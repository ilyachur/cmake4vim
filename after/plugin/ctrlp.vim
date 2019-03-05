" after/plugin/ctrlp.vim - CtrlP command for cmake4vim plugin
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>
" Version:      0.3

if !exists('g:loaded_ctrlp') || !g:loaded_ctrlp
    finish
endif

let s:old_cpo = &cpo
set cpo&vim

command! CtrlPCMakeTarget call ctrlp#init(ctrlp#cmake4vim#id())

let &cpo = s:old_cpo
unlet s:old_cpo
