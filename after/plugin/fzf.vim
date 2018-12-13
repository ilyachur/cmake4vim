" after/plugin/ctrlp.vim - FZF command for cmake4vim plugin
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>
" Version:      0.2

" if !exists('g:loaded_ctrlp') || !g:loaded_ctrlp
"     finish
" endif

let s:old_cpo = &cpo
set cpo&vim

if !exists(':FZF')
    finish
endif

command!      -bang -nargs=* FZFCMakeSelectTarget call fzf#cmake4vim#SelectTarget(<q-args>, <bang>0)

let &cpo = s:old_cpo
unlet s:old_cpo
