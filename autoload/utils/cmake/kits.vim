" autoload/utils/cmake/kits.vim - contains helpers for working with cmake kits

" cache filename and mtime to skip reading
" if it hasn't changed since last time
let s:config_cache = {}

function! s:removeFromCache(config_path) abort
    if has_key(s:config_cache, a:config_path)
        call remove(s:config_cache, a:config_path)
    endif
endfunction

function! s:isCached(config_path) abort
    return has_key(s:config_cache, a:config_path)
       \ && get(s:config_cache[a:config_path], 'mtime', -1) == getftime(a:config_path)
endfunction

function! s:addToCache(config_path) abort
    try
        let l:result = json_decode(join(readfile(a:config_path)))
        if !empty(l:result)
            let s:config_cache[a:config_path] = {
                    \ 'kits' : l:result,
                    \ 'mtime': getftime(a:config_path)
                    \}
        endif
    catch
        call utils#common#Warning(printf('Invalid config "%s": %s"', a:config_path, v:exception))
        let l:result = {}
    endtry
    return l:result
endfunction

function! s:validateConfigPath(config_path) abort
    if !empty(findfile(a:config_path))
        return v:true
    endif

    call s:removeFromCache(a:config_path)
    return v:false
endfunction

function! utils#cmake#kits#resetCMakeKitsCache() abort
    let s:config_cache = {}
endfunction

function! utils#cmake#kits#getCMakeKits() abort
    for config_path in ['.cmake-kits.json', fnameescape(g:cmake_kits_global_path)]
        if !s:validateConfigPath( config_path )
            continue
        endif

        if s:isCached(config_path)
            return s:config_cache[config_path]['kits']
        else
            let l:cached_kits = s:addToCache(config_path)
            if !empty(l:cached_kits)
                return l:cached_kits
            endif
        endif
    endfor

    return get(g:, 'cmake_kits', {})
endfunction
