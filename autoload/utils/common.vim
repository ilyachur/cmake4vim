" autoload/utils/common.vim - contains cmake helpers
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

" Private functions {{{ "
function! s:add_noglob(cmd) abort
    if has('win32')
        let l:status = ''
    else
        silent! let l:status = system('command -v noglob')
    endif
    if l:status !~# '\w\+'
        let l:noglob = ''
    else
        let l:noglob = 'noglob '
    endif
    return l:noglob . a:cmd
endfunction
" }}} Private functions "

" Executes the command
function! utils#common#executeCommand(cmd, ...) abort
    let l:errFormat = get(a:, 1, '')

    if (g:cmake_build_executor ==# 'dispatch') || (g:cmake_build_executor ==# '' && exists(':Dispatch'))
        " Close quickfix list to discard custom error format
        silent! cclose
        call utils#exec#dispatch#run(s:add_noglob(a:cmd), l:errFormat)
    elseif (g:cmake_build_executor ==# 'job') || (g:cmake_build_executor ==# '' && ((has('job') && has('channel')) || has('nvim')))
        " job#run behaves differently if the qflist is open or closed
        call utils#exec#job#run(a:cmd, l:errFormat)
    else
        " Close quickfix list to discard custom error format
        silent! cclose
        call utils#exec#system#run(s:add_noglob(a:cmd), l:errFormat)
    endif
endfunction

" Prints warning message
function! utils#common#Warning(msg) abort
    echohl WarningMsg |
                \ echomsg a:msg |
                \ echohl None
endfunction
