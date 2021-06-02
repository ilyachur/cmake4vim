" autoload/fzf.vim - FZF functionality for cmake4vim plugin
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

if exists('g:loaded_fzf_cmake4vim')
    finish
endif
let g:loaded_fzf_cmake4vim = 1

function! fzf#cmake4vim#SelectTarget(...) abort
    if exists(':FZF')
        return fzf#run({
                    \ 'source': cmake4vim#GetAllTargets(),
                    \ 'options': '+m -n 1 --prompt CMakeTarget\>\ ',
                    \ 'down':    '30%',
                    \ 'sink':    function('cmake4vim#SelectTarget')})
    endif
endfunction

function! fzf#cmake4vim#SelectBuildType() abort
    if exists(':FZF')
        return fzf#run({
                    \ 'source': sort( keys( utils#cmake#getCMakeVariants() ), 'i' ),
                    \ 'options': '+m -n 1 --prompt CMakeBuildType\>\ ',
                    \ 'down':    '30%',
                    \ 'sink':    function('cmake4vim#SelectBuildType')})
    endif
endfunction

function! fzf#cmake4vim#SelectKit() abort
    if exists(':FZF')
        return fzf#run({
                    \ 'source': sort( keys( utils#cmake#getLoadedCMakeKits() ), 'i' ),
                    \ 'options': '+m -n 1 --prompt CMakeKit\>\ ',
                    \ 'down':    '30%',
                    \ 'sink':    function('cmake4vim#SelectKit')})
    endif
endfunction
