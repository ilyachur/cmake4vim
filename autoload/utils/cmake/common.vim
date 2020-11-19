" autoload/utils/cmake/common.vim - contains wrapper to work CMake cache
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

if !exists('s:cmake_cache_info')
    let s:cmake_cache_info = {}
endif

function! utils#cmake#common#makeRequests(build_dir) abort
    call utils#cmake#fileapi#prepare(a:build_dir)
endfunction

function! utils#cmake#common#collectResults(build_dir) abort
    let s:cmake_cache_info = utils#cmake#fileapi#parceReply(a:build_dir)
    if empty(s:cmake_cache_info)
        let s:cmake_cache_info = utils#cmake#cache#collectInfo(a:build_dir)
    endif
endfunction

" Returns the dictionary with CMake Cache
function! utils#cmake#common#getInfo(...) abort
    let l:build_dir = ''
    if exists('a:1') && a:1 !=# ''
        let l:build_dir = a:1
    endif
    if l:build_dir !=# '' && empty(s:cmake_cache_info)
        call utils#cmake#common#collectResults(l:build_dir)
    endif
    if !executable('cmake') || empty(s:cmake_cache_info)
        return {}
    endif

    return s:cmake_cache_info
endfunction
