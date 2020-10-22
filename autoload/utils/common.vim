" autoload/utils/common.vim - contains cmake helpers
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

function! utils#common#runDispatch(cmd) abort
    let l:old_make = &l:makeprg

    try
        let &l:makeprg = a:cmd
        silent! execute 'Make'
    finally
        let &l:makeprg = l:old_make
    endtry
endfunction

function! utils#common#runSystem(cmd) abort
    let l:s_out = system(a:cmd)
    cgetexpr l:s_out
    copen
endfunction

function! utils#common#executeCommand(cmd, ...) abort
    " Close quickfix list in order to don't save custom error format
    silent! cclose
    let l:errFormat = get(a:, 1, '')
    let l:old_error = &l:errorformat
    if l:errFormat !=# ''
        let &l:errorformat = l:errFormat
    endif

    if exists(':Dispatch')
        silent call utils#common#runDispatch(a:cmd)
    else
        silent call utils#common#runSystem(a:cmd)
    endif

    if l:errFormat !=# ''
        let &l:errorformat = l:old_error
    endif
endfunction
