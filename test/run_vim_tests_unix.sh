#!/bin/bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TEST_HOME=$(realpath "${CURRENT_DIR}/")

export HOME="${TEST_HOME}/tmp"
git clone --depth 1 https://github.com/tpope/vim-dispatch.git "${HOME}/.vim/plugged/vim-dispatch" > /dev/null 2>&1 
rm -f "${HOME}/vim-profile.txt"

VIM=$1
RUN_VIM="$VIM --clean --not-a-term"
RUN_TEST="$RUN_VIM -Nu new_vimrc -S run_test.vim"

echo "Running cmake4vim tests"

TESTS="${@:2}"

if [ -z "$TESTS" ]; then
  TESTS=tests/*/*.vim
fi

STATUS_CODE=0

for t in ${TESTS}; do
    echo ""
    echo "RUNNING: $t"

    TESTLOGDIR=$(pwd)/logs/$t

    if ${RUN_TEST} --cmd 'au SwapExists * let v:swapchoice = "e"' $t; then
        echo "PASSED: $t"
    else
        echo "FAILED: $t FAILED - see $t.failed.log"
        STATUS_CODE=1
    fi
done

echo "ALL TESTS DONE"
exit $STATUS_CODE
