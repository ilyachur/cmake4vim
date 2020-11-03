" autoload/utils/cmake.vim - contains cmake helpers
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

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

function! utils#cmake#findCachedVar(data, variable) abort
    for l:value in a:data
        let l:split_res = split(l:value, '=')
        if len(l:split_res) > 1 && stridx(l:split_res[0], a:variable . ':') != -1
            return l:split_res[1]
        endif
    endfor
    return ''
endfunction

function! utils#cmake#getCMakeCache(dir) abort
    let l:cache_file = a:dir . '/CMakeCache.txt'
    if !filereadable(l:cache_file)
        return []
    endif
    if has('win32')
        let l:cache_file = substitute(l:cache_file, '\/', '\\', 'g')
        return split(system('type ' . shellescape(l:cache_file)), '\n')
    else
        return split(system('cat ' . shellescape(l:cache_file)), '\n')
    endif
endfunction

function! utils#cmake#getCmakeGeneratorType() abort
    let l:build_dir = utils#cmake#getBuildDir()
    let l:cmake_info = utils#cmake#getCMakeCache(l:build_dir)

    return utils#cmake#findCachedVar(l:cmake_info, 'CMAKE_GENERATOR')
endfunction

function! utils#cmake#setBuildTarget(target) abort
    " Use all target if a:target and g:cmake_target are empty
    let l:cmake_target = a:target
    if a:target ==# ''
        let l:cmake_gen = utils#cmake#getCmakeGeneratorType()
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
        let l:src = shellescape(l:build_dir) . '/compile_commands.json'
        let l:dst = shellescape(g:cmake_compile_commands_link) . '/compile_commands.json'
        silent call utils#fs#createLink(l:src, l:dst)
    endif

    let l:cmake_gen = utils#cmake#getCmakeGeneratorType()
    if stridx(l:cmake_gen, utils#gen#vs#getGeneratorName()) != -1
        return utils#gen#vs#getBuildCommand(l:build_dir, a:target, g:make_arguments)
    elseif stridx(l:cmake_gen, utils#gen#ninja#getGeneratorName()) != -1
        return utils#gen#ninja#getBuildCommand(l:build_dir, a:target, g:make_arguments)
    else
        return utils#gen#make#getBuildCommand(l:build_dir, a:target, g:make_arguments)
    endif
endfunction

function! utils#cmake#getCMakeGenerationCommand() abort
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

    let l:cmake_cmd = 'cmake '.join(l:cmake_args).' '.join(a:000).' -H'.getcwd().' -B'.l:build_dir
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
        let l:cmake_vars = utils#cmake#getCMakeCache(l:build_dir)
        let l:res = utils#cmake#findCachedVar(l:cmake_vars, 'CMAKE_BUILD_TYPE')
        if l:res !=# ''
            return l:res
        endif
    endif

    return 'Release'
endfunction

function! utils#cmake#detectBuildDir() abort
    if g:cmake_build_dir !=# ''
        return g:cmake_build_dir
    endif
    let l:build_type = utils#cmake#detectBuildType()
    if l:build_type ==# ''
        return 'cmake-build'
    endif
    return g:cmake_build_dir_prefix . l:build_type
endfunction

function! utils#cmake#getBuildDir() abort
    return finddir(utils#cmake#detectBuildDir(), getcwd().';.')
endfunction

