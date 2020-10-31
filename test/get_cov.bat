@echo off

pushd %~dp0
set PLUGIN_HOME=%CD%\..\
set HOME=%CD%\tmp

python -m covimerage write_coverage --data-file %PLUGIN_HOME%\.coverage_covimerage %HOME%\vim-profile.txt
popd
