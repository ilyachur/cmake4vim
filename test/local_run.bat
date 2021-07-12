@echo off

set VADER_OUTPUT_FILE=%~dp0\vader_output
type nul > "%VADER_OUTPUT_FILE%"

pushd %~dp0
set HOME=%CD%\tmp
if not exist %HOME% mkdir %HOME%
git clone --depth 1 https://github.com/junegunn/vader.vim.git %HOME%\.vim\plugged\vader.vim
git clone --depth 1 https://github.com/tpope/vim-dispatch.git %HOME%\.vim\plugged\vim-dispatch
del %HOME%\vim-profile.txt

vim -Nu vimrc +Vader! tests/basic/plugin_initialization.vader
vim -Nu vimrc +Vader! tests/basic/cmake_version.vader
vim -Nu vimrc +Vader! tests/basic/generate_cmake_project.vader
vim -Nu vimrc +Vader! tests/basic/change_cmake_file.vader
vim -Nu vimrc +Vader! tests/basic/cmake_info.vader

vim -Nu vimrc +Vader! tests/build/build_cmake_targets.vader
vim -Nu vimrc +Vader! tests/build/ninja_generator.vader
vim -Nu vimrc +Vader! tests/build/job.vader
vim -Nu vimrc +Vader! tests/build/dispatch.vader
vim -Nu vimrc +Vader! tests/build/cmake_kits.vader

vim -Nu vimrc +Vader! tests/run/run_target.vader
vim -Nu vimrc +Vader! tests/run/ctest.vader

vim -Nu vimrc +Vader! tests/integration/ccmake.vader
vim -Nu vimrc +Vader! tests/integration/vimspector.vader
set code=%ERRORLEVEL%

type vader_output
exit /B %code%
