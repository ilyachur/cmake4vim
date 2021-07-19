#!/bin/bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TEST_HOME=$(realpath "${CURRENT_DIR}/")

export HOME="${TEST_HOME}/tmp"
git clone --depth 1 https://github.com/tpope/vim-dispatch.git "${HOME}/.vim/plugged/vim-dispatch"
rm -f "${HOME}/vim-profile.txt"

RUN_VIM="vim --clean --not-a-term"
RUN_TEST="$RUN_VIM -S run_test.vim"
echo "Running cmake4vim tests"

TESTS="$@"

if [ -z "$TESTS" ]; then
  TESTS=*.test.vim
fi

for t in ${TESTS}; do
    echo ""
    echo "%RUN: $t"

    if ${RUN_TEST} --cmd 'au SwapExists * let v:swapchoice = "e"' $t $T \
        && [ -f $t.res ];  then
        echo "%PASS: $t PASSED"
    else
        echo "%FAIL: $t FAILED - see $TESTLOGDIR"
        RESULT=1
    fi
done

cd "${TEST_HOME}"
vim -Nu new_vimrc --cmd 'au SwapExists * let v:swapchoice = "e"' -S run_test.vim tests/basic/plugin_initialization.vim
vim -Nu new_vimrc --cmd 'au SwapExists * let v:swapchoice = "e"' -S run_test.vim tests/basic/cmake_info.vim
vim -Nu new_vimrc --cmd 'au SwapExists * let v:swapchoice = "e"' -S run_test.vim tests/basic/cmake_version.vim
vim -Nu new_vimrc --cmd 'au SwapExists * let v:swapchoice = "e"' -S run_test.vim tests/basic/change_cmake_file.vim
vim -Nu new_vimrc --cmd 'au SwapExists * let v:swapchoice = "e"' -S run_test.vim tests/basic/generate_cmake_project.vim

