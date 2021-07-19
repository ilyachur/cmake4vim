function! SetUp()
    silent call RemoveCMakeDirs()

    silent call ResetPluginOptions()
    let g:cmake_build_executor = 'job'
endfunction

function! TearDown()
    silent cclose
endfunction

function s:WaitFor( filename, duration )
    let l:iter = 0
    while l:iter < a:duration
        if !filereadable( a:filename )
            return
        endif
        sleep 1
        let l:iter += 1
    endwhile
endfunction

function! Test_Job_executor_Generate_cmake_project_with_default_settings()
    if !has( 'win32' ) " Skip for Windows
        call assert_false( isdirectory( 'cmake-build-Release' ), 'Build directory should not exist' )
        call assert_equal( -1, bufnr( 'cmake4vim_execute' ) )
        silent CMake
        call s:WaitFor( 'cmake-build-Release/CMakeCache.txt', 40 )
        call assert_true( filereadable( 'cmake-build-Release/CMakeCache.txt' ), 'CMakeCache.txt should be generated' )
        silent call utils#exec#job#stop()
        call assert_equal( -1, bufnr( 'cmake4vim_execute' ) )
    endif
endfunction

function! Test_Job_executor_Generate_cmake_project_with_default_settings_and_build_error_target()
    if !has( 'win32' ) " Skip for Windows
        call assert_false( isdirectory( 'cmake-build-Release' ), 'Build directory should not exist' )
        call assert_equal( -1, bufnr( 'cmake4vim_execute' ) )
        silent CMake
        call s:WaitFor( 'cmake-build-Release/CMakeCache.txt', 40 )
        call assert_true( filereadable('cmake-build-Release/CMakeCache.txt'), 'CMakeCache.txt should be generated' )
        silent CMakeBuild incorrect_lib

        let l:iter = 0
        let g:window_counter = 0
        while l:iter < 40
            windo let g:window_counter = g:window_counter + 1
            if g:window_counter > 1
                break
            endif
            sleep 1
            let l:iter += 1
        endwhile
        call assert_true( g:window_counter > 1 )
        unlet g:window_counter

        silent call utils#exec#job#stop()
        call assert_equal( -1, bufnr( 'cmake4vim_execute' ) )
    endif
endfunction

function! Test_Job_executor_Check_job_cancel_command_without_run()
    call assert_equal( -1, bufnr( 'cmake4vim_execute' ) )
    silent call utils#exec#job#stop()
    call assert_equal( -1, bufnr( 'cmake4vim_execute' ) )
endfunction

function! Test_Job_executor_Check_job_cancel_command()
    call assert_equal( -1, bufnr( 'cmake4vim_execute' ) )
    silent call utils#exec#job#run( 'sleep 10', 1, '' )
    silent call utils#exec#job#stop()
    call assert_equal( -1, bufnr( 'cmake4vim_execute' ) )
endfunction

function! Test_Job_executor_Run_2_jobs_at_once()
    silent call utils#exec#job#run( 'sleep 10', 1, '' )
    let l:ret_code = utils#exec#job#run( 'sleep 10', 1, '' )
    call assert_equal( -1, ret_code )
    silent call utils#exec#job#stop()
    call assert_equal( -1, bufnr( 'cmake4vim_execute' ) )
endfunction

function! Test_Job_executor_Run_job_and_keep_the_alternate_file()
    silent edit first.txt
    silent edit second.txt
    call assert_equal( 'first.txt', bufname( '#' ) )
    silent call utils#exec#job#run( 'sleep 1', 1, '' )
    call assert_equal( 'first.txt', bufname( '#' ) )
    sleep 2
    copen
    cclose
    call assert_equal( 'first.txt', bufname( '#' ) )
endfunction
