" autoload/utils/exec/system.vim - contains executable helpers
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

" Use system
function! utils#exec#system#run(cmd, errFormat) abort
    let l:old_error = &l:errorformat
    if a:errFormat !=# ''
        let &l:errorformat = a:errFormat
    endif
    let l:s_out = system(a:cmd)
    cgetexpr l:s_out
    call setqflist( [], 'a', { 'title' : a:cmd } )
    copen
    if a:errFormat !=# ''
        let &l:errorformat = l:old_error
    endif
endfunction
