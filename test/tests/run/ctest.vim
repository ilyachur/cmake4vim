function! SetUp()
    silent call RemoveCMakeDirs()

    silent call ResetPluginOptions()
    let g:cmake_usr_args = '-DENABLE_TESTS=ON'
    " to shorten test time
    let g:cmake_build_type = 'Debug'
endfunction

function s:ValidateBuild()
    if !has( 'win32' )
        call assert_true( filereadable( 'cmake-build-Debug/app/test_app'      ), 'app should be built'        )
        call assert_true( filereadable( 'cmake-build-Debug/tests/unit_tests'  ), 'unit_tests should be built' )
        call assert_true( filereadable( 'cmake-build-Debug/lib/libtest_lib.a' ), 'test_lib should be built'   )
    else
        call assert_true( filereadable( 'cmake-build-Debug/app/Debug/test_app.exe'     ), 'app should be built'        )
        call assert_true( filereadable( 'cmake-build-Debug/tests/Debug/unit_tests.exe' ), 'unit_tests should be built' )
        call assert_true( filereadable( 'cmake-build-Debug/lib/Debug/test_lib.lib'     ), 'test_lib should be built'   )
    endif
endfunction

function! Test_CTest_Check_CTest_for_empty_project()
    " enable tests for windows with last cmake
    call assert_false( isdirectory( 'cmake-build-Debug' ), 'Build directory should not exist' )
    CTest
    call assert_false( isdirectory( 'cmake-build-Debug' ), 'Build directory should not exist' )
endfunction

function! Test_CTest_Run_tests_with_default_settings()
    " enable tests for windows with last cmake
    if !has( 'win32' ) || utils#cmake#verNewerOrEq( [ 3, 14 ] )
        call assert_false( isdirectory( 'cmake-build-Debug' ), 'Build directory should not exist' )
        silent CMake
        call assert_true( filereadable( 'cmake-build-Debug/CMakeCache.txt' ), 'CMakeCache.txt should be generated' )
        silent CMakeBuild
        call s:ValidateBuild()
        if !has( 'win32' )
            silent call system( 'cmake-build-Debug/tests/unit_tests' )
            call assert_equal( 0, v:shell_error )
        endif
    endif
endfunction

function! Test_CTest_Run_tests_with_custom_settings()
    " enable tests for windows with last cmake
    if !has( 'win32' ) || utils#cmake#verNewerOrEq( [ 3, 14 ] )
        call assert_false( isdirectory( 'cmake-build-Debug' ), 'Build directory should not exist' )
        silent CMake -DCUSTOM_OP=ON
        call assert_true( filereadable( 'cmake-build-Debug/CMakeCache.txt' ), 'CMakeCache.txt should be generated' )
        silent CMakeBuild
        call s:ValidateBuild()
        if !has( 'win32' )
            silent call system( 'cmake-build-Debug/tests/unit_tests' )
            call assert_equal( 1, v:shell_error )
        endif
    endif
endfunction

function! Test_CTest_CTest_with_default_settings()
    " enable tests for windows with last cmake
    if !has( 'win32' ) || utils#cmake#verNewerOrEq( [ 3, 14 ] )
        call assert_false( isdirectory( 'cmake-build-Debug' ), 'Build directory should not exist' )
        silent CMake
        call assert_true( filereadable( 'cmake-build-Debug/CMakeCache.txt' ), 'CMakeCache.txt should be generated' )
        silent CMakeBuild
        call s:ValidateBuild()
        silent CTest
    endif
endfunction

function! Test_CTest_CTest_check_target()
    " enable tests for windows with last cmake
    if !has( 'win32' ) || utils#cmake#verNewerOrEq( [ 3, 14 ] )
        call assert_false( isdirectory( 'cmake-build-Debug' ), 'Build directory should not exist' )
        silent CMake
        call assert_true( filereadable( 'cmake-build-Debug/CMakeCache.txt' ), 'CMakeCache.txt should be generated' )
        silent CMakeBuild
        call s:ValidateBuild()
        if !has( 'win32' )
            call assert_equal( 'all'      , g:cmake_build_target )
        else
            call assert_equal( 'ALL_BUILD', g:cmake_build_target )
        endif
        silent CTest
        if !has( 'win32' )
            call assert_equal( 'all'      , g:cmake_build_target )
        else
            call assert_equal( 'ALL_BUILD', g:cmake_build_target )
        endif
    endif
endfunction

function! Test_CTest_CTest_with_custom_settings()
    " enable tests for windows with last cmake
    if !has( 'win32' ) || utils#cmake#verNewerOrEq( [ 3, 14 ] )
        call assert_false( isdirectory( 'cmake-build-Debug' ), 'Build directory should not exist' )
        silent CMake -DCUSTOM_OP=ON
        call assert_true( filereadable( 'cmake-build-Debug/CMakeCache.txt' ), 'CMakeCache.txt should be generated' )
        silent CMakeBuild
        call s:ValidateBuild()
        if !has( 'win32' )
            silent call system( 'cmake-build-Debug/tests/unit_tests' )
            call assert_equal( 1, v:shell_error )
        endif
        silent CTest
    endif
endfunction

function! Test_CTest_CTest_with_custom_args()
    if !has( 'win32' )
        call assert_false( isdirectory( 'cmake-build-Debug' ), 'Build directory should not exist' )
        silent CMake -DCUSTOM_OP=ON
        call assert_true( filereadable( 'cmake-build-Debug/CMakeCache.txt' ), 'CMakeCache.txt should be generated' )
        silent CMakeBuild
        call s:ValidateBuild()
        let g:cmake_ctest_args = '-j2 --output-on-failure --verbose'
        silent CTest -R 'non-existant_pattern'
        silent copen
        call assert_true( w:quickfix_title =~# "-j2 --output-on-failure --verbose -R 'non-existant_pattern'" )
        silent cclose
    endif
endfunction

function! Test_CTest_CTest_with_custom_args_and_a_bang()
    if !has( 'win32' )
        call assert_false( isdirectory( 'cmake-build-Debug' ), 'Build directory should not exist' )
        silent CMake -DCUSTOM_OP=ON
        call assert_true( filereadable( 'cmake-build-Debug/CMakeCache.txt' ), 'CMakeCache.txt should be generated' )
        silent CMakeBuild
        call s:ValidateBuild()
        let g:cmake_ctest_args = '-j2 --output-on-failure --verbose'
        silent CTest! -R 'non-existant_pattern'
        silent copen
        call assert_true( w:quickfix_title !~# '-j2 --output-on-failure --verbose' )
        call assert_true( w:quickfix_title =~# "-R 'non-existant_pattern'" )
        silent cclose
    endif
endfunction
