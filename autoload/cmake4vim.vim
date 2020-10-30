" autoload/cmake4vim.vim - Cmake4vim common functionality
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

" Public functions {{{ "
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
    if l:build_dir ==# ''
        return
    endif

    let l:cmake_clean_cmd = 'cmake --build ' . shellescape(l:build_dir) . ' --target clean -- ' . g:make_arguments

    silent call utils#common#executeCommand(l:cmake_clean_cmd, utils#cmake#getCMakeErrorFormat())
endfunction

function! cmake4vim#GetAllTargets() abort
    let l:list_targets = []
    let l:build_dir = utils#fs#makeDir(utils#cmake#detectBuildDir())
    let l:res = split(system('cmake --build ' . shellescape(l:build_dir) . ' --target help'), "\n")[1:]
    if v:shell_error != 0
        let l:error_msg = ''
        if has('win32')
            " Parse VS projects
            let l:res = split(system('dir *.vcxproj /S /B'), "\n")
            if v:shell_error != 0
                let l:error_msg = 'Error: cannot detect targets!'
            else
                for l:value in l:res
                    if l:value !=# ''
                        let l:files = split(l:value, l:build_dir)
                        if len(l:files) != 2
                            continue
                        endif
                        " Exclude projects from CMakeFiles folder
                        let l:files = split(l:files[1], 'CMakeFiles')
                        if len(l:files) != 1
                            continue
                        endif
                        let l:files = split(l:files[0], '\\')
                        let l:list_targets += [fnamemodify(l:files[-1], ':r')]
                    endif
                endfor
            endif
        else
            let l:error_msg = 'Error: cannot detect targets!'
        endif
        if l:error_msg !=# ''
            echohl WarningMsg |
                        \ echomsg l:error_msg |
                        \ echohl None
        endif
    else
        for l:value in l:res
            if l:value !=# ''
                let l:list_targets += [split(l:value)[1]]
            endif
        endfor
    endif

    return l:list_targets
endfunction

function! cmake4vim#CompleteTarget(arg_lead, cmd_line, cursor_pos) abort
    let l:sorted_targets = cmake4vim#GetAllTargets()
    return join(l:sorted_targets, "\n")
endfunction

function! cmake4vim#GenerateCMake(...) abort
    let l:cmake_cmd = utils#cmake#getCMakeGenerationCommand()
    silent call utils#common#executeCommand(l:cmake_cmd, utils#cmake#getCMakeErrorFormat())

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

function! cmake4vim#GetCMakeInfo() abort
    let l:info = []
    if executable('cmake')
        let l:info += ['Cmake was found!']
        let l:info += ['CMAKE_GENERATOR     : ' . utils#cmake#getCmakeGeneratorType()]
        let l:info += ['CMAKE_BUILD_TYPE    : ' . utils#cmake#detectBuildType()]
        let l:info += ['BUILD_DIRECTORY     : ' . utils#cmake#getBuildDir()]
        let l:info += ['CMAKE_GEN_COMMAND   : ' . utils#cmake#getCMakeGenerationCommand()]
        let l:info += ['CMAKE_BUILD_COMMAND : ' . utils#cmake#getBuildCommand(g:cmake_build_target)]
    else
        let l:info += ['Cmake was not found!']
    endif
    return l:info
endfunction

function! cmake4vim#SelectBuildType(buildType) abort
    let g:cmake_build_type = a:buildType

    silent call cmake4vim#GenerateCMake()
endfunction
" }}} Public functions "

