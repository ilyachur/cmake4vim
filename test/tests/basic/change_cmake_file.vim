function! SetUp()
    silent call RemoveCMakeDirs()

    silent call ResetPluginOptions()
endfunction

function! Test_Change_CMake_script_Changes_in_cmake_file_should_not_call_project_generation()
    call assert_false( isdirectory('cmake-build-Release'), 'Build directory shouldn''t exist' )
    edit CMakeLists.txt
    write
    call assert_false( isdirectory('cmake-build-Release'), 'Build directory shouldn''t exist' )
endfunction

function! Test_Change_CMake_script_Changes_in_cmake_file_should_call_project_generation()
    call assert_false( isdirectory('cmake-build-Release'), 'Build directory shouldn''t exist' )
    let g:cmake_reload_after_save = 1
    edit CMakeLists.txt
    write
    call assert_true( filereadable('cmake-build-Release/CMakeCache.txt'), 'CMakeCache.txt should be generated' )
endfunction
