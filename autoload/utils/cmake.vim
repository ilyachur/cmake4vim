" autoload/utils/cmake.vim - contains cmake helpers
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

function! utils#cmake#getVersion() abort
    let l:version_out = system('cmake --version')
    let l:version_str = matchstr(l:version_out, '\v\d+.\d+.\d+')
    return split(l:version_str, '\.')
endfunction

function! utils#cmake#versionGreater(cmake_version) abort
    let l:i = 0
    let l:cmake_ver = utils#cmake#getVersion()
    while l:i < len(a:cmake_version) && l:i < len(l:cmake_ver)
        if a:cmake_version[l:i] > l:cmake_ver[l:i]
            return 0
        endif
        let i += 1
    endwhile
    return 1
endfunction

function! utils#cmake#getCMakeErrorFormat() abort
    return ' %#%f:%l %#(%m),'
                \ .'See also "%f".,'
                \ .'%E%>CMake Error at %f:%l:,'
                \ .'%Z  %m,'
                \ .'%E%>CMake Error at %f:%l (%[%^)]%#):,'
                \ .'%Z  %m,'
                \ .'%W%>Cmake Warning at %f:%l (%[%^)]%#):,'
                \ .'%Z  %m,'
                \ .'%E%>CMake Error: Error in cmake code at,'
                \ .'%C%>%f:%l:,'
                \ .'%Z%m,'
                \ .'%E%>CMake Error in %.%#:,'
                \ .'%C%>  %m,'
                \ .'%C%>,'
                \ .'%C%>    %f:%l (if),'
                \ .'%C%>,'
                \ .'%Z  %m,'
endfunction

function! utils#cmake#setBuildTarget(target) abort
    " Use all target if a:target and g:cmake_target are empty
    let l:cmake_target = a:target
    if a:target ==# ''
        let l:cmake_gen = ''
        let cmake_info = utils#cmake#common#getInfo()
        if !empty(cmake_info)
            let l:cmake_gen = cmake_info['cmake']['generator']
        endif
        if (l:cmake_gen ==# '' && has('win32')) || stridx(l:cmake_gen, utils#gen#vs#getGeneratorName()) != -1
            let l:cmake_target = utils#gen#vs#getDefaultTarget()
        elseif stridx(l:cmake_gen, utils#gen#ninja#getGeneratorName()) != -1
            let l:cmake_target = utils#gen#ninja#getDefaultTarget()
        else
            let l:cmake_target = utils#gen#make#getDefaultTarget()
        endif
    endif
    let g:cmake_build_target = l:cmake_target

    return l:cmake_target
endfunction

function! utils#cmake#getBuildCommand(target) abort
    let l:build_dir = utils#fs#makeDir(utils#cmake#detectBuildDir())
    if g:cmake_compile_commands_link !=# ''
        let l:src = l:build_dir . '/compile_commands.json'
        let l:dst = g:cmake_compile_commands_link . '/compile_commands.json'
        silent call utils#fs#createLink(l:src, l:dst)
    endif

    let l:cmake_gen = ''
    let cmake_info = utils#cmake#common#getInfo()
    if !empty(cmake_info)
        let l:cmake_gen = cmake_info['cmake']['generator']
    endif
    if stridx(l:cmake_gen, utils#gen#vs#getGeneratorName()) != -1
        return utils#gen#vs#getBuildCommand(l:build_dir, a:target, g:make_arguments)
    elseif stridx(l:cmake_gen, utils#gen#ninja#getGeneratorName()) != -1
        return utils#gen#ninja#getBuildCommand(l:build_dir, a:target, g:make_arguments)
    else
        return utils#gen#make#getBuildCommand(l:build_dir, a:target, g:make_arguments)
    endif
endfunction

function! utils#cmake#getCMakeGenerationCommand(...) abort
    let l:build_dir = utils#fs#makeDir(utils#cmake#detectBuildDir())
    let l:cmake_args = []

    let l:cmake_args += ['-DCMAKE_BUILD_TYPE=' . utils#cmake#detectBuildType()]
    if g:cmake_project_generator !=# ''
        let l:cmake_args += ['-G "' . g:cmake_project_generator . '"']
    endif
    if g:cmake_install_prefix !=# ''
        let l:cmake_args += ['-DCMAKE_INSTALL_PREFIX=' . g:cmake_install_prefix]
    endif
    if g:cmake_c_compiler !=# ''
        let l:cmake_args += ['-DCMAKE_C_COMPILER=' . g:cmake_c_compiler]
    endif
    if g:cmake_cxx_compiler !=# ''
        let l:cmake_args += ['-DCMAKE_CXX_COMPILER=' . g:cmake_cxx_compiler]
    endif
    if g:cmake_compile_commands
        let l:cmake_args += ['-DCMAKE_EXPORT_COMPILE_COMMANDS=ON']
    endif
    if g:cmake_usr_args !=# ''
        let l:cmake_args += [g:cmake_usr_args]
    endif

    let l:cmake_cmd = 'cmake ' . join(l:cmake_args) . ' ' . join(a:000)
    if utils#cmake#versionGreater([3, 13])
        let l:cmake_cmd .= ' -B ' . utils#fs#fnameescape(l:build_dir)
    else
        let l:cmake_cmd .= ' ' . utils#fs#fnameescape(getcwd())
    endif
    return l:cmake_cmd
endfunction

function! utils#cmake#detectBuildType() abort
    if g:cmake_build_type !=# ''
        return g:cmake_build_type
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
        let l:build_dir = utils#cmake#getBuildDir()
    endif

    if l:build_dir !=# ''
        let l:cmake_info = utils#cmake#common#getInfo()
        if !empty(l:cmake_info) && l:cmake_info['cmake']['build_type'] !=# ''
            return l:cmake_info['cmake']['build_type']
        endif
    endif

    return 'Release'
endfunction

function! utils#cmake#detectBuildDir() abort
    if g:cmake_build_dir !=# ''
        return g:cmake_build_dir
    endif
    let l:build_type = utils#cmake#detectBuildType()
    return g:cmake_build_dir_prefix . l:build_type
endfunction

function! utils#cmake#getBuildDir() abort
    let l:build_dir = finddir(utils#cmake#detectBuildDir(), getcwd().';.')
    if l:build_dir !=# ''
        let l:build_dir = fnamemodify(l:build_dir, ':p:h')
    endif
    return l:build_dir
endfunction
