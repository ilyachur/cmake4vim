" Needed for a code coverage
profile start /tmp/vim-profile.txt
profile! file ../*

set nocompatible
filetype off
filetype plugin indent on
syntax enable
set rtp+=${HOME}/.vim/plugged/vader.vim
" set rtp+=${HOME}/.fzf
" set rtp+=${HOME}/.vim/plugged/fzf.vim
set rtp+=${PLUGIN_HOME}
