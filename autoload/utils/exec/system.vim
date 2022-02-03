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

    if l:ret_code == 0
        echon 'Success! ' . a:cmd
    else
        echon 'Failure! ' . a:cmd
    endif

    cgetexpr l:s_out
    call setqflist( [], 'a', { 'title' : a:cmd } )
    if a:open_qf == 1 || l:ret_code != 0
        execute g:cmake_build_executor_height . 'copen'
    endif
    if a:errFormat !=# ''
        let &l:errorformat = l:old_error
    endif
    return l:ret_code
endfunction
