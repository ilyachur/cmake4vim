" for debugging, stop after an exception occurrs
" and don't call TearDown
let s:stop_on_exception = v:false
let s:stop_on_failure   = v:false

let g:test_name = expand( '%:p:t' )
let g:test_path = expand( '%:p:h' )
let g:logfile   = printf( '%s/%s.failed.log', g:test_path, g:test_name )

" source the file that's open to define all the functions
source %
" and then close it
%bwipe!

" Extract the list of functions matching ^Test_
let s:tests = split( substitute( execute( 'function /^Test_' ),
            \ 'function \(\k*()\)',
            \ '\1',
            \ 'g' ) )

" Save all errors
let s:errors = []

" Avoid stopping at the "hit enter" prompt
set nomore

function! s:RunTests()
    call s:Start()

    " cd into the actual project where all tests will be run
    execute 'cd ' . fnameescape( expand( '%:p:h' ) .  '/cmake projects/test proj' )

    " ... run all of the Test_* functions
    for test_function in s:tests
        "TODO: add error handling for setup and teardown functions
        if exists( '*SetUp' )
            call SetUp()
        endif

        " so it can be referenced in s:EarlyExit
        let g:test_function = test_function
        augroup early_exit
            au!
            autocmd VimLeavePre * call s:EarlyExit()
        augroup END
        try
            execute 'call ' test_function
        catch
            call add( v:errors, printf(
                        \   'Uncaught exception in test %s:%s: %s at %s',
                        \   g:test_name,
                        \   test_function,
                        \   v:exception,
                        \   v:throwpoint ) )

            if s:stop_on_exception
                let s:exception_caught = v:true
                break
            endif
        finally
            augroup early_exit
                au!
            augroup END
        endtry

        if exists( '*TearDown' )
            call TearDown()
        endif
        call s:EndTest( test_function )
    endfor

    if !exists( 's:exception_caught' )
        call s:Done()
    endif
endfunction

"{{{ Helper testing framework functions
function! s:EarlyExit()
    call add( v:errors, printf(
                \ 'Test %s:%s caused Vim to quit!',
                \  g:test_name,
                \  g:test_function ) )
    call s:EndTest()
    call s:Done()
endfunction

function! s:EndTest(...)
    if !empty( v:errors )
        " Append errors to test failure log
        call writefile( v:errors, g:logfile, 'as' )
        if s:stop_on_failure
            let s:tests = []
            echom 'Failing test: ' . a:1
            execute 'edit ' . g:test_path . '/' . g:test_name 
            call search( a:1 )
        endif
    endif
    call extend( s:errors, v:errors )
    let v:errors = []
endfunction

function! s:Done()
    if !empty( s:errors )
        " Quit with an error code
        cquit!
    else
        " Delete logs since they're empty
        call Remove( g:logfile )
        quit!
    endif
endfunction

function! s:Start()
    " Truncate logfile
    call writefile( [], g:logfile, 's' )
endfunction
"}}}

"{{{ Helper functions
function! Remove( path )
    if empty( a:path ) || !filewritable( fnameescape( a:path ) )
        return
    endif

    if has('win32')
        if isdirectory( a:path ) 
            silent call system( printf( 'rd  /S /Q "%s" >nul 2>&1', a:path ) )
        else
            silent call system( printf( 'del /F /Q "%s" >nul 2>&1', a:path ) )
        endif
    else
        silent call system( printf( 'rm -rf "%s"', a:path ) )
    endif
endfunction

function! RemoveCMakeDirs()
    for l:value in ['cmake-build-Release', 'cmake-build-Debug', 'cmake-build-RelWithDebInfo', 'cmake-build-MinSizeRel', 'cmake-build']
        silent call Remove( l:value )
    endfor
endfunction

function! ResetPluginOptions()
    let g:cmake_executable            = 'cmake'
    let g:cmake_build_executor        = 'system'
    let g:cmake_build_dir_prefix      = 'cmake-build-'

    let g:cmake_change_build_command  = 1
    let g:cmake_reload_after_save     = 0
    let g:cmake_compile_commands      = 0
    let g:cmake_vimspector_support    = 0

    let g:cmake_variants              = {}
    let g:cmake_kits                  = {}
    let g:cmake_build_path_pattern    = []

    let g:cmake_compile_commands_link = ''
    let g:cmake_build_dir             = ''
    let g:make_arguments              = ''
    let g:cmake_build_target          = ''
    let g:cmake_build_type            = ''
    let g:cmake_src_dir               = ''
    let g:cmake_usr_args              = ''
    let g:cmake_ctest_args            = ''
    let g:cmake_kits_global_path      = ''
    let g:cmake_selected_kit          = ''
    let g:cmake_project_generator     = ''
    let g:cmake_install_prefix        = ''
    let g:cmake_c_compiler            = ''
    let g:cmake_cxx_compiler          = ''
    let g:cmake_toolchain_file        = ''
    call utils#cmake#common#resetCache()
endfunction
"}}}

call s:RunTests()

call RemoveCMakeDirs()
