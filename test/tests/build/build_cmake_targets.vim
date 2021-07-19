function! SetUp()
    call RemoveCMakeDirs()
    call ResetPluginOptions()
endfunction

function! Test_CMake_targets_Generate_cmake_project_with_default_settings()
    " enable tests for windows with last cmake
    if !has( 'win32' ) || utils#cmake#verNewerOrEq( [3, 14] )
        call assert_false( isdirectory( 'cmake-build-Release' ), 'Build directory should not exist' )
        silent CMake
        call assert_true( filereadable( 'cmake-build-Release/CMakeCache.txt' ), 'CMakeCache.txt should be generated' )
        silent CMakeBuild
        if !has('win32')
            call assert_true( filereadable( 'cmake-build-Release/app/test_app'      ), 'app should be built'      )
            call assert_true( filereadable( 'cmake-build-Release/lib/libtest_lib.a' ), 'test_lib should be built' )
            silent call system( 'cmake-build-Release/app/test_app' )
            call assert_equal( 0, v:shell_error )
        else
            call assert_true( filereadable( 'cmake-build-Release/app/Debug/test_app.exe' ), 'app should be built'      )
            call assert_true( filereadable( 'cmake-build-Release/lib/Debug/test_lib.lib' ), 'test_lib should be built' )
        endif
    endif
endfunction

function! Test_CMake_targets_Generate_cmake_project_with_custom_options()
    " enable tests for windows with last cmake
    if !has( 'win32' ) || utils#cmake#verNewerOrEq( [ 3, 14 ] )
        call assert_false( isdirectory( 'cmake-build-Release' ), 'Build directory should not exist' )
        let g:cmake_usr_args='-DCUSTOM_OP=ON'
        silent CMake
        call assert_true( filereadable( 'cmake-build-Release/CMakeCache.txt' ), 'CMakeCache.txt should be generated' )
        silent CMakeBuild
        if !has('win32')
            call assert_true( filereadable( 'cmake-build-Release/app/test_app'      ), 'app should be built'      )
            call assert_true( filereadable( 'cmake-build-Release/lib/libtest_lib.a' ), 'test_lib should be built' )
            silent call system( 'cmake-build-Release/app/test_app' )
            call assert_equal( 1, v:shell_error )
        else
            call assert_true( filereadable( 'cmake-build-Release/app/Debug/test_app.exe' ), 'app should be built'      )
            call assert_true( filereadable( 'cmake-build-Release/lib/Debug/test_lib.lib' ), 'test_lib should be built' )
            silent call system( 'cmake-build-Release/app/Debug/test_app.exe' )
            call assert_equal( 1, v:shell_error )
        endif
    endif
endfunction

function! Test_CMake_targets_Generate_cmake_project_with_custom_options_as_argument()
    " enable tests for windows with last cmake
    if !has( 'win32' ) || utils#cmake#verNewerOrEq( [ 3, 14 ] )
        call assert_false( isdirectory( 'cmake-build-Release' ), 'Build directory should not exist' )
        silent CMake -DCUSTOM_OP=ON
        call assert_true( filereadable( 'cmake-build-Release/CMakeCache.txt' ), 'CMakeCache.txt should be generated' )
        silent CMakeBuild
        if !has( 'win32' )
            call assert_true( filereadable( 'cmake-build-Release/app/test_app' ), 'app shouldn be built'          )
            call assert_true( filereadable( 'cmake-build-Release/lib/libtest_lib.a' ), 'test_lib should be built' )
            silent call system( 'cmake-build-Release/app/test_app' )
            call assert_equal( 1, v:shell_error ) 
        else
            call assert_true( filereadable( 'cmake-build-Release/app/Debug/test_app.exe' ), 'app should be built'      )
            call assert_true( filereadable( 'cmake-build-Release/lib/Debug/test_lib.lib' ), 'test_lib should be built' )
            silent call system( 'cmake-build-Release/app/Debug/test_app.exe' )
            call assert_equal( 1, v:shell_error ) 
        endif
    endif
endfunction

