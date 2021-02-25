" after/plugin/ctrlp.vim - FZF command for cmake4vim plugin
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

let s:old_cpo = &cpoptions
set cpoptions&vim

if !exists(':FZF')
    finish
endif

command! -bang -nargs=* FZFCMakeSelectTarget call fzf#cmake4vim#SelectTarget(<q-args>, <bang>0)
command! FZFCMakeSelectBuildType call fzf#cmake4vim#SelectBuildType()

let &cpoptions = s:old_cpo
unlet s:old_cpo
