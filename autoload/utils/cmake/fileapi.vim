" autoload/utils/cmake/fileapi.vim - cmake from 3.14 version supports file-api
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

" Private functions {{{ "
function! s:getClientFolder(build_dir) abort
    let l:client_folder = a:build_dir . '/.cmake/api/v1/query/client-cmake4vim'
    return utils#fs#makeDir(l:client_folder)
endfunction

function! s:getReplyFolder(build_dir) abort
    let l:reply_folder = a:build_dir . '/.cmake/api/v1/reply'
    if !isdirectory(l:reply_folder)
        return ''
    endif
    return l:reply_folder
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

function s:parseCodemodel(path, hash)
    let l:codemodel = json_decode(join(readfile(a:path), ''))
    let l:common = a:hash
    let l:common['cmake']['build_dir'] = l:codemodel['paths']['build']
    return l:common
endfunction

function s:parseCMakeFiles(path, hash)
    let l:cmakeFiles = json_decode(join(readfile(a:path), ''))
    return a:hash
endfunction

function s:parseCache(path, hash)
    let l:cache = json_decode(join(readfile(a:path), ''))['entries']
    let l:common = a:hash
    for l:val in l:cache
        if l:val['name'] ==# 'CMAKE_BUILD_TYPE'
            let l:common['cmake']['build_type'] = l:val['value']
        endif
        if l:val['name'] ==# 'CMAKE_PROJECT_NAME'
            let l:common['cmake']['project_name'] = l:val['value']
        endif
    endfor
    return l:common
endfunction

function! s:parseAll(reply_folder, index) abort
    let l:index = json_decode(join(readfile(a:index), ''))
    let l:common = {}
    let l:common['cmake'] = {
                \ 'version': l:index['cmake']['version']['string'],
                \ 'generator': l:index['cmake']['generator']['name']
                \ }
    let l:responses = l:index['reply']['client-cmake4vim']['query.json']['responses']
    for l:resp in l:responses
        if l:resp['kind'] ==# 'codemodel'
            let l:common = s:parseCodemodel(a:reply_folder . '/' . l:resp['jsonFile'], l:common)
        endif
        if l:resp['kind'] ==# 'cache'
            let l:common = s:parseCache(a:reply_folder . '/' . l:resp['jsonFile'], l:common)
        endif
        if l:resp['kind'] ==# 'cmakeFiles'
            let l:common = s:parseCMakeFiles(a:reply_folder . '/' . l:resp['jsonFile'], l:common)
        endif
    endfor
    return l:common
endfunction
" }}} Private functions "

function! utils#cmake#fileapi#prepare(build_dir) abort
    if !(utils#cmake#versionGreater([3, 13]))
        return
    endif
    let l:reply_folder = s:getReplyFolder(a:build_dir)
    if l:reply_folder !=# ''
        call utils#fs#removeDirectory(l:reply_folder)
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
    let l:common =  s:parseAll(l:reply_folder, l:index_file)

    return l:common
endfunction
