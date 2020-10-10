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
    let l:build_dir = utils#fs#makeDir(utils#cmake#detectBuildDir())
    let l:cmake_args = []

    let l:cmake_args += ['-DCMAKE_BUILD_TYPE=' . utils#cmake#detectBuildType()]
    if g:cmake_project_generator !=# ''
        let l:cmake_args += ['-G "' . g:cmake_project_generator . '"']
    endif
    if g:cmake_install_prefix !=# ''
        let l:cmake_args += ['-DCMAKE_INSTALL_PREFIX=' . g:cmake_install_prefix]
    endif
    if g:cmake_c_compiler !=# ''
        let l:cmake_args += ['-DCMAKE_C_COMPILER=' . g:cmake_c_compiler]
    endif
    if g:cmake_cxx_compiler !=# ''
        let l:cmake_args += ['-DCMAKE_CXX_COMPILER=' . g:cmake_cxx_compiler]
    endif
    if g:cmake_compile_commands
        let l:cmake_args += ['-DCMAKE_EXPORT_COMPILE_COMMANDS=ON']
    endif
    if g:cmake_usr_args !=# ''
        let l:cmake_args += [g:cmake_usr_args]
    endif

    let l:cmake_cmd = 'cmake '.join(l:cmake_args).' '.join(a:000).' -H'.getcwd().' -B'.l:build_dir

    silent call utils#common#executeCommand(l:cmake_cmd, utils#cmake#getCMakeErrorFormat())

    if g:cmake_change_build_command
        silent call cmake4vim#SelectTarget(g:cmake_build_target)
    endif
endfunction

function! cmake4vim#SelectTarget(target) abort
    let l:build_dir = utils#fs#makeDir(utils#cmake#detectBuildDir())
    if g:cmake_compile_commands_link !=# ''
        let l:src = shellescape(l:build_dir) . '/compile_commands.json'
        let l:dst = shellescape(g:cmake_compile_commands_link) . '/compile_commands.json'
        silent call utils#fs#createLink(l:src, l:dst)
    endif

    let g:cmake_build_target = a:target
    let l:cmd = 'cmake --build ' . shellescape(l:build_dir) . ' --target ' . a:target . ' -- '
    if utils#cmake#getCmakeGeneratorType() ==# 'Ninja'
        let l:cmd .= '-C ' . fnamemodify(l:build_dir, ':p:h') . ' '
    endif
    let l:cmd .= g:make_arguments
    if g:cmake_change_build_command
        let &makeprg = l:cmd
    endif
    echon 'Cmake target: ' . a:target . ' selected!'
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
