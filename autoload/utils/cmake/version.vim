" autoload/utils/cmake/version.vim - CMake version handling utilities
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

if !exists('s:cmake_version_cache')
    let s:cmake_version_cache = []
endif

" Gets CMake version
" Returns array [major, minor, patch]
function! utils#cmake#version#getVersion() abort
    if !empty(s:cmake_version_cache)
        return s:cmake_version_cache
    endif
    
    let l:version_out = system(g:cmake_executable . ' --version')
    let l:version_str = matchstr(l:version_out, '\v\d+.\d+.\d+')
    let l:version_exp = split(l:version_str, '\.')
    let l:version = []
    for l:val in l:version_exp
        let l:version += [str2nr(l:val)]
    endfor
    let s:cmake_version_cache = l:version
    return l:version
endfunction

" Return 1 if cmake version is newer or equal to passed value
function! utils#cmake#version#verNewerOrEq(cmake_version) abort
    let l:cmake_ver = utils#cmake#version#getVersion()
    let l:cmake_version = a:cmake_version
    if len(l:cmake_version) == 0
        return 1
    endif
    if len(l:cmake_ver) == 0
        return 0
    endif
    
    " Compare versions
    for i in range(max([len(l:cmake_version), len(l:cmake_ver)]))
        if i >= len(l:cmake_ver) 
            return 0
        endif
        if i >= len(l:cmake_version)
            return 1
        endif
        if l:cmake_ver[i] > l:cmake_version[i]
            return 1
        elseif l:cmake_ver[i] < l:cmake_version[i]
            return 0
        endif
    endfor
    return 1
endfunction