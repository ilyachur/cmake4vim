" autoload/cmake4vim.vim - Cmake4vim common functionality
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

" Public functions {{{ "

" Reset cmake cache
function! cmake4vim#ResetCMakeCache() abort
    let l:build_dir = utils#cmake#getBuildDir()
    if l:build_dir !=# ''
        silent call utils#fs#removeDirectory(l:build_dir)
    endif
    echon 'Cmake cache was removed!'
endfunction

function! cmake4vim#ResetAndReloadCMake(...) abort
    silent call cmake4vim#ResetCMakeCache()
    silent call cmake4vim#GenerateCMake(join(a:000))
endfunction

function! cmake4vim#CMakeFileSaved() abort
    if g:cmake_reload_after_save
        silent call cmake4vim#GenerateCMake()
    endif
endfunction

function! cmake4vim#CleanCMake() abort
    let l:build_dir = utils#cmake#getBuildDir()
    let l:cmake_info = utils#cmake#common#getInfo()
    if l:build_dir ==# '' || empty(l:cmake_info)
        return
    endif
    let l:cmake_gen = l:cmake_info['cmake']['generator']
    let l:clean_target = utils#gen#make#getCleanTarget()
    if stridx(l:cmake_gen, utils#gen#vs#getGeneratorName()) != -1
        let l:clean_target = utils#gen#vs#getCleanTarget()
    elseif stridx(l:cmake_gen, utils#gen#ninja#getGeneratorName()) != -1
        let l:clean_target = utils#gen#ninja#getCleanTarget()
    endif

    let l:cmake_clean_cmd = 'cmake --build ' . utils#fs#fnameescape(l:build_dir) . ' --target ' . l:clean_target . ' -- ' . g:make_arguments

    silent call utils#common#executeCommand(l:cmake_clean_cmd, utils#cmake#getCMakeErrorFormat())
endfunction

function! cmake4vim#GetAllTargets() abort
    let l:build_dir = utils#fs#makeDir(utils#cmake#detectBuildDir())
    let l:cmake_info = utils#cmake#common#getInfo()
    let l:cmake_gen = ''
    if !empty(cmake_info)
        let l:cmake_gen = l:cmake_info['cmake']['generator']
    endif
    if (l:cmake_gen ==# '' && has('win32')) || stridx(l:cmake_gen, utils#gen#vs#getGeneratorName()) != -1
        return utils#gen#vs#getTargets()
    elseif stridx(l:cmake_gen, utils#gen#ninja#getGeneratorName()) != -1
        return utils#gen#ninja#getTargets()
    elseif stridx(l:cmake_gen, utils#gen#make#getGeneratorName()) != -1
        return utils#gen#make#getTargets()
    endif
    call utils#common#Warning('Cmake targets were not found!')
    return [json_encode(l:cmake_info)]
endfunction

function! cmake4vim#CompleteTarget(arg_lead, cmd_line, cursor_pos) abort
    let l:sorted_targets = cmake4vim#GetAllTargets()
    return join(l:sorted_targets, "\n")
endfunction

function! cmake4vim#GenerateCMake(...) abort
    let l:cmake_cmd = utils#cmake#getCMakeGenerationCommand(join(a:000))
    let l:src_dir = getcwd()
    let l:build_dir = utils#fs#makeDir(utils#cmake#detectBuildDir())
    call utils#cmake#common#makeRequests(l:build_dir)

    if !utils#cmake#versionGreater([3, 13])
        silent exec 'cd' l:build_dir
    endif
    silent call utils#common#executeCommand(l:cmake_cmd, utils#cmake#getCMakeErrorFormat())
    if !utils#cmake#versionGreater([3, 13])
        silent exec 'cd' l:src_dir
    endif
    call utils#cmake#common#collectResults(l:build_dir)

    if g:cmake_change_build_command
        silent call cmake4vim#SelectTarget(g:cmake_build_target)
    endif
endfunction

function! cmake4vim#SelectTarget(target) abort
    let l:cmake_target = utils#cmake#setBuildTarget(a:target)
    let l:cmd = utils#cmake#getBuildCommand(l:cmake_target)
    if g:cmake_change_build_command
        let &makeprg = l:cmd
    endif
    echon 'Cmake target: ' . l:cmake_target . ' selected!'
    return l:cmd
endfunction

function! cmake4vim#CMakeBuild(...) abort
    let l:cmake_target = g:cmake_build_target
    if exists('a:1') && a:1 !=# ''
        let l:cmake_target = a:1
    endif
    let l:result = cmake4vim#SelectTarget(l:cmake_target)
    silent call utils#common#executeCommand(l:result)
endfunction

function! cmake4vim#SelectBuildType(buildType) abort
    let g:cmake_build_type = a:buildType

    silent call cmake4vim#GenerateCMake()
endfunction
" }}} Public functions "
