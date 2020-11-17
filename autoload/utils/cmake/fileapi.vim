" autoload/utils/cmake/fileapi.vim - cmake from 3.14 version supports file-api
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

function! s:getClientFolder(build_dir) abort
    let l:client_folder = a:build_dir . '/.cmake/api/v1/query/client-cmake4vim'
    return utils#fs#makeDir(l:client_folder)
endfunction

function! s:getReplyFolder(build_dir) abort
    let l:reply_folder = a:build_dir . '/.cmake/api/v1/reply'
    if !isdirectory(l:reply_folder)
        return ''
    endif
    return utils#fs#fnameescape(l:reply_folder)
endfunction

function! s:createFile(filename, content) abort
    new
    setlocal buftype=nofile bufhidden=hide noswapfile nobuflisted
    put=a:content
    execute 'w! ' a:filename
    q
endfunction

function! s:createQuery() abort
    let l:query = {}
    let l:requests = []
    let l:requests += [ { 'kind': 'codemodel', 'version': 2 } ]
    let l:requests += [ { 'kind': 'cache', 'version': 2 } ]
    let l:requests += [ { 'kind': 'cmakeFiles', 'version': 1 } ]
    let l:query['requests'] = l:requests
    let l:query['client'] = {}
    return l:query
endfunction

function! s:parseAll(index) abort
    let l:index = json_decode(join(readfile(a:index), ''))
    return l:index
endfunction

function! utils#cmake#fileapi#prepare(build_dir) abort
    let l:cmake_ver = utils#cmake#getVersion()
    if !(l:cmake_ver[0] > 3 || (l:cmake_ver[0] == 3 && l:cmake_ver[1] >= 14))
        return l:cmake_ver
    endif
    let l:client_folder = s:getClientFolder(a:build_dir)
    call s:createFile(l:client_folder . '/query.json', json_encode(s:createQuery()))
endfunction

function! utils#cmake#fileapi#parceReply(build_dir) abort
    let l:reply_folder = s:getReplyFolder(a:build_dir)
    if l:reply_folder ==# ''
        return {}
    endif
    let l:index_file = globpath(l:reply_folder, 'index*')
    return s:parseAll(l:index_file)
endfunction
