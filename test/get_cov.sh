#!/bin/bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TEST_HOME=$(realpath ${CURRENT_DIR}/)
export PLUGIN_HOME=$(realpath ${CURRENT_DIR}/../)
export HOME="${TEST_HOME}/tmp"

python -m covimerage write_coverage --data-file ${PLUGIN_HOME}/.coverage_covimerage ${HOME}/vim-profile.txt
