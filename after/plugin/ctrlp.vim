" after/plugin/ctrlp.vim - CtrlP command for cmake4vim plugin
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

if !exists('g:loaded_ctrlp') || !g:loaded_ctrlp
    finish
endif

let s:old_cpo = &cpoptions
set cpoptions&vim

command! CtrlPCMakeTarget call ctrlp#init(ctrlp#cmake4vim#id())

let &cpoptions = s:old_cpo
unlet s:old_cpo
