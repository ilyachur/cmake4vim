function! SetUp()
    silent call Remove("compile_commands.json")
    silent call RemoveCMakeDirs()
    silent call Remove('build_test')
    silent call Remove('cmake-vador-Release')
    silent call Remove('custom-folder')
    silent call Remove('custom-folder/')

    silent call ResetPluginOptions()
endfunction

function! TearDown()
    silent call Remove("compile_commands.json")
    silent call RemoveCMakeDirs()
    silent call Remove('build_test')
    silent call Remove('cmake-vador-Release')
    silent call Remove('custom-folder')
    silent call Remove('custom-folder/')
endfunction

function! Test_CMake_generate_Generate_cmake_project_with_default_settings()
    call assert_false( isdirectory("cmake-build-Release"), "Build directory shouldn't exist" )
    silent CMake
    call assert_true( filereadable("cmake-build-Release/CMakeCache.txt"), "CMakeCache.txt should be generated" )
endfunction

function! Test_CMake_generate_Remove_cmake_build_forder()
    call assert_false( isdirectory("cmake-build-Release"), "Build directory shouldn't exist" )
    silent CMake
    call assert_true( isdirectory("cmake-build-Release"), "Build directory should be created" )
    silent CMakeReset
    call assert_false( isdirectory("cmake-build-Release"), "Build directory shouldn't exist" )
endfunction

function! Test_CMake_generate_Generate_Debug_cmake_project()
    call assert_false( isdirectory("cmake-build-Debug"), "Build directory shouldn't exist" )
    let g:cmake_build_type = 'Debug'
    silent CMake
    call assert_true( filereadable("cmake-build-Debug/CMakeCache.txt"), "CMakeCache.txt should be exist" )
endfunction

function! Test_CMake_generate_Validate_create_link_method()
    call assert_false( isdirectory("cmake-build-Release"), "Build directory shouldn't exist" )
    silent CMakeResetAndReload
    call assert_true( filereadable("cmake-build-Release/CMakeCache.txt"), "CMakeCache.txt should be generated" )
    call assert_false( filereadable("compile_commands.json"), "compile_commands.json shouldn't be generated" )
    silent call utils#fs#createLink("cmake-build-Release/CMakeCache.txt", "compile_commands.json")
    call assert_true( filereadable("compile_commands.json"), "compile_commands.json shouldn be exist" )
endfunction

function! Test_CMake_generate_Generate_cmake_project_with_compilation_database_generation()
    if !has('win32') " Skip for Windows
        call assert_false( isdirectory("cmake-build-Release"), "Build directory shouldn't exist" )
        let g:cmake_compile_commands = 1
        silent CMakeResetAndReload
        call assert_true( filereadable("cmake-build-Release/CMakeCache.txt"), "CMakeCache.txt should be generated" )
        call assert_true( filereadable("cmake-build-Release/compile_commands.json"), "compile_commands.json should be generated" )
    endif
endfunction

function! Test_CMake_generate_Generate_cmake_project_with_link_to_compilation_database()
    if !has('win32') " Skip for Windows
        call assert_false( isdirectory("cmake-build-Release"), "Build directory shouldn't exist" )
        let g:cmake_compile_commands      = 1
        let g:cmake_compile_commands_link = '.'
        silent CMake
        call assert_true( filereadable("cmake-build-Release/CMakeCache.txt"), "CMakeCache.txt should be generated" )
        call assert_true( filereadable("cmake-build-Release/compile_commands.json"), "compile_commands.json should be generated" )
        call assert_true( filereadable("compile_commands.json"), "Link to compile_commands.json should be generated" )
    endif
endfunction

function! Test_CMake_generate_Generate_cmake_project_in_custom_build_folder()
    call assert_false( isdirectory("build_test"), "Build directory shouldn't exist" )
    let g:cmake_build_dir = 'build_test'
    silent CMakeResetAndReload
    call assert_true( filereadable("build_test/CMakeCache.txt"), "CMakeCache.txt should be generated" )
endfunction

function! Test_CMake_generate_Generate_cmake_project_with_custom_generator()
    call assert_false( isdirectory("cmake-build-Release"), "Build directory shouldn't exist" )
    let g:cmake_project_generator = 'Unix Makefiles'
    silent CMake
    silent call utils#gen#common#getDefaultTarget()
    call assert_true( filereadable("cmake-build-Release/CMakeCache.txt"), "CMakeCache.txt should be exist" )
endfunction

function! Test_CMake_generate_Generate_cmake_project_with_custom_install_prefix()
    call assert_false( isdirectory("cmake-build-Release"), "Build directory shouldn't exist" )
    let g:cmake_install_prefix = '.'
    silent CMake
    call assert_true( filereadable("cmake-build-Release/CMakeCache.txt"), "CMakeCache.txt should be exist" )
endfunction

function! Test_CMake_generate_Generate_cmake_project_with_custom_compilers()
    call assert_false( isdirectory("cmake-build-Release"), "Build directory shouldn't exist" )
    let g:cmake_c_compiler   = 'gcc'
    let g:cmake_cxx_compiler = 'g++'
    silent CMake
    call assert_true( filereadable("cmake-build-Release/CMakeCache.txt"), "CMakeCache.txt should be exist" )
endfunction

function! Test_CMake_generate_Generate_cmake_project_in_prefix_build_folder()
    call assert_false( isdirectory("cmake-vador-Release"), "Build directory shouldn't exist" )
    let g:cmake_build_dir_prefix = 'cmake-vador-'
    silent CMakeResetAndReload
    call assert_true( filereadable("cmake-vador-Release/CMakeCache.txt"), "CMakeCache.txt should be generated" )
    silent call Remove("cmake-vador-Release")
endfunction

