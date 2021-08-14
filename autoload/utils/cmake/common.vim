" autoload/utils/cmake/common.vim - contains wrapper to work CMake cache
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

if !exists('s:cmake_cache_info')
    let s:cmake_cache_info = {}
endif

" Functions reset current CMake cache from the memory
" and cmake-kits cache
" basically all caching is cleared
function! utils#cmake#common#resetCache() abort
    let s:cmake_cache_info = {}
    call utils#cmake#resetCache()
endfunction

" Prepare requests to CMake
function! utils#cmake#common#makeRequests(build_dir) abort
    call utils#cmake#fileapi#prepare(a:build_dir)
endfunction

" Collect information from CMake reply and cache
function! utils#cmake#common#collectCMakeInfo(build_dir) abort
    let s:cmake_cache_info = utils#cmake#fileapi#parseReply(a:build_dir)
    if empty(s:cmake_cache_info)
        let s:cmake_cache_info = utils#cmake#cache#collectInfo(a:build_dir)
    endif
endfunction

" Returns the dictionary with CMake information
function! utils#cmake#common#getInfo(...) abort
    let l:build_dir = ''
    if exists('a:1') && a:1 !=# ''
        let l:build_dir = a:1
    endif
    if l:build_dir !=# '' && empty(s:cmake_cache_info)
        call utils#cmake#common#collectCMakeInfo(l:build_dir)
    endif
    if !executable('cmake') || empty(s:cmake_cache_info)
        return {}
    endif

    return s:cmake_cache_info
endfunction
