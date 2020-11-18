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
function! utils#cmake#common#getInfo() abort
    if !executable('cmake') || empty(s:cmake_cache_info)
        return {}
    endif

    let s:cmake_cache_info['cmake']['build_command'] = utils#cmake#getBuildCommand(g:cmake_build_target)
    return s:cmake_cache_info
endfunction
