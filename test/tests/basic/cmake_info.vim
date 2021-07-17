function! SetUp()
    silent call ResetPluginOptions()

    silent call RemoveCMakeDirs()
endfunction

function! TearDown()
    silent call RemoveCMakeDirs()
endfunction

function! Test_CMake_info_Get_CMake_info()
    call assert_false( isdirectory('cmake-build-Release'), 'Build directory shouldn''t exist' )
    silent CMake
    call assert_true( filereadable('cmake-build-Release/CMakeCache.txt'), 'CMakeCache.txt should be generated' )
    let l:result = utils#window#PrepareInfo(utils#cmake#common#getInfo())
    call assert_equal( 10, len(result), 'Test project info should contain 10 lines' )
endfunction

 function! Test_CMake_info_Get_CMake_info_for_empty_project()
    call assert_false( isdirectory('cmake-build-Release'), 'Build directory shouldn''t exist' )
    silent CMakeInfo
    call assert_equal( 'CMake project was not found!', getline(1) )
    " wipe the buffer with the message
    bwipeout!
 endfunction

function! Test_CMake_info_Close_CMakeInfo_Window()
    call assert_equal( 1, winnr( '$' ), 'There should be exactly one window in the start' )

    silent CMakeInfo
    call assert_equal( 2, winnr( '$' ), 'There should be two windows after calling CMakeInfo' )

    call utils#window#CloseCMakeInfoWindow()
    call assert_equal( 1, winnr( '$' ), 'There should be exactly one window after closing cmake info' )
endfunction

function! Test_CMake_info_Get_cmake_info_2_times()
    call assert_false( isdirectory('cmake-build-Release'), 'Build directory shouldn''t exist' )
    silent CMakeInfo
    silent CMakeInfo
    %bwipeout!
endfunction
