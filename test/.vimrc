" Needed for a code coverage
profile start $HOME/vim-profile.txt
profile! file ../*

" vint: next-line -ProhibitSetNoCompatible
filetype off
filetype plugin indent on
syntax enable
set runtimepath +=$HOME/.vim/plugged/vader.vim
" set rtp+=$HOME/.fzf
" set rtp+=$HOME/.vim/plugged/fzf.vim
set runtimepath +=$PLUGIN_HOME

set tabpagemax=1000
