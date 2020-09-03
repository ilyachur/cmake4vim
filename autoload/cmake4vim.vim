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
" Create directory
function! s:makeDir(dir) abort
    let l:directory = finddir(a:dir, getcwd().';.')
    if l:directory ==# ''
        silent call mkdir(a:dir, 'p')
        let l:directory = finddir(a:dir, getcwd().';.')
    endif
    if l:directory ==# ''
        echohl WarningMsg |
                    \ echomsg 'Cannot create a build directory: '.a:dir |
                    \ echohl None
        return
    endif
    return l:directory
endfunction

" Remove directory
function! s:removeDirectory(file) abort
    if has('win32')
        silent call system("rd /S /Q \"".a:file."\"")
    else
        silent call system("rm -rf '".a:file."'")
    endif
endfunction

" Remove file
function! s:removeFile(file) abort
    if has('win32')
        silent call system("del /F /Q \"".a:file."\"")
    else
        silent call system("rm -rf '".a:file."'")
    endif
endfunction

function! s:runDispatch(cmd) abort
    let l:old_make = &l:makeprg

    try
        let &l:makeprg = a:cmd
        silent! execute 'Make'
    finally
        let &l:makeprg = l:old_make
    endtry
endfunction

function! s:runSystem(cmd) abort
    let l:s_out = system(a:cmd)
    silent cgetexpr l:s_out
    silent copen
endfunction

function! s:getCMakeErrorFormat() abort
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
    let l:old_error = &l:errorformat
    if l:errFormat !=# ''
        let &l:errorformat = l:errFormat
    endif

    if exists(':Dispatch')
        silent call s:runDispatch(a:cmd)
    else
        silent call s:runSystem(a:cmd)
    endif

    if l:errFormat !=# ''
        let &l:errorformat = l:old_error
    endif
endfunction

function! s:createLink() abort
    let l:build_dir = s:getBuildDir()
    if l:build_dir ==# '' || !g:cmake_compile_commands || g:cmake_compile_commands_link ==# ''
        return
    endif
    silent call s:removeFile(shellescape(g:cmake_compile_commands_link) . '/compile_commands.json')
    if has('win32')
        silent call system('copy ' . shellescape(l:build_dir) . '/compile_commands.json ' . shellescape(g:cmake_compile_commands_link) . '/compile_commands.json')
    else
        silent call system('ln -s ' . shellescape(l:build_dir) . '/compile_commands.json ' . shellescape(g:cmake_compile_commands_link) . '/compile_commands.json')
    endif
endfunction

function! s:findCachedVar(data, variable) abort
    for l:value in a:data
        let l:split_res = split(l:value, '=')
        if len(l:split_res) > 1 && stridx(l:split_res[0], a:variable . ':') != -1
            return l:split_res[1]
        endif
    endfor
endfunction

function! s:detectBuildType() abort
    if g:cmake_build_type !=# ''
        return g:cmake_build_type
    endif
    " WA for recursive DetectBuildDir, try to find the first valid cmake directory
    let l:build_dir = ''
    if g:cmake_build_dir ==# ''
        for l:value in ['cmake-build-release', 'cmake-build-debug', 'cmake-build-relwithdebinfo', 'cmake-build-minsizerel', 'cmake-build']
            let l:build_dir = finddir(l:value, getcwd().';.')
            if l:build_dir !=# ''
                break
            endif
        endfor
    else
        let l:build_dir = s:getBuildDir()
    endif

    if l:build_dir !=# ''
        let l:cmake_vars = split(system('cmake -L -N ' . shellescape(l:build_dir)), '\n')
        let l:res = s:findCachedVar(l:cmake_vars, 'CMAKE_BUILD_TYPE')
        if l:res !=# ''
            return l:res
        endif
    endif

    return 'Release'
endfunction

function! s:detectBuildDir() abort
    if g:cmake_build_dir !=# ''
        return g:cmake_build_dir
    endif
    let l:build_type = tolower(s:detectBuildType())
    if l:build_type ==# ''
        return 'cmake-build'
    endif
    return 'cmake-build-'.l:build_type
endfunction

function! s:getBuildDir() abort
    return finddir(s:detectBuildDir(), getcwd().';.')
endfunction

function! s:getCmakeCache() abort
    let l:cache_file = s:getBuildDir() . '/CMakeCache.txt'
    if !filereadable(l:cache_file)
        return []
    endif
    if has('win32')
        return split(system('type ' . shellescape(l:cache_file)), '\n')
    else
        return split(system('cat ' . shellescape(l:cache_file)), '\n')
    endif
endfunction

function! s:getCmakeGeneratorType() abort
    let l:cmake_info = s:getCmakeCache()

    return s:findCachedVar(l:cmake_info, 'CMAKE_GENERATOR')
endfunction
" }}} Private functions "

" Public functions {{{ "
function! cmake4vim#ResetCMakeCache() abort
    let l:build_dir = s:getBuildDir()
    if l:build_dir !=# ''
        silent call s:removeDirectory(l:build_dir)
    endif
    echon 'Cmake cache was removed!'
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
    let l:build_dir = s:getBuildDir()
    if l:build_dir ==# ''
        return
    endif

    let l:cmake_clean_cmd = 'cmake --build ' . shellescape(l:build_dir) . ' --target clean -- ' . g:make_arguments

    silent call s:executeCommand(l:cmake_clean_cmd, s:getCMakeErrorFormat())
endfunction

function! cmake4vim#GetAllTargets() abort
    let l:list_targets = []
    let l:build_dir = s:makeDir(s:detectBuildDir())
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
    let l:build_dir = s:makeDir(s:detectBuildDir())
    let l:cmake_args = []

    let l:cmake_args += ['-DCMAKE_BUILD_TYPE=' . s:detectBuildType()]
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

    silent call s:executeCommand(l:cmake_cmd, s:getCMakeErrorFormat())

    if g:cmake_change_build_command
        silent call cmake4vim#SelectTarget(g:cmake_build_target)
    endif
endfunction

function! cmake4vim#SelectTarget(target) abort
    let l:build_dir = s:makeDir(s:detectBuildDir())
    if g:cmake_compile_commands && g:cmake_compile_commands_link !=# ''
        silent call s:createLink()
    endif

    let g:cmake_build_target = a:target
    let l:cmd = 'cmake --build ' . shellescape(l:build_dir) . ' --target ' . a:target . ' -- ' . g:make_arguments
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
    silent call s:executeCommand(l:result)
endfunction

function! cmake4vim#GetCMakeInfo() abort
    let l:info = []
    if executable('cmake')
        let l:info += ['Cmake was found!']
        let l:info += ['CMAKE_GENERATOR     : ' . s:getCmakeGeneratorType()]
        let l:info += ['CMAKE_BUILD_TYPE    : ' . s:detectBuildType()]
        let l:info += ['BUILD_DIRECTORY     : ' . s:getBuildDir()]
    else
        let l:info += ['Cmake was not found!']
    endif
    return l:info
endfunction
" }}} Public functions "
