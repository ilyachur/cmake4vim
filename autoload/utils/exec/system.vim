" autoload/utils/exec/system.vim - contains executable helpers
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

" Use system
function! utils#exec#system#run(cmd, open_qf, errFormat) abort
    let l:old_error = &l:errorformat
    if a:errFormat !=# ''
        let &l:errorformat = a:errFormat
    endif
    let l:s_out = system(a:cmd)
    let l:ret_code = v:shell_error
    cgetexpr l:s_out
    call setqflist( [], 'a', { 'title' : a:cmd } )
    if a:open_qf == 1 || l:ret_code != 0
        copen
    endif
    if a:errFormat !=# ''
        let &l:errorformat = l:old_error
    endif
endfunction
