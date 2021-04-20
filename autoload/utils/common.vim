" autoload/utils/common.vim - contains cmake helpers
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

" Executes the command
function! utils#common#executeCommand(cmd, ...) abort
    let l:errFormat = get(a:, 1, '')

    if (g:cmake_build_executor ==# 'dispatch') || (g:cmake_build_executor ==# '' && exists(':Dispatch'))
        " Close quickfix list to discard custom error format
        silent! cclose
        call utils#exec#dispatch#run(a:cmd, l:errFormat)
    elseif (g:cmake_build_executor ==# 'job') || (g:cmake_build_executor ==# '' && ((has('job') && has('channel')) || has('nvim')))
        call utils#exec#job#run(a:cmd, l:errFormat)
    else
        call utils#exec#system#run(a:cmd, l:errFormat)
    endif
endfunction

" Prints warning message
function! utils#common#Warning(msg) abort
    echohl WarningMsg |
                \ echomsg a:msg |
                \ echohl None
endfunction
