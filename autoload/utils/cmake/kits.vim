" autoload/utils/cmake/kits.vim - contains helpers for working with cmake kits

" cache filename and mtime to skip reading
" if it hasn't changed since last time
let s:config_mtimes = {}

function! utils#cmake#kits#resetCMakeKitsCache() abort
    let s:config_mtimes = {}
endfunction

function! utils#cmake#kits#findCMakeKitsConfig() abort
    for config_path in [ '.cmake-kits.json', fnameescape(g:cmake_kits_global_path) ]
        let l:config = findfile( config_path )
        if !empty( l:config )
            return l:config
        else
            " clear cache if the file was removed
            if has_key( s:config_mtimes, config_path )
                call remove( s:config_mtimes, config_path )
            endif
        endif
    endfor
    return ''
endfunction

function! utils#cmake#kits#readCMakeKits( json_path ) abort
    if empty( a:json_path )
        return {}
    endif

    try
        return json_decode(join(readfile(a:json_path)))
    catch
        call utils#common#Warning( printf( 'Invalid config "%s": %s"', a:json_path, v:exception ) )
    endtry
    return {}
endfunction

function! utils#cmake#kits#getCMakeKits() abort
    let l:config_path = utils#cmake#kits#findCMakeKitsConfig()
    if empty(l:config_path)
        return get( g:, 'cmake_kits', {} )
    endif

    let l:config_mtime = getftime( l:config_path )

    " it is already cached for that timestamp
    if get( s:config_mtimes, l:config_path, -1 ) == l:config_mtime
        return utils#cmake#getLoadedCMakeKits()
    else
        let l:result = utils#cmake#kits#readCMakeKits( l:config_path )
        if !empty( l:result )
            let s:config_mtimes[ l:config_path ] = l:config_mtime
            call utils#cmake#setLoadedCMakeKits( l:result )
            return l:result
        endif
    endif

    return get( g:, 'cmake_kits', {} )
endfunction