function! Test_CMake_targets_Check_CMake_generator()
    " enable tests for windows with last cmake
    if !has( 'win32' ) || utils#cmake#verNewerOrEq( [ 3, 14 ] )
        call assert_false( isdirectory( 'cmake-build-Release' ), 'Build directory should not exist' )
        silent CMake
        call assert_true( filereadable( 'cmake-build-Release/CMakeCache.txt' ), 'CMakeCache.txt should be generated' )
        let l:cmake_info = utils#cmake#common#getInfo()
        let l:cmake_gen = l:cmake_info[ 'cmake' ][ 'generator' ]
        if has('win32')
            call assert_true( l:cmake_gen =~# utils#gen#vs#getGeneratorName()  , 'Cmake Generator '. l:cmake_gen )
        else
            call assert_true( l:cmake_gen =~# utils#gen#make#getGeneratorName(), 'Cmake Generator '. l:cmake_gen )
        endif
    endif
endfunction

function! Test_CMake_targets_Check_CMakeClean()
    " enable tests for windows with last cmake
    if !has( 'win32' ) || utils#cmake#verNewerOrEq( [ 3, 14 ] )
        call assert_false( isdirectory( 'cmake-build-Release' ), 'Build directory should not exist' )
        silent CMake
        call assert_true( filereadable( 'cmake-build-Release/CMakeCache.txt' ), 'CMakeCache.txt should be generated' )
        silent CMakeBuild
        if !has('win32')
            call assert_true( filereadable( 'cmake-build-Release/app/test_app'      ), 'app should be built'      )
            call assert_true( filereadable( 'cmake-build-Release/lib/libtest_lib.a' ), 'test_lib should be built' )
        else
            call assert_true( filereadable( 'cmake-build-Release/app/Debug/test_app.exe' ), 'app should be built'      )
            call assert_true( filereadable( 'cmake-build-Release/lib/Debug/test_lib.lib' ), 'test_lib should be built' )
        endif
        silent CMakeClean
        if !has('win32')
            call assert_false( filereadable( 'cmake-build-Release/app/test_app'      ), 'app should be built'      )
            call assert_false( filereadable( 'cmake-build-Release/lib/libtest_lib.a' ), 'test_lib should be built' )
        else
            call assert_false( filereadable( 'cmake-build-Release/app/Debug/test_app.exe' ), 'app should be built'      )
            call assert_false( filereadable( 'cmake-build-Release/lib/Debug/test_lib.lib' ), 'test_lib should be built' )
        endif
    endif
endfunction

function! Test_CMake_targets_Build_only_library_with_arguments()
    " enable tests for windows with last cmake
    if !has( 'win32' ) || utils#cmake#verNewerOrEq( [ 3, 14 ] )
        call assert_false( isdirectory( 'cmake-build-Release' ), 'Build directory should not exist' )
        silent CMake
        call assert_true( filereadable( 'cmake-build-Release/CMakeCache.txt' ), 'CMakeCache.txt should be generated' )
        silent CMakeSelectTarget test_lib
        silent CMakeBuild
        if !has('win32')
            call assert_false( filereadable( 'cmake-build-Release/app/test_app'      ), 'app should be built'      )
            call assert_true ( filereadable( 'cmake-build-Release/lib/libtest_lib.a' ), 'test_lib should be built' )
        else
            call assert_false( filereadable( 'cmake-build-Release/app/Debug/test_app.exe' ), 'app should be built'      )
            call assert_true ( filereadable( 'cmake-build-Release/lib/Debug/test_lib.lib' ), 'test_lib should be built' )
        endif
    endif
endfunction

function! Test_CMake_targets_CMakeBuild_for_test_library()
    " enable tests for windows with last cmake
    if !has( 'win32' ) || utils#cmake#verNewerOrEq( [ 3, 14 ] )
        " Check that make command works with changed build command
        call assert_false( isdirectory( 'cmake-build-Release' ), 'Build directory should not exist' )
        silent CMake
        call assert_true( filereadable( 'cmake-build-Release/CMakeCache.txt' ), 'CMakeCache.txt should be generated' )
        silent CMakeBuild test_lib
        if !has('win32')
            call assert_false( filereadable( 'cmake-build-Release/app/test_app'      ), 'app should be built'      )
            call assert_true ( filereadable( 'cmake-build-Release/lib/libtest_lib.a' ), 'test_lib should be built' )
        else
            call assert_false( filereadable( 'cmake-build-Release/app/Debug/test_app.exe' ), 'app should be built'      )
            call assert_true ( filereadable( 'cmake-build-Release/lib/Debug/test_lib.lib' ), 'test_lib should be built' )
        endif
    endif
endfunction

function! Test_CMake_targets_Check_all_targets()
    " enable tests for windows with last cmake
    if !has( 'win32' ) || utils#cmake#verNewerOrEq( [ 3, 14 ] )
        silent CMake
        call assert_true( filereadable( 'cmake-build-Release/CMakeCache.txt' ), 'CMakeCache.txt should be generated' )
        let l:targets = cmake4vim#GetAllTargets()
        call assert_true( len( l:targets ) >= 5, printf( 'Number of targets: %s, content: %s', len( l:targets ), join( l:targets ) ) )
    endif
endfunction

function! Test_CMake_targets_Get_cmake_targets()
    " enable tests for windows with last cmake
    if !has( 'win32' ) || utils#cmake#verNewerOrEq( [ 3, 14 ] )
        call assert_false( isdirectory( 'cmake-build-Release' ), 'Build directory should not exist' )
        silent CMake
        call assert_true( filereadable( 'cmake-build-Release/CMakeCache.txt' ), 'CMakeCache.txt should be generated' )
        let l:targets = split( cmake4vim#CompleteTarget( 0,0,0 ), '\n' )
        call assert_true( len( l:targets ) >= 5, printf( 'Number of targets: %s, content: %s', len( l:targets ), join( l:targets ) ) )
    endif
endfunction

function! Test_CMake_targets_Get_custom_build_types()
    let g:cmake_variants = { 'custom-build' : { 'cmake_build_type' : 'Debug', 'cmake_usr_args' : { 'CUSTOM_OP':'ON' } } }
    let l:result = split( cmake4vim#CompleteBuildType( 0,0,0 ), '\n' )
    call assert_equal( 5, len( l:result ) ) 
endfunction

function! Test_CMake_targets_Override_default_build_types()
    let g:cmake_variants = { 'Debug' : { 'cmake_build_type' : 'Debug', 'cmake_usr_args' : { 'CUSTOM_OP' : 'ON' } } }
    let l:result = split( cmake4vim#CompleteBuildType( 0,0,0 ), '\n' )
    call assert_equal( 4, len( l:result ) ) 
    call assert_equal( { 'CUSTOM_OP':'ON' }, g:cmake_variants[ 'Debug' ][ 'cmake_usr_args' ] ) 
endfunction

function! Test_CMake_targets_Store_cmake_usr_args_with_default_build_types()
    let g:cmake_usr_args = '-DCUSTOM_OP=ON'
    let l:result = split( cmake4vim#CompleteBuildType( 0,0,0 ), '\n' )
    call assert_equal( 4, len( l:result ) ) 
    for build_type in keys( g:cmake_variants )
        call assert_equal( { 'CUSTOM_OP':'ON' }, g:cmake_variants[ build_type ][ 'cmake_usr_args' ] ) 
    endfor
endfunction

function! Test_CMake_targets_Update_cmake_usr_args_for_default_build_types()
    let g:cmake_usr_args = '-DCUSTOM_OP=ON'
    let l:gen_command = utils#cmake#getCMakeGenerationCommand()
    call assert_true( l:gen_command =~# '-DCUSTOM_OP=ON', l:gen_command )

    let g:cmake_usr_args = '-DCUSTOM_TEST=OFF'
    let l:gen_command = utils#cmake#getCMakeGenerationCommand()
    call assert_false( l:gen_command =~# '-DCUSTOM_OP=ON'    )
    call assert_true ( l:gen_command =~# '-DCUSTOM_TEST=OFF' )
endfunction

function! Test_CMake_targets_Only_default_build_types_have_default_values()
    let g:cmake_variants = { 'custom-build' : { 'cmake_build_type' : 'Debug', 'cmake_usr_args' : { 'CUSTOM_OP' : 'ON' } } }
    let g:cmake_usr_args = '-DDEFAULT_OP=ON'
    let l:result = split( cmake4vim#CompleteBuildType( 0,0,0 ), '\n' )
    call assert_equal( 5, len( l:result ) ) 
    for build_type in filter( keys( g:cmake_variants ), "v:val !=# 'custom-build'" )
        call assert_equal( { 'DEFAULT_OP':'ON' }, g:cmake_variants[ build_type ][ 'cmake_usr_args' ] ) 
    endfor
    call assert_equal( { 'CUSTOM_OP':'ON' }, g:cmake_variants[ 'custom-build' ][ 'cmake_usr_args' ] ) 
endfunction

function! Test_CMake_targets_Get_default_build_types()
    let l:result = split( cmake4vim#CompleteBuildType( 0,0,0 ), '\n' )
    call assert_equal( 4, len( l:result ) ) 
endfunction

function! Test_CMake_targets_Check_all_targets_for_empty_project()
    " enable tests for windows with last cmake
    if !has( 'win32' ) || utils#cmake#verNewerOrEq( [ 3, 14 ] )
        call assert_false( filereadable( 'cmake-build-Release/CMakeCache.txt' ), 'CMakeCache.txt should not be generated' )
        let l:targets = cmake4vim#GetAllTargets()
        call assert_true( empty( l:targets ), 'CMake targets should be empty but it is: ' . join( l:targets ) )
    endif
endfunction

function! Test_CMake_targets_Check_clean_target_for_empty_project()
    " enable tests for windows with last cmake
    if !has( 'win32' ) || utils#cmake#verNewerOrEq( [ 3, 14 ] )
        call assert_false( filereadable( 'cmake-build-Release/CMakeCache.txt' ), 'CMakeCache.txt should not be generated' )
        let l:default = utils#gen#common#getCleanTarget()
        call assert_true( empty( l:default ) ) 
    endif
endfunction

function! Test_CMake_targets_Check_default_target_for_empty_project()
    " enable tests for windows with last cmake
    if !has( 'win32' ) || utils#cmake#verNewerOrEq( [ 3, 14 ] )
        call assert_false( filereadable( 'cmake-build-Release/CMakeCache.txt' ), 'CMakeCache.txt should not be generated' )
        let l:default = utils#gen#common#getDefaultTarget()
        call assert_false( empty( default ) )
    endif
endfunction

function! Test_CMake_targets_Select_all_targets_for_empty_project()
    " enable tests for windows with last cmake
    if !has( 'win32' ) || utils#cmake#verNewerOrEq( [ 3, 14 ] )
        call assert_false( filereadable( 'cmake-build-Release/CMakeCache.txt' ), 'CMakeCache.txt should not be generated' )
        let l:cmd = cmake4vim#SelectTarget( 'all' )
        call assert_true ( empty( cmd ) )
        call assert_false( filereadable( 'cmake-build-Release/CMakeCache.txt' ), 'CMakeCache.txt should not be generated' )
    endif
endfunction

function! Test_CMake_targets_Call_CMakeBuild_for_empty_project()
    " enable tests for windows with last cmake
    if !has( 'win32' ) || utils#cmake#verNewerOrEq( [ 3, 14 ] )
        call assert_false( filereadable( 'cmake-build-Release/CMakeCache.txt' ), 'CMakeCache.txt should not be generated' )
        silent CMakeBuild
        call assert_false( filereadable( 'cmake-build-Release/CMakeCache.txt' ), 'CMakeCache.txt should not be generated' )
    endif
endfunction

function! Test_CMake_targets_Check_CMakeClean_for_empty_project()
    " enable tests for windows with last cmake
    if !has( 'win32' ) || utils#cmake#verNewerOrEq( [ 3, 14 ] )
        call assert_false( isdirectory( 'cmake-build-Release' ), 'Build directory should not exist' )
        CMakeClean
        call assert_false( isdirectory( 'cmake-build-Release' ), 'Build directory should not exist' )
    endif
endfunction
