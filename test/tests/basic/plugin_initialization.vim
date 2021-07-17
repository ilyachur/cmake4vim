function! SetUp()
    call RemoveCMakeDirs()
    let g:cmake_build_executor = 'system'
endfunction

function! TearDown()
    call RemoveCMakeDirs()
endfunction

function! Test_Plugin_Initialization_Check_default_initialization()
    call assert_false( isdirectory( 'cmake-build-Release' ) )
    CMake
    call assert_true( filereadable('cmake-build-Release/CMakeCache.txt'), 'File is not readable' )
    let l:cmake_info = utils#cmake#common#getInfo()
    echom l:cmake_info
    let l:cmake_gen  = cmake_info['cmake']['generator']
    " Disable this check for windows with cmake 2.8
    if !has('win32') || utils#cmake#verNewerOrEq([3, 0])
        if cmake_gen =~# utils#gen#vs#getGeneratorName()
            call assert_equal( g:cmake_build_target, 'ALL_BUILD' )
        else
            call assert_equal( g:cmake_build_target, 'all' )
        endif
    endif
    call assert_equal( g:cmake_compile_commands_link, '' )
    call assert_equal( g:cmake_compile_commands, 0 )
    call assert_equal( g:cmake_usr_args, '' )
    call assert_equal( g:cmake_cxx_compiler, '' )
    call assert_equal( g:cmake_c_compiler, '' )
    call assert_equal( g:cmake_build_type, '' )
    call assert_equal( g:cmake_install_prefix, '' )
    call assert_equal( g:cmake_project_generator, '' )
    call assert_equal( g:make_arguments, '' )
    call assert_equal( g:cmake_executable, 'cmake' )

    call assert_equal( g:cmake_build_dir, '' )
    call assert_equal( g:cmake_src_dir, '' )
    call assert_equal( g:cmake_build_dir_prefix, 'cmake-build-' )
    call assert_equal( g:cmake_change_build_command, 1 )
    call assert_equal( g:cmake_reload_after_save, 0 )
    call assert_equal( sort( keys(g:cmake_variants) ), ['Debug', 'MinSizeRel', 'RelWithDebInfo', 'Release'] )
    call assert_equal( g:cmake_ctest_args, '' )
    call assert_equal( g:cmake_kits, {} )
    call assert_equal( g:cmake_toolchain_file, '' )
    call assert_equal( g:cmake_selected_kit, '' )
endfunction

function Test_Plugin_Initialization_CheckCmake_usr_argsConversionFromStringToDictionary()
    let l:cmake_usr_args = '-DCOMPILER_PATH=this/is/a/compiler/path
                          \ -DMOUNT_PATH=./mount/disk15
                          \ -DMY_CUSTOM_OP=ON'
    let l:split_args = utils#cmake#splitUserArgs( l:cmake_usr_args )
    call assert_equal( sort( items( l:split_args ) ),
                \ [ [ 'COMPILER_PATH', 'this/is/a/compiler/path' ],
                   \[ 'MOUNT_PATH', './mount/disk15' ],
                   \[ 'MY_CUSTOM_OP', 'ON' ] ] )
endfunction

function Test_Plugin_Initialization_Check_cmake_usr_args_conversion_crom_dictionary_to_string()
    let l:cmake_usr_args = { 'MY_CUSTOM_OP'  : 'ON',
                            \'COMPILER_PATH' : 'this/is/a/compiler/path',
                            \'MOUNT_PATH'    : './mount/disk15' }
    let l:joined_args = utils#cmake#joinUserArgs( l:cmake_usr_args )
    call assert_true( l:joined_args =~# '-DMY_CUSTOM_OP=ON' )
    call assert_true( l:joined_args =~# '-DMOUNT_PATH=./mount/disk15' )
    call assert_true( l:joined_args =~# '-DCOMPILER_PATH=this/is/a/compiler/path' )
endfunction

function Test_Plugin_Initialization_check_cmake_usr_args_conversion_from_string_to_dictionary_to_string()
    let l:cmake_usr_args = '-DMY_CUSTOM_OP=ON
                          \ -DCOMPILER_PATH=this/is/a/compiler/path
                          \ -DMOUNT_PATH=./mount/disk15'
    let l:new_cmake_usr_args = utils#cmake#joinUserArgs( utils#cmake#splitUserArgs( l:cmake_usr_args ) )
    call assert_true( l:new_cmake_usr_args =~# '-DMY_CUSTOM_OP=ON' )
    call assert_true( l:new_cmake_usr_args =~# '-DMOUNT_PATH=./mount/disk15' )
    call assert_true( l:new_cmake_usr_args =~# '-DCOMPILER_PATH=this/is/a/compiler/path' )
endfunction
