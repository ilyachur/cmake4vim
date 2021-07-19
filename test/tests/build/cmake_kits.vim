function! SetUp()
    silent call RemoveCMakeDirs()
    silent call Remove('custom-build-name')

    silent call ResetPluginOptions()
    let g:cmake_kits = {
                \ 'First':
                \ {
                \    'toolchain_file' : 'android.toolchain.cmake',
                \    'cmake_usr_args': { 'ANDROID_STL': 'c++_static', 'ANDROID_TOOLCHAIN': 'clang', 'ANDROID_ABI': 'arm64-v8a' },
                \    'compilers': { 'C': 'clang', 'CXX': 'clang++' },
                \    'generator': 'Ninja',
                \    'environment_variables' : { 'MY_CUSTOM_VARIABLE' : '15', 'MY_OTHER_CUSTOM_VARIABLE' : 'YES' }
                \},
                \ 'Second' : { 'compilers' : { 'C': '', 'CXX': '' }, 'cmake_usr_args' : { 'Flag' : 'ON' } } }
    let g:cmake_build_path_pattern = []
    let g:cmake_executable = 'cmake'
endfunction

function! TearDown()
    silent call Remove('custom-build-name')
endfunction

function! Test_CMake_kits_Check_CMakeKit_autocomplete()
    let l:kits = split( cmake4vim#CompleteKit( 0,0,0 ) )
    call assert_equal( 2, len( l:kits ) )
    call assert_equal( [ 'First', 'Second' ], l:kits ) 
    let g:cmake_kits[ 'Third' ] = { 'toolchain_file' : 'random_third.txt' }
    let l:kits = split( cmake4vim#CompleteKit( 0,0,0 ) )
    call assert_equal( 3, len( l:kits ) )
    call assert_equal( [ 'First', 'Second', 'Third' ], l:kits )
endfunction

function! Test_CMake_kits_Check_toolchain_file()
    let g:cmake_kits = {}
    let g:cmake_toolchain_file = 'android.toolchain.cmake'

    let l:generation_command = utils#cmake#getCMakeGenerationCommand()
    call assert_true( l:generation_command =~# '-DCMAKE_TOOLCHAIN_FILE=android.toolchain.cmake', l:generation_command )
endfunction

function! Test_CMake_kits_Check_CMakeKit_toolchain_file()
    silent CMakeSelectKit First
    let l:generation_command = utils#cmake#getCMakeGenerationCommand()
    call assert_true( l:generation_command =~# '-DCMAKE_TOOLCHAIN_FILE=android.toolchain.cmake' )
endfunction

function! Test_CMake_kits_Check_toolchain_file_precedence_over_compilers()
    silent CMakeSelectKit First
    let l:generation_command = utils#cmake#getCMakeGenerationCommand()
    call assert_true ( generation_command =~# '-DCMAKE_TOOLCHAIN_FILE=android.toolchain.cmake' )
    call assert_false( generation_command =~# '-DCMAKE_C_COMPILER'                             )
    call assert_false( generation_command =~# '-DCMAKE_CXX_COMPILER'                           )
endfunction

function! Test_CMake_kits_Check_CMakeKit_compilers_setting()
    silent call remove( g:cmake_kits[ 'First' ], 'toolchain_file' )
    silent CMakeSelectKit First
    let l:generation_command = utils#cmake#getCMakeGenerationCommand()
    call assert_true( l:generation_command =~# '-DCMAKE_C_COMPILER=clang'     )
    call assert_true( l:generation_command =~# '-DCMAKE_CXX_COMPILER=clang++' )
endfunction

function! Test_CMake_kits_Check_CMakeKit_generator_setting()
    if !has( 'win32' )
        silent call remove( g:cmake_kits[ 'First' ], 'toolchain_file' )
        silent CMakeSelectKit First
        let l:generation_command = utils#cmake#getCMakeGenerationCommand()
        call assert_true( l:generation_command =~# '-G "Ninja"', 'CMake should use Ninja generator: ' . l:generation_command )

        let g:cmake_kits[ 'First' ][ 'generator' ] = ''
        silent CMakeSelectKit First
        let l:generation_command = utils#cmake#getCMakeGenerationCommand()
        call assert_false( l:generation_command =~# '-G', 'CMake should not use Ninja generator: ' . l:generation_command )

    endif
endfunction

function! Test_CMake_kits_Check_CMakeKit_cmake_usr_args_setting()
    silent CMakeSelectKit First
    let l:generation_command = utils#cmake#getCMakeGenerationCommand()
    call assert_true( l:generation_command =~# '-DANDROID_STL=c++_static'  )
    call assert_true( l:generation_command =~# '-DANDROID_TOOLCHAIN=clang' )
    call assert_true( l:generation_command =~# '-DANDROID_ABI=arm64-v8a'   )
endfunction

function! Test_CMake_kits_Check_CMakeKit_environment_variables()
    silent CMakeSelectKit First
    silent CMakeSelectBuildType Release
    call assert_equal( '15' , $MY_CUSTOM_VARIABLE       )
    call assert_equal( 'YES', $MY_OTHER_CUSTOM_VARIABLE )
    unlet $MY_CUSTOM_VARIABLE
    unlet $MY_OTHER_CUSTOM_VARIABLE
endfunction

function! Test_CMake_kits_Check_CMakeKit_change_kit_unset_environment_variables()
    silent CMakeSelectKit First
    call assert_equal( '15' , $MY_CUSTOM_VARIABLE       )
    call assert_equal( 'YES', $MY_OTHER_CUSTOM_VARIABLE )
    silent CMakeSelectKit Second
    call assert_false( exists( '$MY_CUSTOM_VARIABLE' ) )
    call assert_false( exists( '$MY_OTHER_CUSTOM_VARIABLE' ) )
endfunction

function! Test_CMake_kits_Check_CMakeKit_default()
    silent CMakeSelectKit First
    silent CMakeSelectBuildType Release
    call assert_equal( '15' , $MY_CUSTOM_VARIABLE       )
    call assert_equal( 'YES', $MY_OTHER_CUSTOM_VARIABLE )
    unlet $MY_CUSTOM_VARIABLE
    unlet $MY_OTHER_CUSTOM_VARIABLE
endfunction

function! Test_CMake_kits_Check_CMakeKit_selected_kit_without_CMakeSelectKit()
    let g:cmake_selected_kit = 'Second'
    let l:generation_command = utils#cmake#getCMakeGenerationCommand()
    call assert_true( l:generation_command =~# '-DFlag=ON' )
endfunction

function! Test_CMake_kits_Check_build_path_pattern()
    let g:cmake_build_path_pattern = [ './custom-build-name/%s/%s', 'g:cmake_selected_kit, g:cmake_build_type' ]
    call assert_false( isdirectory('custom-build-name/First/Release'), 'Build directory should not exist' )
    silent CMakeSelectKit First
    silent CMake
    call assert_equal( 'First', g:cmake_selected_kit )
    silent CMakeSelectBuildType Release
    call assert_true( isdirectory( 'custom-build-name/First/Release' ), 'Build directory should exist' )
endfunction

function! Test_CMake_kits_Check_build_path_pattern_precedence_over_build_dir_prefix()
    let g:cmake_build_path_pattern = [ './custom-build-name/%s/%s', 'g:cmake_selected_kit, g:cmake_build_type' ]
    let g:cmake_build_dir_prefix = 'my-custom-prefix'
    call assert_false( isdirectory( 'custom-build-name/First/Release' ), 'Build directory should not exist' )
    call assert_false( isdirectory( 'my-custom-prefixRelease'         ), 'Build directory should not exist' )
    silent CMakeSelectKit First
    silent CMakeSelectBuildType Release
    call assert_true ( isdirectory( 'custom-build-name/First/Release' ), 'Build directory should exist'     )
    call assert_false( isdirectory( 'my-custom-prefixRelease'         ), 'Build directory should not exist' )
endfunction

function! Test_CMake_kits_Call_joinUserArgs_with_a_string()
    let l:usr_args = '-DOPTION=YES -DSETTING=YES'
    call assert_equal( l:usr_args, utils#cmake#joinUserArgs( l:usr_args ) )
endfunction

function! Test_CMake_kits_Call_splitUserArgs_with_a_dict()
    let l:usr_args = { 'OPTION' : 'YES', 'SETTING' : 'YES' }
    let l:new_args = utils#cmake#splitUserArgs( l:usr_args )
    call assert_true ( has_key( l:new_args, 'OPTION'  ) )
    call assert_true ( has_key( l:new_args, 'SETTING' ) )
    call assert_equal( l:new_args[ 'OPTION'  ], 'YES' )
    call assert_equal( l:new_args[ 'SETTING' ], 'YES' )
endfunction

function! Test_CMake_kits_Select_a_non_existing_kit()
    call cmake4vim#SelectKit( 'nonexistant_key' )
    call assert_true( empty( g:cmake_selected_kit ) )
endfunction
