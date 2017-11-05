" cmake4vim.vim - Vim plugin for cmake integration
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>
" Version:      0.1

let s:cmake4vim_plugin_version = '0.1'

if exists("loaded_cmake4vim_plugin")
  finish
endif
" Initialization {{{ "
let loaded_cmake4vim_plugin = 1
if !exists('g:cmake4vim_change_build_command')
    let g:cmake4vim_change_build_command = 1
endif
" }}} Initialization "

" Utility functions {{{ "
" " Thanks to tpope/vim-fugitive
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

function! s:exec_command(cmd)
    if exists("g:loaded_dispatch")
        silent execute 'Dispatch '.a:cmd
    else
        silent cexpr system(a:cmd)
        copen
    endif
endfunction
" }}} Utility functions "

" Public interfaces {{{ "
command! -nargs=? CMake call s:generate_cmake(<f-args>)
command! -nargs=? CMakeResetAndReload call s:reset_reload_cmake(<f-args>)
command! CMakeReset call s:reset_cmake()
command! CMakeClean call s:clean_cmake()
" }}} Public interfaces "za

" Main functionality {{{ "
function! s:generate_cmake(...)
    if !exists("g:cmake_build_dir")
        let g:cmake_build_dir = 'build'
    endif

    let s:build_dir = s:make_dir(g:cmake_build_dir)
    if s:build_dir == ""
        echohl WarningMsg |
                    \ echomsg "Cannot create a build directory: ".g:cmake_build_dir |
                    \ echohl None
        return
    endif

    if g:cmake4vim_change_build_command
        if !exists('g:cmake_build_target')
            let g:cmake_build_target = 'all'
        endif
        if !exists('g:make_arguments')
            let g:make_arguments = ''
        endif
        let &makeprg='cmake --build ' . shellescape(s:build_dir) . ' --target ' . g:cmake_build_target . ' -- ' . g:make_arguments
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

    let s:old_directory = getcwd()
    silent exec 'cd' s:fnameescape(s:build_dir)
    let s:cmake_cmd = 'cmake ' . join(l:cmake_args) . ' ' . join(a:000) . ' ' . s:old_directory

    silent call s:exec_command(s:cmake_cmd)

    silent exec 'cd' s:fnameescape(s:old_directory)
endfunction

function! s:reset_cmake()
    if !exists("g:cmake_build_dir")
        let g:cmake_build_dir = 'build'
    endif

    let s:directory = finddir(g:cmake_build_dir, getcwd().';.')
    if s:directory != ""
        silent call system("rm -rf '".s:directory."'")
    endif
endfunction

function! s:reset_reload_cmake(...)
    silent call s:reset_cmake()
    silent call s:generate_cmake(join(a:000))
endfunction

function! s:clean_cmake()
    if !exists("g:cmake_build_dir")
        let g:cmake_build_dir = 'build'
    endif

    let s:build_dir = finddir(g:cmake_build_dir, getcwd().';.')
    if s:build_dir == ""
        return
    endif

    if !exists('g:make_arguments')
        let g:make_arguments = ''
    endif

    let s:cmake_clean_cmd = 'cmake --build ' . shellescape(s:build_dir) . ' --target clean -- ' . g:make_arguments

    silent call s:exec_command(s:cmake_clean_cmd)
endfunction
" }}} Main functionality "
