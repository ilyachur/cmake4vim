" cmake4vim.vim - Vim plugin for cmake integration
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

" Initialization {{{ "
if exists('g:loaded_cmake4vim_plugin')
    finish
endif
let g:loaded_cmake4vim_plugin = 1

silent call cmake4vim#init()

augroup cmake
    autocmd BufWritePre *.cmake call cmake4vim#CMakeFileSaved()
    autocmd BufWritePre CMakeLists.txt call cmake4vim#CMakeFileSaved()
augroup END
" }}} Initialization "

" Commands {{{ "
command!       -nargs=? -complete=custom,cmake4vim#CompleteTarget       CMake                   call cmake4vim#GenerateCMake(<f-args>)
command!       -nargs=? -complete=custom,cmake4vim#CompleteTarget       CMakeResetAndReload     call cmake4vim#ResetAndReloadCMake(<f-args>)
command!       -nargs=? -complete=custom,cmake4vim#CompleteTarget       CMakeBuild              call cmake4vim#CMakeBuild(<f-args>)
command!       -nargs=1 -complete=custom,cmake4vim#CompleteTarget       CMakeSelectTarget       call cmake4vim#SelectTarget(<f-args>)
command!       -nargs=1 -complete=custom,cmake4vim#CompleteBuildType    CMakeSelectBuildType    call cmake4vim#SelectBuildType(<f-args>)
command!       -nargs=1 -complete=custom,cmake4vim#CompleteKit          CMakeSelectKit          call cmake4vim#SelectKit(<f-args>)
command!       -nargs=? -complete=custom,cmake4vim#CompleteCCMakeModes  CCMake                  call cmake4vim#CCMake(<f-args>)
command! -bang -nargs=?  CTest              call cmake4vim#CTest(<bang>0, <f-args>)
command! -bang -nargs=?  CTestCurrent       call cmake4vim#CTestCurrent(<bang>0, <f-args>)
command!                 CMakeReset         call cmake4vim#ResetCMakeCache()
command!                 CMakeClean         call cmake4vim#CleanCMake()
command!                 CMakeInfo          call utils#window#OpenCMakeInfo()
command! -bang -nargs=*  CMakeRun           call cmake4vim#RunTarget(<bang>0, <f-args>)
command!       -nargs=?  CMakeCompileSource call cmake4vim#CompileSource(<f-args>)
" }}} Commands "

" Mappings {{{
nnoremap <silent> <Plug>(CMake)                     :call cmake4vim#GenerateCMake()<CR>
nnoremap <silent> <Plug>(CMakeResetAndReload)       :call cmake4vim#ResetAndReloadCMake()<CR>
nnoremap <silent> <Plug>(CMakeReset)                :call cmake4vim#ResetCMakeCache()<CR>
nnoremap <silent> <Plug>(CMakeBuild)                :call cmake4vim#CMakeBuild()<CR>
nnoremap <silent> <Plug>(CMakeClean)                :call cmake4vim#CleanCMake()<CR>
nnoremap <silent> <Plug>(CMakeInfo)                 :call utils#window#OpenCMakeInfo()<CR>
nnoremap <silent> <Plug>(CMakeRun)                  :call cmake4vim#RunTarget(0)<CR>
nnoremap <silent> <Plug>(CTest)                     :call cmake4vim#CTest(0)<CR>
nnoremap <silent> <Plug>(CTestCurrent)              :call cmake4vim#CTestCurrent(0)<CR>
nnoremap <silent> <Plug>(CCMake)                    :call cmake4vim#CCMake()<CR>
nnoremap <silent> <Plug>(CMakeCompileSource)        :call cmake4vim#CompileSource()<CR>
" }}} Mappings
