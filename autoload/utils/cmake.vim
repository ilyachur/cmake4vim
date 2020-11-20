" autoload/utils/cmake.vim - contains cmake helpers
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

" Private functions {{{ "
function! s:detectCMakeBuildType() abort
    if g:cmake_build_type !=# ''
        return g:cmake_build_type
    endif
    let l:cmake_info = utils#cmake#common#getInfo()
    if !empty(l:cmake_info)
        return l:cmake_info['cmake']['build_type']
    endif
    " WA for recursive DetectBuildDir, try to find the first valid cmake directory
    let l:build_dir = ''
    if g:cmake_build_dir ==# ''
        for l:value in ['cmake-build-Release', 'cmake-build-Debug', 'cmake-build-RelWithDebInfo', 'cmake-build-MinSizeRel', 'cmake-build']
            let l:build_dir = finddir(l:value, getcwd().';.')
            if l:build_dir !=# ''
                break
            endif
        endfor
    else
        let l:build_dir = utils#cmake#findBuildDir()
    endif

    if l:build_dir !=# ''
        let l:cmake_info = utils#cmake#common#getInfo(l:build_dir)
        if !empty(l:cmake_info) && l:cmake_info['cmake']['build_type'] !=# ''
            return l:cmake_info['cmake']['build_type']
        endif
    endif

    return 'Release'
endfunction

function! s:detectCMakeBuildDir() abort
    if g:cmake_build_dir !=# ''
        return g:cmake_build_dir
    endif
    let l:cmake_info = utils#cmake#common#getInfo()
    if !empty(l:cmake_info) && l:cmake_info['cmake']['build_dir'] !=# ''
        return l:cmake_info['cmake']['build_dir']
    endif
    let l:build_type = s:detectCMakeBuildType()
    return g:cmake_build_dir_prefix . l:build_type
endfunction
" }}} Private functions "

" Gets CMake version
" Returns array [major, minor, patch]
function! utils#cmake#getVersion() abort
    let l:version_out = system('cmake --version')
    let l:version_str = matchstr(l:version_out, '\v\d+.\d+.\d+')
    let l:version_str = split(l:version_str, '\.')
    let l:version = []
    for l:val in l:version_str
        let l:version += [str2nr(l:val)]
    endfor
    return l:version
endfunction

" Return 1 if cmake version is newer or equal to passed value
function! utils#cmake#verNewerOrEq(cmake_version) abort
    let l:i = 0
    let l:cmake_ver = utils#cmake#getVersion()
    while l:i < len(a:cmake_version) && l:i < len(l:cmake_ver)
        if a:cmake_version[l:i] > l:cmake_ver[l:i]
            return 0
        elseif a:cmake_version[l:i] < l:cmake_ver[l:i]
            return 1
        endif
        let l:i += 1
    endwhile
    return 1
endfunction

" Set CMake build target
function! utils#cmake#setBuildTarget(build_dir, target) abort
    " Use all target if a:target and g:cmake_target are empty
    let l:cmake_target = a:target
    if a:target ==# ''
        let l:cmake_target = utils#gen#common#getDefaultTarget()
    endif
    let g:cmake_build_target = l:cmake_target

    return l:cmake_target
endfunction

" Generates CMake build command
function! utils#cmake#getBuildCommand(build_dir, target) abort
    if g:cmake_compile_commands_link !=# ''
        let l:src = a:build_dir . '/compile_commands.json'
        let l:dst = g:cmake_compile_commands_link . '/compile_commands.json'
        call utils#fs#createLink(l:src, l:dst)
    endif

    return utils#gen#common#getBuildCommand(a:build_dir, a:target, g:make_arguments)
endfunction

" Generates the command line for CMake generator
" Additional cmake arguments can be passed as arguments of this function
function! utils#cmake#getCMakeGenerationCommand(...) abort
    let l:build_dir = utils#cmake#findBuildDir()
    let l:cmake_args = []

    " Set build type
    let l:cmake_args += ['-DCMAKE_BUILD_TYPE=' . s:detectCMakeBuildType()]
    " Specify generator
    if g:cmake_project_generator !=# ''
        let l:cmake_args += ['-G "' . g:cmake_project_generator . '"']
    endif
    if g:cmake_install_prefix !=# ''
        let l:cmake_args += ['-DCMAKE_INSTALL_PREFIX=' . g:cmake_install_prefix]
    endif
    " Set c and c++ compilers
    if g:cmake_c_compiler !=# ''
        let l:cmake_args += ['-DCMAKE_C_COMPILER=' . g:cmake_c_compiler]
    endif
    if g:cmake_cxx_compiler !=# ''
        let l:cmake_args += ['-DCMAKE_CXX_COMPILER=' . g:cmake_cxx_compiler]
    endif
    " Add command to export compilation database
    if g:cmake_compile_commands
        let l:cmake_args += ['-DCMAKE_EXPORT_COMPILE_COMMANDS=ON']
    endif
    " Add user arguments
    if g:cmake_usr_args !=# ''
        let l:cmake_args += [g:cmake_usr_args]
    endif

    " Generates the command line
    let l:cmake_cmd = 'cmake ' . join(l:cmake_args) . ' ' . join(a:000)
    " CMake -B option was introduced in the 3.13 version
    if utils#cmake#verNewerOrEq([3, 13])
        let l:cmake_cmd .= ' -B ' . utils#fs#fnameescape(l:build_dir)
    else
        let l:cmake_cmd .= ' ' . utils#fs#fnameescape(getcwd())
    endif

    return l:cmake_cmd
endfunction

" Check that build directory exists
function! utils#cmake#findBuildDir() abort
    let l:build_dir = finddir(s:detectCMakeBuildDir(), getcwd().';.')
    if l:build_dir !=# ''
        let l:build_dir = fnamemodify(l:build_dir, ':p:h')
    endif
    return l:build_dir
endfunction

" Returs the path to build directory if directory was found and returns empty string in other case.
" Use build directory from the cmake cache or try to find it at the current folder
" Creates directory if it doesn't exist
function! utils#cmake#getBuildDir() abort
    let l:build_dir = s:detectCMakeBuildDir()
    let l:build_dir = utils#fs#makeDir(l:build_dir)
    let l:build_dir = fnamemodify(l:build_dir, ':p:h')
    return l:build_dir
endfunction
