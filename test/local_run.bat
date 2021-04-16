@echo off

set VADER_OUTPUT_FILE=%~dp0\vader_output
type nul > "%VADER_OUTPUT_FILE%"

pushd %~dp0
set HOME=%CD%\tmp
if not exist %HOME% mkdir %HOME%
git clone --depth 1 https://github.com/junegunn/vader.vim.git %HOME%\.vim\plugged\vader.vim
git clone --depth 1 https://github.com/tpope/vim-dispatch.git %HOME%\.vim\plugged\vim-dispatch
del %HOME%\vim-profile.txt

vim -Nu vimrc +Vader!*
set code=%ERRORLEVEL%

type vader_output
exit /B %code%
