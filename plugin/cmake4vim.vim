" cmake4vim.vim - Vim plugin for cmake integration
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

" Initialization {{{ "
if exists("loaded_cmake4vim_plugin")
  finish
endif
let loaded_cmake4vim_plugin = 1

autocmd BufWritePre *.cmake call cmake4vim#CMakeFileSaved()
autocmd BufWritePre CMakeLists.txt call cmake4vim#CMakeFileSaved()
" }}} Initialization "

" Commands {{{ "
command! -nargs=? CMake call cmake4vim#GenerateCMake(<f-args>)
command! -nargs=? CMakeResetAndReload call cmake4vim#ResetAndReloadCMake(<f-args>)
command! CMakeReset call cmake4vim#ResetCMakeCache()
command! CMakeClean call cmake4vim#CleanCMake()
command! -nargs=? CMakeSelectTarget call cmake4vim#SelectTarget(<f-args>)
command! CMakeCompile call cmake4vim#Compile()
" }}} Commands "

