" autoload/utils/cmake/fileapi.vim - cmake from 3.14 version supports file-api
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

function! s:getClientFolder(build_dir) abort
    let l:client_folder = a:build_dir . '/.cmake/api/v1/query/client-cmake4vim'
    return utils#fs#makeDir(l:client_folder)
endfunction

function! s:createFile(filename) abort
    silent call system('echo >' . utils#fs#fnameescape(a:filename))
endfunction

function! utils#cmake#fileapi#prepare(build_dir) abort
    let l:cmake_ver = utils#cmake#getVersion()
    if !(l:cmake_ver[0] > 3 || (l:cmake_ver[0] == 3 && l:cmake_ver[1] >= 14))
        return l:cmake_ver
    endif
    let l:client_folder = s:getClientFolder(a:build_dir)
    call s:createFile(l:client_folder . '/cache-v2')
    call s:createFile(l:client_folder . '/codemodel-v2')
    call s:createFile(l:client_folder . '/cmakeFiles-v1')
endfunction
