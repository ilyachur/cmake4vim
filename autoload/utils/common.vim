" autoload/utils/common.vim - contains cmake helpers
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

" Private functions {{{ "
function! s:add_noglob(cmd) abort
    if has('win32')
        return a:cmd
    endif

    silent! let l:status = system('command -v noglob')

    if l:status =~# '\w\+'
        return 'noglob ' . a:cmd
    endif

    return a:cmd
endfunction
" }}} Private functions "

" Executes the command
function! utils#common#executeCommand(cmd, ...) abort
    let l:errFormat = get(a:, 1, '')

    let l:cmd = s:add_noglob(a:cmd)
    if (g:cmake_build_executor ==# 'dispatch') || (g:cmake_build_executor ==# '' && exists(':Dispatch'))
        " Close quickfix list to discard custom error format
        silent! cclose
        call utils#exec#dispatch#run(l:cmd, l:errFormat)
    elseif (g:cmake_build_executor ==# 'job') || (g:cmake_build_executor ==# '' && ((has('job') && has('channel')) || has('nvim')))
        " job#run behaves differently if the qflist is open or closed
        call utils#exec#job#run(l:cmd, l:errFormat)
    else
        " Close quickfix list to discard custom error format
        silent! cclose
        call utils#exec#system#run(l:cmd, l:errFormat)
    endif
endfunction

" Prints warning message
function! utils#common#Warning(msg) abort
    echohl WarningMsg |
                \ echomsg a:msg |
                \ echohl None
endfunction
