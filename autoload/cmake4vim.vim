" autoload/cmake4vim.vim - Cmake4vim common functionality
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>
" Version:      0.2

" Options {{{ "
if !exists("g:cmake_build_dir")
    let g:cmake_build_dir = 'build'
endif
if exists("g:cmake_build_type")
    let g:cmake_build_type = 'Release'
endif
if !exists('g:make_arguments')
    let g:make_arguments = '-j8'
endif
if !exists('g:cmake_build_target')
    let g:cmake_build_target = 'all'
endif
if !exists('g:cmake4vim_change_build_command')
    let g:cmake4vim_change_build_command = 1
endif
if !exists('g:cmake_reload_after_save')
    let g:cmake_reload_after_save = 1
endif
" }}} Options "

" Private functions {{{ "
" Thanks to tpope/vim-fugitive
function! s:fnameescape(file) abort
    if exists('*fnameescape')
        return fnameescape(a:file)
    else
        return escape(a:file," \t\n*?[{`$\\%#'\"|!<")
    endif
endfunction

function! s:make_dir(dir)
    let s:directory = finddir(a:dir, getcwd().';.')
    if s:directory == ""
        silent call mkdir(a:dir, 'p')
        let s:directory = finddir(a:dir, getcwd().';.')
    endif
    return s:directory
endfunction

function! s:exec_command(cmd, dir)
    let s:old_error = &efm
    let s:ErrorFormatCMake =
                \ ' %#%f:%l %#(%m),'
                \ .'See also "%f".,'
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

    let s:old_directory = getcwd()
    let &efm = s:ErrorFormatCMake
    if exists("g:loaded_dispatch")
        let s:old_mkprog = &makeprg
        let &makeprg = 'cd '.s:fnameescape(a:dir).' && '.a:cmd.' && cd '.s:fnameescape(s:old_directory)
        silent execute 'Make'
        let &makeprg = s:old_mkprog
        silent exec 'cd' s:fnameescape(s:old_directory)
    else
        silent exec 'cd' s:fnameescape(a:dir)
        let s:s_out = system(a:cmd)
        silent exec 'cd' s:fnameescape(s:old_directory)
        silent cgetexpr s:s_out
        copen
    endif
    let &efm = s:old_error
endfunction
" }}} Private functions "

" Public functions {{{ "
function! cmake4vim#ResetCMakeCache()
    let s:directory = finddir(g:cmake_build_dir, getcwd().';.')
    if s:directory != ""
        silent call system("rm -rf '".s:directory."'")
    endif
    echon "Cmake cache was removed!"
endfunction

function! cmake4vim#ResetAndReloadCMake(...)
    silent call cmake4vim#ResetCMakeCache()
    silent call cmake4vim#GenerateCMake(join(a:000))
endfunction

function! cmake4vim#CMakeFileSaved()
    if g:cmake_reload_after_save
        silent call cmake4vim#ResetAndReloadCMake()
    endif
endfunction

function! cmake4vim#CleanCMake()
    let s:build_dir = finddir(g:cmake_build_dir, getcwd().';.')
    if s:build_dir == ""
        return
    endif

    let s:cmake_clean_cmd = 'cmake --build ' . shellescape(s:build_dir) . ' --target clean -- ' . g:make_arguments

    silent call s:exec_command(s:cmake_clean_cmd)
endfunction

function! cmake4vim#GetAllTargets()
    let s:build_dir = s:make_dir(g:cmake_build_dir)
    if s:build_dir == ""
        echohl WarningMsg |
                    \ echomsg "Cannot create a build directory: ".g:cmake_build_dir |
                    \ echohl None
        return
    endif
    let s:res = split(system('cmake --build ' . shellescape(s:build_dir) . ' --target help'), "\n")[1:]

    let s:list_targets = []
    for value in s:res
        let s:list_targets += [split(value)[1]]
    endfor

    return s:list_targets
endfunction

function! cmake4vim#GenerateCMake(...)
    if g:cmake4vim_change_build_command
        silent call cmake4vim#SelectTarget(g:cmake_build_target)
    endif

    let l:cmake_args = []

    if exists("g:cmake_project_generator")
        let l:cmake_args += ["-G \"" . g:cmake_project_generator . "\""]
    endif
    if exists("g:cmake_install_prefix")
        let l:cmake_args += ["-DCMAKE_INSTALL_PREFIX=" . g:cmake_install_prefix]
    endif
    if exists("g:cmake_build_type")
        let l:cmake_args += ["-DCMAKE_BUILD_TYPE=" . g:cmake_build_type]
    endif
    if exists("g:cmake_c_compiler")
        let l:cmake_args += ["-DCMAKE_C_COMPILER=" . g:cmake_c_compiler]
    endif
    if exists("g:cmake_cxx_compiler")
        let l:cmake_args += ["-DCMAKE_CXX_COMPILER=" . g:cmake_cxx_compiler]
    endif
    if exists("g:cmake_usr_args")
        let l:cmake_args += [g:cmake_usr_args]
    endif

    let s:cmake_cmd = 'cmake ' . join(l:cmake_args) . ' ' . join(a:000) . ' ' . getcwd()

    silent call s:exec_command(s:cmake_cmd, s:build_dir)
endfunction

function! cmake4vim#SelectTarget(...)
    let s:build_dir = s:make_dir(g:cmake_build_dir)
    if s:build_dir == ""
        echohl WarningMsg |
                    \ echomsg "Cannot create a build directory: ".g:cmake_build_dir |
                    \ echohl None
        return
    endif

    if g:cmake4vim_change_build_command
        let s:cmake_target = ''
        if exists('a:1') && a:1 != ""
            let s:cmake_target = a:1
        else
            let s:targets = ['Select target:']
            let s:sorted_targets = cmake4vim#GetAllTargets()
            let s:count = 1
            let s:sorted_targets = sort(s:sorted_targets)
            for value in s:sorted_targets
                let s:targets += [s:count.'. '.value]
                let s:count += 1
            endfor
            let s:target = inputlist(s:targets)
            if s:target < 1 || s:target >= len(s:targets)
                echohl WarningMsg |
                            \ echomsg "Index of target is out of range!" |
                            \ echohl None
                return
            endif
            let s:cmake_target = split(get(s:targets, s:target))[1]
        endif
        let &makeprg='cmake --build ' . shellescape(s:build_dir) . ' --target ' . s:cmake_target . ' -- ' . g:make_arguments
        echon 'Cmake target: ' . s:cmake_target . ' selected!'
    endif
endfunction

" }}} Public functions "
