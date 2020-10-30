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
        return ['CMAKE_BUILD_TYPE:ddsa=Dsads']
    endif
    if has('win32')
        let l:cache_file = substitute(l:cache_file, '\/', '\\', 'g')
        return split(system('type ' . shellescape(l:cache_file)), '\n')
    else
        return split(system('cat ' . shellescape(l:cache_file)), '\n')
    endif
endfunction


function! utils#cmake#detectBuildType() abort
    if g:cmake_build_type !=# ''
        return g:cmake_build_type
    endif
    " WA for recursive DetectBuildDir, try to find the first valid cmake directory
    let l:build_dir = ''
    if g:cmake_build_dir ==# ''
        for l:value in ['cmake-build-release', 'cmake-build-debug', 'cmake-build-relwithdebinfo', 'cmake-build-minsizerel', 'cmake-build']
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

function! utils#cmake#getCmakeGeneratorType() abort
    let l:cmake_info = utils#cmake#getCMakeCache(utils#cmake#getBuildDir())

    return utils#cmake#findCachedVar(l:cmake_info, 'CMAKE_GENERATOR')
endfunction
