#!/bin/bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TEST_HOME=$(realpath "${CURRENT_DIR}/")
export HOME="${TEST_HOME}/tmp"
git clone --depth 1 https://github.com/junegunn/vader.vim.git "${HOME}/.vim/plugged/vader.vim"
git clone --depth 1 https://github.com/tpope/vim-dispatch.git "${HOME}/.vim/plugged/vim-dispatch"
rm -f "${HOME}/vim-profile.txt"
# git clone --depth 1 https://github.com/junegunn/fzf.vim ${HOME}/.vim/plugged/fzf.vim
# git clone --depth 1 https://github.com/junegunn/fzf.git ${HOME}/.fzf
# ${HOME}/.fzf/install --all

cd "${TEST_HOME}"
vim -Nu vimrc +Vader!*
