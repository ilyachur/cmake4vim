" autoload/utils/window.vim - contains function for work with windows
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

let s:cmake_info_win_name = 'CMake4Vim info'
let s:cmake_info_prev_win_id = -1

" Private functions {{{ "
function! s:closeWindowMap() abort
    nnoremap <silent> <buffer> q :call utils#window#CloseCMakeInfoWindow()<CR>
endfunction
" }}} Private functions "

function! utils#window#CloseCMakeInfoWindow() abort
    q
    if s:cmake_info_prev_win_id > -1
        exec s:cmake_info_prev_win_id . 'wincmd w'
    endif
endfunction

function! utils#window#OpenCMakeInfoWindow() abort
    let bufnum = bufnr(s:cmake_info_win_name)
    let bufwinnum = bufwinnr(s:cmake_info_win_name)

    if bufnum != -1 && bufwinnum != -1
        return
    endif
    let wcmd = s:cmake_info_win_name
    let s:cmake_info_prev_win_id = winnr()

    silent execute printf('botright %d %s %s', utils#common#getWindowSize(), g:cmake_build_executor_split_mode, wcmd)
endfunction

function! utils#window#GotoCMakeInfoWindow() abort
    if bufname('%') == s:cmake_info_win_name
        return
    endif

    let l:cmake_info_winnr = bufwinnr(s:cmake_info_win_name)
    if l:cmake_info_winnr == -1
        call utils#window#OpenCMakeInfoWindow()
        let l:cmake_info_winnr = bufwinnr(s:cmake_info_win_name)
    endif
    exec l:cmake_info_winnr . 'wincmd w'
endfunction

function! utils#window#PrepareInfo(cache) abort
    let l:info = []
    if empty(a:cache)
        let l:info = 'CMake project was not found!'
    else
        let l:info += ['CMake:']
        let l:info += ['    version:            ' . a:cache['cmake']['version']]
        let l:info += ['']
        let l:info += ['Project:']
        let l:info += ['    name:               ' . a:cache['cmake']['project_name']]
        let l:info += ['    build type:         ' . a:cache['cmake']['build_type']]
        let l:info += ['    build directory:    ' . a:cache['cmake']['build_dir']]
        let l:info += ['    generator:          ' . a:cache['cmake']['generator']]
        let l:info += ['    generation command: ' . utils#cmake#getCMakeGenerationCommand()]
        let l:info += ['    build command:      ' . utils#cmake#getBuildCommand(a:cache['cmake']['build_dir'], g:cmake_build_target)]
    endif
    return l:info
endfunction

function! utils#window#OpenCMakeInfo() abort
    call utils#window#GotoCMakeInfoWindow()

    call s:closeWindowMap()
    setlocal buftype=nofile
    setlocal complete=.
    setlocal noswapfile
    setlocal nobuflisted
    setlocal nonumber
    setlocal norelativenumber
    setlocal modifiable

    let l:build_dir = utils#cmake#getBuildDir()
    let l:info = utils#window#PrepareInfo(utils#cmake#common#getInfo(l:build_dir))

    %delete
    silent! call append('$', l:info)
    delete
    setlocal nomodifiable
endfunction
