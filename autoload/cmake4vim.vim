" autoload/cmake4vim.vim - Cmake4vim common functionality
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

" Options {{{ "
if !exists('g:make_arguments')
    let g:make_arguments = ''
endif
if !exists('g:cmake_build_target')
    let g:cmake_build_target = 'all'
endif
if !exists('g:cmake_change_build_command')
    let g:cmake_change_build_command = 1
endif
if !exists('g:cmake_reload_after_save')
    let g:cmake_reload_after_save = 0
endif
if !exists('g:cmake_compile_commands')
    let g:cmake_compile_commands = 0
endif
if !exists('g:cmake_compile_commands_link')
    let g:cmake_compile_commands_link = ''
endif
if !exists('g:cmake_build_type')
    let g:cmake_build_type = ''
endif
if !exists('g:cmake_build_dir')
    let g:cmake_build_dir = ''
endif
if !exists('g:cmake_project_generator')
    let g:cmake_project_generator = ''
endif
if !exists('g:cmake_install_prefix')
    let g:cmake_install_prefix = ''
endif
if !exists('g:cmake_c_compiler')
    let g:cmake_c_compiler = ''
endif
if !exists('g:cmake_cxx_compiler')
    let g:cmake_cxx_compiler = ''
endif
if !exists('g:cmake_usr_args')
    let g:cmake_usr_args = ''
endif
" }}} Options "

" Private functions {{{ "
function! s:makeDir(dir) abort
    let s:directory = finddir(a:dir, getcwd().';.')
    if s:directory ==# ''
        silent call mkdir(a:dir, 'p')
        let s:directory = finddir(a:dir, getcwd().';.')
    endif
    if s:directory ==# ''
        echohl WarningMsg |
                    \ echomsg 'Cannot create a build directory: '.a:dir |
                    \ echohl None
        return
    endif
    return s:directory
endfunction

function! s:runDispatch(cmd) abort
    let s:old_make = &l:makeprg

    try
        let &l:makeprg = a:cmd
        silent! execute 'Make'
    finally
        let &l:makeprg = s:old_make
    endtry
endfunction

function! s:runSystem(cmd) abort
    let s:s_out = system(a:cmd)
    silent cgetexpr s:s_out
    silent copen
endfunction

function! s:GetCMakeErrorFormat() abort
    return ' %#%f:%l %#(%m),'
                \ .'See also "%f".,'
                \ .'%E%>CMake Error at %f:%l:,'
                \ .'%Z  %m,'
                \ .'%E%>CMake Error at %f:%l (%[%^)]%#):,'
                \ .'%Z  %m,'
                \ .'%W%>Cmake Warning at %f:%l (%[%^)]%#):,'
                \ .'%Z  %m,'
                \ .'%E%>CMake Error: Error in cmake code at,'
                \ .'%C%>%f:%l:,'
                \ .'%Z%m,'
                \ .'%E%>CMake Error in %.%#:,'
                \ .'%C%>  %m,'
                \ .'%C%>,'
                \ .'%C%>    %f:%l (if),'
                \ .'%C%>,'
                \ .'%Z  %m,'
endfunction

function! s:executeCommand(cmd, ...) abort
    " Close quickfix list in order to don't save custom error format
    silent cclose
    let l:errFormat = get(a:, 1, '')
    let s:old_error = &l:errorformat
    if l:errFormat !=# ''
        let &l:errorformat = l:errFormat
    endif

    if exists(':Dispatch')
        silent call s:runDispatch(a:cmd)
    else
        silent call s:runSystem(a:cmd)
    endif

    if l:errFormat !=# ''
        let &l:errorformat = s:old_error
    endif
endfunction
" }}} Private functions "

