" autoload/ctrlp.vim - CtrlP functionality for cmake4vim plugin
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

if exists('g:loaded_ctrlp_cmake4vim')
    finish
endif
let g:loaded_ctrlp_cmake4vim = 1

let s:cmake4vim_vars = [
            \{
            \ 'init': 'ctrlp#cmake4vim#initTargets()',
            \ 'accept': 'ctrlp#cmake4vim#acceptTarget',
            \ 'lname': 'CMake targets',
            \ 'sname': 'CMake',
            \ 'type': 'line',
            \ 'sort': 0,
            \ },
            \{
            \ 'init': 'ctrlp#cmake4vim#initBuildTypes()',
            \ 'accept': 'ctrlp#cmake4vim#acceptBuildType',
            \ 'lname': 'CMake build type',
            \ 'sname': 'CMake',
            \ 'type': 'line',
            \ 'sort': 1,
            \ },
            \]

if !exists('g:ctrlp_cmake4vim_execute')
    let g:ctrlp_cmake4vim_execute = 0
endif

if exists('g:ctrlp_ext_vars') && !empty(g:ctrlp_ext_vars)
    let g:ctrlp_ext_vars = add(g:ctrlp_ext_vars, s:cmake4vim_vars)
else
    let g:ctrlp_ext_vars = s:cmake4vim_vars
endif

function! ctrlp#cmake4vim#initTargets() abort
    return cmake4vim#GetAllTargets()
endfunction

function! ctrlp#cmake4vim#initBuildTypes() abort
    return keys( utils#cmake#getCMakeVariants() )
endfunction

function! ctrlp#cmake4vim#acceptTarget(mode, str) abort
    call ctrlp#exit()
    redraw
    call cmake4vim#SelectTarget(a:str)
endfunction

function! ctrlp#cmake4vim#acceptBuildType(mode, str) abort
    call ctrlp#exit()
    redraw
    call cmake4vim#SelectBuildType(a:str)
endfunction

let s:target_id     = g:ctrlp_builtins + 1
let s:build_type_id = g:ctrlp_builtins + 2

function! ctrlp#cmake4vim#TargetID() abort
    return s:target_id
endfunction

function! ctrlp#cmake4vim#BuildTypeID() abort
    return s:build_type_id
endfunction
