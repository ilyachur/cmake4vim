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