" Public functions {{{ "
function! cmake4vim#ResetCMakeCache() abort
    let s:build_dir = cmake4vim#DetectBuildDir()
    let s:directory = finddir(cmake4vim#DetectBuildDir(), getcwd().';.')
    if s:directory !=# ''
        silent call system("rm -rf '".s:directory."'")
    endif
    echon 'Cmake cache was removed!'
endfunction

function! cmake4vim#CreateLink() abort
    let s:build_dir = finddir(cmake4vim#DetectBuildDir(), getcwd().';.')
    if s:build_dir ==# '' || !g:cmake_compile_commands || g:cmake_compile_commands_link ==# '' || has('win32')
        return
    endif
    silent call system('rm -f ' . shellescape(g:cmake_compile_commands_link) . '/compile_commands.json')
    silent call system('ln -s ' . shellescape(s:build_dir) . '/compile_commands.json ' . shellescape(g:cmake_compile_commands_link) . '/compile_commands.json')
endfunction

function! cmake4vim#ResetAndReloadCMake(...) abort
    silent call cmake4vim#ResetCMakeCache()
    silent call cmake4vim#GenerateCMake(join(a:000))
endfunction

function! cmake4vim#CMakeFileSaved() abort
    if g:cmake_reload_after_save
        silent call cmake4vim#ResetAndReloadCMake()
    endif
endfunction

function! cmake4vim#CleanCMake() abort
    let s:build_dir = finddir(cmake4vim#DetectBuildDir(), getcwd().';.')
    if s:build_dir ==# ''
        return
    endif

    let s:cmake_clean_cmd = 'cmake --build ' . shellescape(s:build_dir) . ' --target clean -- ' . g:make_arguments

    silent call s:executeCommand(s:cmake_clean_cmd, s:GetCMakeErrorFormat())
endfunction

function! cmake4vim#GetAllTargets() abort
    let s:build_dir = s:makeDir(cmake4vim#DetectBuildDir())
    let s:res = split(system('cmake --build ' . shellescape(s:build_dir) . ' --target help'), "\n")[1:]

    let s:list_targets = []
    for l:value in s:res
        let s:list_targets += [split(l:value)[1]]
    endfor

    return s:list_targets
endfunction

function! cmake4vim#CompleteTarget(arg_lead, cmd_line, cursor_pos) abort
    let s:sorted_targets = cmake4vim#GetAllTargets()
    return join(s:sorted_targets, "\n")
endfunction

function! cmake4vim#DetectBuildType() abort
    if g:cmake_build_type !=# ''
        return g:cmake_build_type
    endif
    " WA for recursive DetectBuildDir, try to find the first valid cmake directory
    let s:build_dir = ''
    if g:cmake_build_dir ==# ''
        for l:value in ['cmake-build-release', 'cmake-build-debug', 'cmake-build-relwithdebinfo', 'cmake-build-minsizerel', 'cmake-build']
            let s:build_dir = finddir(l:value, getcwd().';.')
            if s:build_dir !=# ''
                break
            endif
        endfor
    else
        let s:build_dir = finddir(cmake4vim#DetectBuildDir(), getcwd().';.')
    endif

    if s:build_dir !=# ''
        let s:res = split(system('cmake -L -N ' . shellescape(s:build_dir)), '\n')
        for l:value in s:res
            let s:split_res = split(l:value, '=')
            if len(s:split_res) > 1 && s:split_res[0] ==# 'CMAKE_BUILD_TYPE:STRING'
                return s:split_res[1]
            endif
        endfor
    endif

    return 'Release'
endfunction

function! cmake4vim#DetectBuildDir() abort
    if g:cmake_build_dir !=# ''
        return g:cmake_build_dir
    endif
    let s:build_type = tolower(cmake4vim#DetectBuildType())
    if s:build_type ==# ''
        return 'cmake-build'
    endif
    return 'cmake-build-'.s:build_type
endfunction

function! cmake4vim#GenerateCMake(...) abort
    let s:build_dir = s:makeDir(cmake4vim#DetectBuildDir())
    let l:cmake_args = []

    let l:cmake_args += ['-DCMAKE_BUILD_TYPE=' . cmake4vim#DetectBuildType()]
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

    let s:cmake_cmd = 'cmake '.join(l:cmake_args).' '.join(a:000).' -H'.getcwd().' -B'.s:build_dir

    silent call s:executeCommand(s:cmake_cmd, s:GetCMakeErrorFormat())

    if g:cmake_change_build_command
        silent call cmake4vim#SelectTarget(g:cmake_build_target)
    endif
endfunction

function! cmake4vim#SelectTarget(target) abort
    let s:build_dir = s:makeDir(cmake4vim#DetectBuildDir())
    if g:cmake_compile_commands && g:cmake_compile_commands_link !=# ''
        silent call cmake4vim#CreateLink()
    endif

    let g:cmake_build_target = a:target
    let l:cmd = 'cmake --build ' . shellescape(s:build_dir) . ' --target ' . a:target . ' -- ' . g:make_arguments
    if g:cmake_change_build_command
        let &makeprg = l:cmd
    endif
    echon 'Cmake target: ' . a:target . ' selected!'
    return l:cmd
endfunction

function! cmake4vim#CMakeBuild(...) abort
    let s:cmake_target = g:cmake_build_target
    if exists('a:1') && a:1 !=# ''
        let s:cmake_target = a:1
    endif
    let l:result = cmake4vim#SelectTarget(s:cmake_target)
    silent call s:executeCommand(l:result)
endfunction
" }}} Public functions "
