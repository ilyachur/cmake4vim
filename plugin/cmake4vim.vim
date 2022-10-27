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

" Options {{{ "
" Common
let g:cmake_executable            = get(g:, "cmake_executable"           , 'cmake'       )
let g:cmake_reload_after_save     = get(g:, 'cmake_reload_after_save'    , 0             )
let g:cmake_change_build_command  = get(g:, 'cmake_change_build_command' , 1             )
let g:cmake_compile_commands      = get(g:, 'cmake_compile_commands'     , 0             )
let g:cmake_compile_commands_link = get(g:, 'cmake_compile_commands_link', ''            )
let g:cmake_vimspector_support    = get(g:, 'cmake_vimspector_support'   , 0             )
let g:cmake_vimspector_default_configuration = get(g:, 'cmake_vimspector_default_configuration', {
            \ 'adapter': '',
            \ 'configuration': {
                \ 'request': 'launch',
                \ 'cwd': '${workspaceRoot}',
                \ 'Mimode': '',
                \ 'args': [],
                \ 'program': ''
                \ }
            \ })

" Optional variable allow to specify the build executor
" Possible values: 'job', 'dispatch', 'system', ''
let g:cmake_build_executor        = get(g:, 'cmake_build_executor'       , '')
let g:cmake_build_executor_height = get(g:, 'cmake_build_executor_height', 10)

" Build path
let g:cmake_build_path_pattern    = get(g:, 'cmake_build_path_pattern'   , ''            )
let g:cmake_build_dir             = get(g:, 'cmake_build_dir'            , ''            )
let g:cmake_build_dir_prefix      = get(g:, 'cmake_build_dir_prefix'     , 'cmake-build-')

" CMake build
let g:make_arguments              = get(g:, 'make_arguments'             , ''            )
let g:cmake_build_target          = get(g:, 'cmake_build_target'         , ''            )
let g:cmake_build_type            = get(g:, 'cmake_build_type'           , ''            )
let g:cmake_src_dir               = get(g:, 'cmake_src_dir'              , ''            )
let g:cmake_usr_args              = get(g:, 'cmake_usr_args'             , ''            )
let g:cmake_ctest_args            = get(g:, 'cmake_ctest_args'           , ''            )
let g:cmake_variants              = get(g:, 'cmake_variants'             , {}            )
let g:cmake_selected_kit          = get(g:, 'cmake_selected_kit'         , ''            )
let g:cmake_kits                  = get(g:, 'cmake_kits'                 , {}            )
let g:cmake_kits_global_path      = get(g:, 'cmake_kits_global_path'     , ''            )

" }}} Options "

" Commands {{{ "
command!       -nargs=? -complete=custom,cmake4vim#CompleteTarget       CMake                   call cmake4vim#GenerateCMake(<f-args>)
command!       -nargs=? -complete=custom,cmake4vim#CompleteTarget       CMakeResetAndReload     call cmake4vim#ResetAndReloadCMake(<f-args>)
command!       -nargs=? -complete=custom,cmake4vim#CompleteTarget       CMakeBuild              call cmake4vim#CMakeBuild(<f-args>)
command!       -nargs=1 -complete=custom,cmake4vim#CompleteTarget       CMakeSelectTarget       call cmake4vim#SelectTarget(<f-args>)
command!       -nargs=1 -complete=custom,cmake4vim#CompleteBuildType    CMakeSelectBuildType    call cmake4vim#SelectBuildType(<f-args>)
command!       -nargs=1 -complete=custom,cmake4vim#CompleteKit          CMakeSelectKit          call cmake4vim#SelectKit(<f-args>)
command!       -nargs=? -complete=custom,cmake4vim#CompleteCCMakeModes  CCMake                  call cmake4vim#CCMake(<f-args>)
command! -bang -nargs=?  CTest              call cmake4vim#CTest(<bang>0, <f-args>)
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
nnoremap <silent> <Plug>(CCMake)                    :call cmake4vim#CCMake()<CR>
nnoremap <silent> <Plug>(CMakeCompileSource)        :call cmake4vim#CompileSource()<CR>
" }}} Mappings