function! Test_CMake_generate_Generate_cmake_project_and_change_BuildType()
    call assert_false( isdirectory("cmake-build-Release"), "Build directory shouldn't exist" )
    call assert_false( isdirectory("cmake-build-Debug"), "Build directory shouldn't exist" )
    let g:cmake_build_dir_prefix = 'cmake-vador-'
    silent CMakeResetAndReload
    call assert_true( filereadable("cmake-vador-Release/CMakeCache.txt"), "CMakeCache.txt should be generated" )
    call assert_false( isdirectory("cmake-build-Debug"), "Build directory shouldn't exist" )
    silent CMakeSelectBuildType Debug
    call assert_true( filereadable("cmake-vador-Debug/CMakeCache.txt"), "CMakeCache.txt should be generated" )
    silent call Remove("cmake-vador-Release")
    silent call Remove("cmake-vador-Debug")
endfunction

function! Test_CMake_generate_Generate_RelWithDebInfo_cmake_project()
    call assert_false( isdirectory("cmake-build-RelWithDebInfo"), "Build directory shouldn't exist" )
    let g:cmake_build_type='RelWithDebInfo'
    silent CMake
    call assert_true( filereadable("cmake-build-RelWithDebInfo/CMakeCache.txt"), "CMakeCache.txt should be exist" )
endfunction

function! Test_CMake_generate_Generate_MinSizeRel_cmake_project()
    call assert_false( isdirectory("cmake-build-MinSizeRel"), "Build directory shouldn't exist" )
    let g:cmake_build_type='MinSizeRel'
    silent CMake
    call assert_true( filereadable("cmake-build-MinSizeRel/CMakeCache.txt"), "CMakeCache.txt should be exist" )
endfunction

function! Test_CMake_generate_Check_findBuild_dir_with_initialized_cache()
    call assert_false( isdirectory("cmake-build-Release"), "Build directory shouldn't exist" )
    silent CMake
    call assert_notequal( utils#cmake#findBuildDir(), '' )
    call assert_true( filereadable("cmake-build-Release/CMakeCache.txt"), "CMakeCache.txt should be exist" )
endfunction

function! Test_CMake_generate_Emulate_uninitialized_project_with_existed_build_folder()
    call assert_false( isdirectory("cmake-build-Release"), "Build directory shouldn't exist" )
    silent CMake
    silent call utils#cmake#common#resetCache()

    let g:cmake_compile_commands_link=""
    let g:cmake_compile_commands=0
    let g:cmake_usr_args=""
    let g:cmake_cxx_compiler=""
    let g:cmake_c_compiler=""
    let g:cmake_build_type=""
    let g:cmake_install_prefix=""
    let g:cmake_project_generator=""
    let g:make_arguments=""
    let g:cmake_build_target=""
    let g:cmake_build_dir=""
    let g:cmake_change_build_command=1
    let g:cmake_reload_after_save=0
    let g:cmake_build_dir_prefix="cmake-build-"

    call assert_true( filereadable("cmake-build-Release/CMakeCache.txt"), "CMakeCache.txt should be exist" )
    silent CMake
    call assert_true( filereadable("cmake-build-Release/CMakeCache.txt"), "CMakeCache.txt should be exist" )
endfunction

function! Test_CMake_generate_Call_prepare_file_API_after_project_generation()
    call assert_false( isdirectory("cmake-build-Release"), "Build directory shouldn't exist" )
    silent CMake
    call assert_true( isdirectory("cmake-build-Release"), "Build directory should exist" )
    if isdirectory("cmake-build-Release/.cmake/api/v1/reply")
        silent call utils#cmake#fileapi#prepare('cmake-build-Release')
        call assert_false( isdirectory("cmake-build-Release/.cmake/api/v1/reply"), "Reply directory shouldn't exist" )
    endif
endfunction

function! Test_CMake_generate_Generate_cmake_project_in_custom_source_folder()
    if utils#cmake#verNewerOrEq([3, 13])
        " TODO: move this to another file because of cd-ing and old cmake
        call assert_false( isdirectory("cmake-build-Release"), "Build directory shouldn't exist" )
        let g:cmake_src_dir='test proj'
        cd ..
        call assert_true( isdirectory(g:cmake_src_dir), "Source directory should exist" )
        silent CMake
        call assert_true( filereadable("cmake-build-Release/CMakeCache.txt"), "CMakeCache.txt should be generated" )
        silent call Remove("compile_commands.json")
        silent call RemoveCMakeDirs()
        cd test\ proj
    endif
endfunction

function! Test_CMake_generate_Update_cmake_executable_option()
    let l:gen_command   = utils#cmake#getCMakeGenerationCommand()
    let l:build_command = utils#cmake#getBuildCommand('build_dir', 'all_target')
    call assert_true ( l:gen_command   =~# 'cmake', l:gen_command   )
    call assert_true ( l:build_command =~# 'cmake', l:build_command )
    call assert_false( l:gen_command   =~# 'custom_make', l:gen_command   )
    call assert_false( l:build_command =~# 'custom_make', l:build_command )

    let g:cmake_executable = 'custom_make'
    let l:gen_command   = utils#cmake#getCMakeGenerationCommand()
    let l:build_command = utils#cmake#getBuildCommand('build_dir', 'all_target')
    call assert_true( l:gen_command   =~# 'custom_make', l:gen_command   )
    call assert_true( l:build_command =~# 'custom_make', l:build_command )
endfunction

function! Test_CMake_generate_Create_incorrect_folder()
    call assert_false( filereadable('custom-folder') )
    call writefile( ['{  }'], 'custom-folder' )
    call assert_false( isdirectory("custom-folder"), "Build directory shouldn't exist" )
    call utils#fs#makeDir('custom-folder')
    call assert_false( isdirectory("custom-folder"), "Build directory shouldn't exist" )
endfunction
