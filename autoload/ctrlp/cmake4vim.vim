" autoload/ctrlp.vim - CtrlP functionality for cmake4vim plugin
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

if exists('g:loaded_ctrlp_cmake4vim')
    finish
endif
let g:loaded_ctrlp_cmake4vim = 1

let s:cmake4vim_var = {
            \ 'init': 'ctrlp#cmake4vim#init()',
            \ 'accept': 'ctrlp#cmake4vim#accept',
            \ 'lname': 'CMake targets',
            \ 'sname': 'CMake',
            \ 'type': 'line',
            \ 'sort': 0,
            \ }
if !exists('g:ctrlp_cmake4vim_execute')
    let g:ctrlp_cmake4vim_execute = 0
endif

if exists('g:ctrlp_ext_vars') && !empty(g:ctrlp_ext_vars)
    let g:ctrlp_ext_vars = add(g:ctrlp_ext_vars, s:cmake4vim_var)
else
    let g:ctrlp_ext_vars = [s:cmake4vim_var]
endif

function! ctrlp#cmake4vim#init() abort
    return cmake4vim#GetAllTargets()
endfunction

function! ctrlp#cmake4vim#accept(mode, str) abort
    call ctrlp#exit()
    redraw
    call cmake4vim#SelectTarget(a:str)
endfunction

let s:id = g:ctrlp_builtins + len(g:ctrlp_ext_vars)

function! ctrlp#cmake4vim#id() abort
    return s:id
endfunction
