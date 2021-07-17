#!/bin/bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TEST_HOME=$(realpath "${CURRENT_DIR}/")

export HOME="${TEST_HOME}/tmp"
git clone --depth 1 https://github.com/tpope/vim-dispatch.git "${HOME}/.vim/plugged/vim-dispatch"
rm -f "${HOME}/vim-profile.txt"

cd "${TEST_HOME}"
vim -Nu new_vimrc --cmd 'au SwapExists * let v:swapchoice = "e"' -S run_test.vim tests/basic/plugin_initialization.vim
vim -Nu new_vimrc --cmd 'au SwapExists * let v:swapchoice = "e"' -S run_test.vim tests/basic/cmake_info.vim
vim -Nu new_vimrc --cmd 'au SwapExists * let v:swapchoice = "e"' -S run_test.vim tests/basic/cmake_version.vim
vim -Nu new_vimrc --cmd 'au SwapExists * let v:swapchoice = "e"' -S run_test.vim tests/basic/change_cmake_file.vim
vim -Nu new_vimrc --cmd 'au SwapExists * let v:swapchoice = "e"' -S run_test.vim tests/basic/generate_cmake_project.vim

