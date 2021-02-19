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
if !exists('g:make_arguments')
    let g:make_arguments = ''
endif
if !exists('g:cmake_build_target')
    let g:cmake_build_target = ''
endif
if !exists('g:cmake_change_build_command')
    let g:cmake_change_build_command = 1
endif
if !exists('g:cmake_reload_after_save')
    let g:cmake_reload_after_save = 0
endif
if !exists('g:cmake_compile_commands')
    let g:cmake_compile_commands = 0
endif
if !exists('g:cmake_compile_commands_link')
    let g:cmake_compile_commands_link = ''
endif
if !exists('g:cmake_build_type')
    let g:cmake_build_type = ''
endif
if !exists('g:cmake_build_dir')
    let g:cmake_build_dir = ''
endif
if !exists('g:cmake_src_dir')
    let g:cmake_src_dir = ''
endif
if !exists('g:cmake_build_dir_prefix')
    let g:cmake_build_dir_prefix = 'cmake-build-'
endif
if !exists('g:cmake_project_generator')
    let g:cmake_project_generator = ''
endif
if !exists('g:cmake_install_prefix')
    let g:cmake_install_prefix = ''
endif
if !exists('g:cmake_c_compiler')
    let g:cmake_c_compiler = ''
endif
if !exists('g:cmake_cxx_compiler')
    let g:cmake_cxx_compiler = ''
endif
if !exists('g:cmake_usr_args')
    let g:cmake_usr_args = ''
endif
if !exists('g:cmake_vimspector_support')
    let g:cmake_vimspector_support = 0
endif

let g:cmake_variants = get( g:, 'cmake_variants', {} )

" Optional variable allow to specify the build executor
" Possible values: 'job', 'dispatch', 'system', ''
if !exists('g:cmake_build_executor')
    let g:cmake_build_executor = ''
endif
" }}} Options "

" Commands {{{ "
command! -nargs=? -complete=custom,cmake4vim#CompleteTarget CMake call cmake4vim#GenerateCMake(<f-args>)
command! -nargs=? -complete=custom,cmake4vim#CompleteTarget CMakeResetAndReload call cmake4vim#ResetAndReloadCMake(<f-args>)
command! -nargs=? -complete=custom,cmake4vim#CompleteTarget CMakeBuild call cmake4vim#CMakeBuild(<f-args>)
command! -nargs=1 -complete=custom,cmake4vim#CompleteTarget CMakeSelectTarget call cmake4vim#SelectTarget(<f-args>)
command! -nargs=1 -complete=custom,cmake4vim#CompleteBuildType CMakeSelectBuildType call cmake4vim#SelectBuildType(<f-args>)
command! -nargs=?  CTest call cmake4vim#CTest(<f-args>)
command! CMakeReset call cmake4vim#ResetCMakeCache()
command! CMakeClean call cmake4vim#CleanCMake()
command! CMakeInfo call utils#window#OpenCMakeInfo()
command! -nargs=1 CMakeSelectBuildType call cmake4vim#SelectBuildType(<f-args>)
command! -bang -nargs=* CMakeRun call cmake4vim#RunTarget(<bang>0, <f-args>)
" }}} Commands "
