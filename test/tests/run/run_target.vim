function! SetUp()
    silent call RemoveCMakeDirs()

    silent call ResetPluginOptions()

    " to shorten test time
    let g:cmake_build_type = 'Debug'
endfunction

function! Test_CMakeRun_Should_not_find_non_binary_target()
    call assert_false( isdirectory('cmake-build-Debug'), 'Build directory should not exist' )
    silent CMake
    call assert_true( filereadable('cmake-build-Debug/CMakeCache.txt'), 'CMakeCache.txt should be generated' )
    silent CMakeBuild
    call assert_true( empty( utils#cmake#getBinaryPath() ) )
endfunction

function! Test_CMakeRun_Should_not_find_library_target()
    if utils#cmake#verNewerOrEq( [ 3, 14 ] )
        call assert_false( isdirectory('cmake-build-Debug'), 'Build directory should not exist' )
        silent CMake
        call assert_true( filereadable('cmake-build-Debug/CMakeCache.txt'), 'CMakeCache.txt should be generated' )
        CMakeSelectTarget test_lib
        silent CMakeBuild
        call assert_true( empty( utils#cmake#getBinaryPath() ) )
    endif
endfunction

function! Test_CMakeRun_Should_find_binary_target()
    call assert_false( isdirectory('cmake-build-Debug'), 'Build directory should not exist' )
    silent CMake
    call assert_true( filereadable('cmake-build-Debug/CMakeCache.txt'), 'CMakeCache.txt should be generated' )
    CMakeSelectTarget test_app
    silent CMakeBuild
    call assert_equal( 'test_app', g:cmake_build_target )

    if !has('win32')
        call assert_true( filereadable('cmake-build-Debug/app/test_app'), 'app should be built' )
    elseif utils#cmake#verNewerOrEq( [ 3, 14 ] )
        call assert_true( filereadable('cmake-build-Debug/app/Debug/test_app.exe'), 'app should be built' )
    endif

    let l:result = utils#cmake#getBinaryPath()

    if !has( 'win32' )
        call assert_equal( utils#fs#fnameescape( utils#cmake#getBuildDir() . '/app/test_app'           ), utils#fs#fnameescape( l:result ) )
    elseif utils#cmake#verNewerOrEq( [ 3, 14 ] )
        call assert_equal( utils#fs#fnameescape( utils#cmake#getBuildDir() . '/app/Debug/test_app.exe' ), utils#fs#fnameescape( l:result ) )
    endif
endfunction

function! Test_CMakeRun_Run_for_empty_target()
    let g:cmake_build_target = ''
    CMakeRun
    redir => l:error_message
    1messages
    redir END
    call assert_equal( '\nExecutable \"\" was not found', l:error_message )
    silent cclose
endfunctio

function! Test_CMakeRun_Run_test_app_target_and_open_quickfix()
    if !has( 'win32' ) || utils#cmake#verNewerOrEq( [ 3, 14 ] )
        silent CMake
        silent CMakeSelectTarget test_app
        silent CMakeBuild
        silent CMakeRun
        call assert_equal( 'F1', getqflist()[ 0 ].text )
        silent cclose
    endif
endfunction

function! Test_CMakeRun_Run_non_binary_target_and_open_quickfix()
    silent CMake
    silent CMakeBuild
    silent CMakeSelectTarget all
    silent CMakeRun
    call assert_equal( 'Executable "all" was not found', v:errmsg )
    silent cclose
endfunction

function! Test_CMakeRun_Run_test_app_target_with_runtime_output_and_open_quickfix()
    if !has( 'win32' ) && utils#cmake#verNewerOrEq( [ 3, 14 ] )
        silent CMake -DCMAKE_RUNTIME_OUTPUT_DIRECTORY=/tmp
        silent CMakeSelectTarget test_app
        silent CMakeBuild
        silent CMakeRun 123
        call assert_equal( '123 F1', getqflist()[ 0 ].text )
        silent cclose
    endif
endfunction

function! Test_CMakeRun_Run_test_app_target_with_mask_arguments()
    if !has( 'win32' ) || utils#cmake#verNewerOrEq( [ 3, 14 ] )
        silent CMake
        silent CMakeSelectTarget test_app
        silent CMakeBuild
        silent CMakeRun --gtest_filter=Test*
        call assert_equal( '--gtest_filter=Test* F1', getqflist()[ 0 ].text )
        silent cclose
    endif
endfunction

" needs to be investigated when someone stumbles upon it ( @mark2185 )
function! Test_CMakeRun_Run_test_app_target_with_mask_arguments_with_job_executor()
    if !has( 'win32' )
        silent CMake
        silent CMakeSelectTarget test_app
        silent CMakeBuild
        let g:cmake_build_executor = 'job'
        call assert_equal( -1, bufnr( 'cmake4vim_execute' ) )
        silent CMakeRun --gtest_filter=Test*
        sleep 10
        call assert_equal( -1, bufnr( 'cmake4vim_execute' ) )
        call assert_equal( '--gtest_filter=Test* F1', getqflist()[ 0 ].text )
        silent cclose
    endif
endfunction
