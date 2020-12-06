" autoload/utils/common.vim - contains cmake helpers
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

" Executes the command
function! utils#common#executeCommand(cmd, ...) abort
    " Close quickfix list in order to don't save custom error format
    silent! cclose
    let l:errFormat = get(a:, 1, '')

    if (has('job') && has('channel')) || has('nvim')
        call utils#exec#job#run(a:cmd, l:errFormat)
    elseif exists(':Dispatch')
        call utils#exec#dispatch#run(a:cmd, l:errFormat)
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
