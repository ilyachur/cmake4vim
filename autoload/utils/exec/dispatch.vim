" autoload/utils/exec/dispatch.vim - contains executable helpers
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

let s:pending = {}

function! s:poll(id, timer) abort
    let l:item = get(s:pending, a:id, {})
    if empty(l:item)
        call timer_stop(a:timer)
        return
    endif
    let l:request = l:item.request
    let l:file = l:request.file . '.complete'
    if !get(l:request, 'aborted', 0) && getfsize(l:file) <= 0
        return
    endif
    let l:status = get(l:request, 'aborted', 0) ? -1 : str2nr(readfile(l:file)[0])
    call timer_stop(a:timer)
    call remove(s:pending, a:id)
    call utils#common#complete(l:item.callback, l:status)
endfunction

function! utils#exec#dispatch#status() abort
    return s:pending
endfunction

" Track this request's exit status, not the last request started by another plugin.
function! utils#exec#dispatch#run(cmd, open_qf, errFormat, ...) abort
    let l:Callback = get(a:, 1, 0)
    let l:old_error = &l:errorformat
    if !empty(a:errFormat)
        let &l:errorformat = a:errFormat
    endif
    let l:old_make = &l:makeprg
    let l:previous = exists('*dispatch#request') ? get(dispatch#request(), 'id', -1) : -1
    try
        let &l:makeprg = a:cmd
        silent execute 'Make'
    finally
        let &l:makeprg = l:old_make
        let &l:errorformat = l:old_error
    endtry
    if type(l:Callback) == v:t_func
        let l:request = dispatch#request()
        if empty(l:request) || l:request.id == l:previous
            call utils#common#complete(l:Callback, -1)
            return -1
        endif
        let s:pending[l:request.id] = {'request': l:request, 'callback': l:Callback}
        let l:timer = timer_start(50, function('s:poll', [l:request.id]), {'repeat': -1})
        call s:poll(l:request.id, l:timer)
    endif
    return 0
endfunction
