" autoload/utils/cmake/cache.vim - contains helpers for work with cmake cache
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

" Private functions {{{ "
function! s:findCacheVar(data, variable) abort
    for l:value in a:data
        let l:split_res = split(l:value, '=')
        if len(l:split_res) > 1 && stridx(l:split_res[0], a:variable . ':') != -1
            return l:split_res[1]
        endif
    endfor
endfunction

function! s:getCache(dir) abort
    let l:cache_file = a:dir . '/CMakeCache.txt'
    if !filereadable(l:cache_file)
        return []
    endif
    if has('win32')
        return split(system('type ' . utils#fs#fnameescape(l:cache_file)), '\n')
    else
        return split(system('cat ' . utils#fs#fnameescape(l:cache_file)), '\n')
    endif
endfunction
" }}} Private functions "

function! utils#cmake#cache#collectInfo(build_dir) abort
    let l:cmake_cache = s:getCache(a:build_dir)
    if empty(l:cmake_cache)
        return {}
    endif

    let l:common = {}

    let l:common['cmake'] = {
                \ 'version': join(utils#cmake#getVersion(), '.'),
                \ 'generator': s:findCacheVar(l:cmake_cache, 'CMAKE_GENERATOR'),
                \ 'build_type': s:findCacheVar(l:cmake_cache, 'CMAKE_BUILD_TYPE'),
                \ 'project_name': s:findCacheVar(l:cmake_cache, 'CMAKE_PROJECT_NAME'),
                \ 'build_dir': a:build_dir,
                \ }
    return l:common
endfunction
