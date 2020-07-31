" cmake4vim.vim - Vim plugin for cmake integration
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

" Initialization {{{ "
if exists('g:loaded_cmake4vim_plugin')
    finish
endif
let g:loaded_cmake4vim_plugin = 1

augroup cmake
    autocmd BufWritePre *.cmake call cmake4vim#CMakeFileSaved()
    autocmd BufWritePre CMakeLists.txt call cmake4vim#CMakeFileSaved()
augroup END
" }}} Initialization "

" Commands {{{ "
command! -nargs=? -complete=custom,cmake4vim#CompleteTarget CMake call cmake4vim#GenerateCMake(<f-args>)
command! -nargs=? -complete=custom,cmake4vim#CompleteTarget CMakeResetAndReload call cmake4vim#ResetAndReloadCMake(<f-args>)
command! -nargs=? -complete=custom,cmake4vim#CompleteTarget CMakeBuild call cmake4vim#CMakeBuild(<f-args>)
command! -nargs=1 -complete=custom,cmake4vim#CompleteTarget CMakeSelectTarget call cmake4vim#SelectTarget(<f-args>)
command! CMakeReset call cmake4vim#ResetCMakeCache()
command! CMakeClean call cmake4vim#CleanCMake()
" }}} Commands "

