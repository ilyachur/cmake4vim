#!/bin/bash

rm -f /tmp/vim-profile.txt

mkdir -p /tmp/.vim/plugged
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TEST_HOME=$(realpath ${CURRENT_DIR}/)
export PLUGIN_HOME=$(realpath ${CURRENT_DIR}/../)
export HOME="${TEST_HOME}/tmp"
touch ${HOME}/.bashrc
git clone --depth 1 https://github.com/junegunn/vader.vim.git ${HOME}/.vim/plugged/vader.vim
git clone --depth 1 https://github.com/junegunn/fzf.vim ${HOME}/.vim/plugged/fzf.vim
git clone --depth 1 https://github.com/junegunn/fzf.git ${HOME}/.fzf
${HOME}/.fzf/install --all

cd ${TEST_HOME}
vim -Nu .vimrc +Vader!*
