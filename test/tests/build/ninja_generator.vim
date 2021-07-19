function! SetUp()
    silent call RemoveCMakeDirs()

    silent call ResetPluginOptions()
" TODO: test of deprecated function ( mark2185 2021-07-30 )
    let g:cmake_project_generator = 'Ninja'

    " to shorten test time
    let g:cmake_build_type = 'Debug'
endfunction

if !has( 'win32' ) " Skip for Windows

function! Test_Ninja_Find_Ninja_generator()
        call assert_true( executable( 'ninja' ), 'Ninja is not found!' )
endfunction

function! Test_Ninja_Check_CMake_generator_name()
        call assert_false( isdirectory( 'cmake-build-Debug' ), 'Build directory should not exist' )
        silent CMake
        let l:cmake_info = utils#cmake#common#getInfo()
        let l:gen_name   = cmake_info[ 'cmake' ][ 'generator' ]
        call assert_equal( 'Ninja', l:gen_name )
endfunction

function! Test_Ninja_Generate_cmake_project_with_Ninja_generator()
        call assert_false( isdirectory( 'cmake-build-Debug' ), 'Build directory should not exist' )
        silent CMake
        call assert_true( filereadable( 'cmake-build-Debug/CMakeCache.txt' ), 'CMakeCache.txt should be generated' )
        call assert_true( filereadable( 'cmake-build-Debug/build.ninja'    ), 'build.ninja should be generated'    )
endfunction

function! Test_Ninja_Build_cmake_project_with_Ninja_generator()
        call assert_false( isdirectory( 'cmake-build-Debug' ), 'Build directory should not exist' )
        silent CMake
        call assert_true( filereadable( 'cmake-build-Debug/CMakeCache.txt' ), 'CMakeCache.txt should be generated' )
        call assert_true( filereadable( 'cmake-build-Debug/build.ninja'    ), 'build.ninja should be generated'    )
        silent CMakeBuild
        call assert_true( filereadable( 'cmake-build-Debug/app/test_app'      ), 'app should be built'      )
        call assert_true( filereadable( 'cmake-build-Debug/lib/libtest_lib.a' ), 'test_lib should be built' )
endfunction

function! Test_Ninja_Build_cmake_project_with_Ninja_generator()
        call assert_false( isdirectory( 'cmake-build-Debug' ), 'Build directory should not exist' )
        silent CMake
        call assert_true( filereadable( 'cmake-build-Debug/CMakeCache.txt' ), 'CMakeCache.txt should be generated' )
        call assert_true( filereadable( 'cmake-build-Debug/build.ninja'    ), 'build.ninja should be generated'    )
        silent CMakeBuild
        call assert_true( filereadable( 'cmake-build-Debug/app/test_app'      ), 'app should be built'      )
        call assert_true( filereadable( 'cmake-build-Debug/lib/libtest_lib.a' ), 'test_lib should be built' )
        silent CMakeClean
        call assert_false( filereadable( 'cmake-build-Debug/app/test_app'      ), 'app should not be built'      )
        call assert_false( filereadable( 'cmake-build-Debug/lib/libtest_lib.a' ), 'test_lib should not be built' )
endfunction

function! Test_Ninja_Build_cmake_project_with_Ninja_generator_and_tests()
        call assert_false( isdirectory( 'cmake-build-Debug' ), 'Build directory should not exist' )
        silent CMake -DENABLE_TESTS=ON
        call assert_true( filereadable( 'cmake-build-Debug/CMakeCache.txt' ), 'CMakeCache.txt should be generated' )
        call assert_true( filereadable( 'cmake-build-Debug/build.ninja'    ), 'build.ninja should be generated'    )
        silent CMakeBuild
        call assert_true( filereadable( 'cmake-build-Debug/app/test_app'      ), 'app should be built'        )
        call assert_true( filereadable( 'cmake-build-Debug/tests/unit_tests'  ), 'unit_tests should be built' )
        call assert_true( filereadable( 'cmake-build-Debug/lib/libtest_lib.a' ), 'test_lib should be built'   )
endfunction

function! Test_Ninja_Build_cmake_project_with_C_param()
        let g:make_arguments = '-C .'
        call assert_false( isdirectory( 'cmake-build-Debug' ), 'Build directory should not exist' )
        silent CMake
        call assert_true( filereadable( 'cmake-build-Debug/CMakeCache.txt' ), 'CMakeCache.txt should be generated' )
        call assert_true( filereadable( 'cmake-build-Debug/build.ninja'    ), 'build.ninja should be generated'    )
        silent CMakeBuild
        call assert_true( filereadable( 'cmake-build-Debug/app/test_app'      ), 'app should be built'      )
        call assert_true( filereadable( 'cmake-build-Debug/lib/libtest_lib.a' ), 'test_lib should be built' )
endfunction

function! Test_Ninja_Build_cmake_project_with_generator_from_usr_args()
        let g:cmake_project_generator = ''
        let g:cmake_usr_args = '-GNinja'
        call assert_false( isdirectory( 'cmake-build-Debug' ), 'Build directory should not exist' )
        silent CMake
        call assert_true( filereadable( 'cmake-build-Debug/CMakeCache.txt' ), 'CMakeCache.txt should be generated' )
        call assert_true( filereadable( 'cmake-build-Debug/build.ninja'    ), 'build.ninja should be generated'    )
        silent CMakeBuild
        call assert_true( filereadable( 'cmake-build-Debug/app/test_app'      ), 'app should be built'      )
        call assert_true( filereadable( 'cmake-build-Debug/lib/libtest_lib.a' ), 'test_lib should be built' )
endfunction

function! Test_Ninja_Get_all_Ninja_targets()
        silent CMake
        call assert_true( filereadable( 'cmake-build-Debug/CMakeCache.txt' ), 'CMakeCache.txt should be generated' )
        let l:targets = cmake4vim#GetAllTargets()
        call assert_true( len( l:targets ) > 10 )
endfunction

function! Test_Ninja_Update_cmake_executable_option()
        let l:gen_command   = utils#cmake#getCMakeGenerationCommand()
        let l:build_command = utils#cmake#getBuildCommand( 'build_dir', 'all_target' )
        call assert_true ( l:gen_command   =~# 'cmake'      , l:gen_command   )
        call assert_true ( l:build_command =~# 'cmake'      , l:build_command )
        call assert_false( l:gen_command   =~# 'custom_make', l:gen_command   )
        call assert_false( l:build_command =~# 'custom_make', l:build_command )

        let g:cmake_executable = 'custom_make'
        let l:gen_command      = utils#cmake#getCMakeGenerationCommand()
        let l:build_command    = utils#cmake#getBuildCommand( 'build_dir', 'all_target' )
        call assert_true( l:gen_command   =~# 'custom_make', l:gen_command   )
        call assert_true( l:build_command =~# 'custom_make', l:build_command )
endfunction

endif
