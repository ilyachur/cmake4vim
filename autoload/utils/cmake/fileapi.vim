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
    silent call writefile([a:content], a:filename)
endfunction

function! s:createQuery() abort
    let l:query = {}
    let l:requests = []
    let l:requests += [{'kind': 'codemodel', 'version': 2}]
    let l:requests += [{'kind': 'cache', 'version': 2}]
    let l:requests += [{'kind': 'cmakeFiles', 'version': 1}]
    " The toolchains object exposes the per-language compilers without
    " scraping the cache. It is available since CMake 3.20.
    if utils#cmake#version#verNewerOrEq([3, 20])
        let l:requests += [{'kind': 'toolchains', 'version': 1}]
    endif
    let l:query['requests'] = l:requests
    let l:query['client'] = {}
    return l:query
endfunction

function! s:parseTarget(path) abort
    let l:targetInfo = json_decode(join(readfile(a:path), ''))
    let l:pathes = []
    if !has_key(l:targetInfo, 'artifacts')
        return {'type': l:targetInfo['type']}
    endif
    for l:artifact in l:targetInfo['artifacts']
        call add(l:pathes, l:artifact['path'])
    endfor
    return {'type': l:targetInfo['type'], 'pathes': l:pathes}
endfunction

function! s:parseCodemodel(reply_folder, jsonFile, hash) abort
    let l:codemodel = json_decode(join(readfile(printf('%s/%s', a:reply_folder, a:jsonFile)), ''))
    let l:common = a:hash
    let l:targetsInfo = {}
    for l:configuration in l:codemodel['configurations']
        let l:targetsInfo[l:configuration['name']] = {}
        for l:target in l:configuration['targets']
            let l:targetsInfo[l:configuration['name']][l:target['name']] = s:parseTarget(printf('%s/%s', a:reply_folder, l:target['jsonFile']))
        endfor
    endfor
    let l:common['cmake']['build_dir'] = l:codemodel['paths']['build']
    let l:common['targets'] = l:targetsInfo
    return l:common
endfunction

function! s:parseToolchains(path, hash) abort
    let l:toolchains = json_decode(join(readfile(a:path), ''))
    let l:common = a:hash
    let l:compilers = {}
    for l:toolchain in get(l:toolchains, 'toolchains', [])
        let l:compiler = get(l:toolchain, 'compiler', {})
        if has_key(l:toolchain, 'language') && has_key(l:compiler, 'path')
            let l:compilers[l:toolchain['language']] = l:compiler['path']
        endif
    endfor
    if !empty(l:compilers)
        let l:common['toolchains'] = l:compilers
    endif
    return l:common
endfunction

function! s:parseCMakeFiles(path, hash) abort
    let l:cmakeFiles = json_decode(join(readfile(a:path), ''))
    return a:hash
endfunction

function! s:parseCache(path, hash) abort
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
            let l:common = s:parseCodemodel(a:reply_folder, l:resp['jsonFile'], l:common)
        endif
        if l:resp['kind'] ==# 'cache'
            let l:common = s:parseCache(a:reply_folder . '/' . l:resp['jsonFile'], l:common)
        endif
        if l:resp['kind'] ==# 'cmakeFiles'
            let l:common = s:parseCMakeFiles(a:reply_folder . '/' . l:resp['jsonFile'], l:common)
        endif
        if l:resp['kind'] ==# 'toolchains'
            let l:common = s:parseToolchains(a:reply_folder . '/' . l:resp['jsonFile'], l:common)
        endif
    endfor
    return l:common
endfunction
" }}} Private functions "

function! utils#cmake#fileapi#prepare(build_dir) abort
    " The CMake file API is only available since CMake 3.14. On older versions
    " the plugin falls back to parsing the cache and generator target lists.
    if !(utils#cmake#version#verNewerOrEq([3, 14]))
        return
    endif
    let l:reply_folder = s:getReplyFolder(a:build_dir)
    if !empty(l:reply_folder)
        call utils#fs#removeDirectory(l:reply_folder)
    endif
    let l:client_folder = s:getClientFolder(a:build_dir)
    call s:createFile(l:client_folder . '/query.json', json_encode(s:createQuery()))
endfunction

function! utils#cmake#fileapi#parseReply(build_dir) abort
    let l:reply_folder = s:getReplyFolder(a:build_dir)
    if empty(l:reply_folder)
        return {}
    endif
    let l:index_file = globpath(l:reply_folder, 'index*')
    if empty(l:index_file)
        return {}
    endif
    " A malformed or partial reply (e.g. an error-*.json produced by a failed
    " generation) must not throw and abort the calling command.
    try
        return s:parseAll(l:reply_folder, l:index_file)
    catch
        return {}
    endtry
endfunction
