
function! SetUp()
    let g:cmake_executable = 'cmake'
    let s:cur_version = utils#cmake#getVersion()
    call assert_equal( 3, len( s:cur_version ) )
endfunction

function! Test_CMake_version_Check_older_cmake_version()
    call assert_equal( 1, utils#cmake#verNewerOrEq( map( s:cur_version, 'v:val - 1' ) ) )
endfunction

function! Test_CMake_version_Check_older_major_minor_cmake_version_1()
    call assert_equal( 1, utils#cmake#verNewerOrEq([s:cur_version[0] - 1, s:cur_version[1] - 1]) ) 
endfunction

function! Test_CMake_version_Check_older_major_minor_cmake_version_2()
    call assert_equal( 1, utils#cmake#verNewerOrEq([s:cur_version[0] - 1, s:cur_version[1] + 1]) ) 
endfunction

function! Test_CMake_version_Check_older_major_minor_cmake_version_3()
    call assert_equal( 1, utils#cmake#verNewerOrEq([s:cur_version[0] - 1, s:cur_version[1]]) ) 
endfunction

function! Test_CMake_version_Check_older_major_minor_cmake_version_3()
    call assert_equal( 1, utils#cmake#verNewerOrEq([s:cur_version[0], s:cur_version[1] - 1]) ) 
endfunction

function! Test_CMake_version_Check_older_major_minor_path_cmake_version_1()
    call assert_equal( 1, utils#cmake#verNewerOrEq([s:cur_version[0] - 1, s:cur_version[1], s:cur_version[2] - 1]) ) 
endfunction

function! Test_CMake_version_Check_older_major_minor_path_cmake_version_2()
    call assert_equal( 1, utils#cmake#verNewerOrEq([s:cur_version[0] - 1, s:cur_version[1], s:cur_version[2] + 1]) ) 
endfunction

function! Test_CMake_version_Check_older_major_minor_path_cmake_version_3()
    call assert_equal( 1, utils#cmake#verNewerOrEq([s:cur_version[0] - 1, s:cur_version[1] - 1, s:cur_version[2] + 1]) ) 
endfunction

function! Test_CMake_version_Check_older_major_minor_path_cmake_version_4()
    call assert_equal( 1, utils#cmake#verNewerOrEq([s:cur_version[0] - 1, s:cur_version[1] + 1, s:cur_version[2] + 1]) ) 
endfunction

function! Test_CMake_version_Check_older_major_minor_path_cmake_version_5()
    call assert_equal( 1, utils#cmake#verNewerOrEq([s:cur_version[0], s:cur_version[1], s:cur_version[2] - 1]) ) 
endfunction

function! Test_CMake_version_Check_newer_cmake_version()
    call assert_equal( 0, utils#cmake#verNewerOrEq([s:cur_version[0] + 1, s:cur_version[1] + 1, s:cur_version[2] + 1]) ) 
endfunction

function! Test_CMake_version_Check_newer_major_minor_cmake_version_1()
    call assert_equal( 0, utils#cmake#verNewerOrEq([s:cur_version[0] + 1, s:cur_version[1] - 1]) ) 
endfunction

function! Test_CMake_version_Check_newer_major_minor_cmake_version_2()
    call assert_equal( 0, utils#cmake#verNewerOrEq([s:cur_version[0] + 1, s:cur_version[1] + 1]) ) 
endfunction

function! Test_CMake_version_Check_newer_major_minor_cmake_version_3()
    call assert_equal( 0, utils#cmake#verNewerOrEq([s:cur_version[0] + 1, s:cur_version[1]]) ) 
endfunction

function! Test_CMake_version_Check_newer_major_minor_cmake_version_3()
    call assert_equal( 0, utils#cmake#verNewerOrEq([s:cur_version[0], s:cur_version[1] + 1]) ) 
endfunction

function! Test_CMake_version_Check_newer_major_minor_path_cmake_version_1()
    call assert_equal( 0, utils#cmake#verNewerOrEq([s:cur_version[0] + 1, s:cur_version[1], s:cur_version[2] - 1]) ) 
endfunction

function! Test_CMake_version_Check_newer_major_minor_path_cmake_version_2()
    call assert_equal( 0, utils#cmake#verNewerOrEq([s:cur_version[0] + 1, s:cur_version[1], s:cur_version[2] + 1]) ) 
endfunction

function! Test_CMake_version_Check_newer_major_minor_path_cmake_version_3()
    call assert_equal( 0, utils#cmake#verNewerOrEq([s:cur_version[0] + 1, s:cur_version[1] - 1, s:cur_version[2] + 1]) ) 
endfunction

function! Test_CMake_version_Check_newer_major_minor_path_cmake_version_4()
    call assert_equal( 0, utils#cmake#verNewerOrEq([s:cur_version[0] + 1, s:cur_version[1] + 1, s:cur_version[2] + 1]) ) 
endfunction

function! Test_CMake_version_Check_newer_major_minor_path_cmake_version_5()
    call assert_equal( 0, utils#cmake#verNewerOrEq([s:cur_version[0], s:cur_version[1], s:cur_version[2] + 1]) ) 
endfunction

function! Test_CMake_version_Check_equal_cmake_version()
    call assert_equal( 1, utils#cmake#verNewerOrEq([s:cur_version[0], s:cur_version[1], s:cur_version[2]]) ) 
endfunction
