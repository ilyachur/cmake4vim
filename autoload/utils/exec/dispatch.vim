" autoload/utils/exec/dispatch.vim - contains executable helpers
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

" Use dispatch to make command
function! utils#exec#dispatch#run(cmd, errFormat) abort
    let l:old_error = &l:errorformat
    if a:errFormat !=# ''
        let &l:errorformat = a:errFormat
    endif
    let l:old_make = &l:makeprg

    try
        let &l:makeprg = a:cmd
        silent! execute 'Make'
    finally
        let &l:makeprg = l:old_make
    endtry
    if a:errFormat !=# ''
        let &l:errorformat = l:old_error
    endif
endfunction

