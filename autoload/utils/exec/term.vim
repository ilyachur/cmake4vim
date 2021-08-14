" autoload/utils/exec/term.vim - contains executable helpers
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

" Private functions {{{ "
let s:cmake4vim_term = {}
let s:cmake4vim_jobs_pool = []

function! s:createQuickFix() abort
    let l:old_error = &errorformat
    if s:cmake4vim_term['err_fmt'] !=# ''
        let &errorformat = s:cmake4vim_term['err_fmt']
    endif
    " just to be sure all messages were processed
    sleep 100m
    cgetexpr join(s:cmake4vim_term['cout'], "\n")
    silent call setqflist( [], 'a', { 'title' : s:cmake4vim_term[ 'cmd' ] } )
    if s:cmake4vim_term['err_fmt'] !=# ''
        let &errorformat = l:old_error
    endif
    " Remove cmake4vim job
    let s:cmake4vim_term = {}
    if len(s:cmake4vim_jobs_pool) > 0
        let l:next_job = s:cmake4vim_jobs_pool[0]
        let s:cmake4vim_jobs_pool = s:cmake4vim_jobs_pool[1:]
        silent call utils#exec#term#run(l:next_job['cmd'], l:next_job['open_qf'], l:next_job['err_fmt'])
    endif
endfunction

function! s:prepareOut(msg) abort
    let l:without_ascii = substitute(a:msg, '\%x1B\[[0-9;]*\a', '', 'g')
    let l:without_ascii = substitute(l:without_ascii, '\r', '', 'g')
    let l:lines = split(l:without_ascii, '\n')
    return l:lines
endfunction

" Vim functions {{{ "
function! s:vimOut(channel, msg) abort
    " Collect outputs
    let s:cmake4vim_term['cout'] += s:prepareOut(a:msg)
endfunction

function! s:vimClose(channel, status) abort
    let l:open_qf = get(s:cmake4vim_term, 'open_qf', 0)

    let l:cmd = s:cmake4vim_term['cmd']
    call s:createQuickFix()

    if l:open_qf == 0
        silent cwindow
    else
        silent copen
    endif
    cbottom

    if a:status == 0
        silent echon 'Success! ' . l:cmd
    else
        silent echon 'Failure! ' . l:cmd
    endif
endfunction
" }}} Vim functions "

" nvim functions {{{ "
function! s:nVimOut(job_id, data, event) abort
    if !empty(s:cmake4vim_term)
        " Collect outputs
        for val in filter(a:data, '!empty(v:val)')
            let s:cmake4vim_term['cout'] += s:prepareOut(val)
        endfor
    endif
endfunction

function! s:nVimExit(job_id, data, event) abort
    let l:job = s:cmake4vim_term['job']
    let l:cmd = s:cmake4vim_term['cmd']

    let l:open_qf = get(s:cmake4vim_term, 'open_qf', 0)
    silent exec 'bwipeout! ' . s:cmake4vim_term['termbuf']

    call s:createQuickFix()

    if a:data != 0 || l:open_qf != 0
        copen
    endif
    if a:data == 0
        silent echon 'Success! ' . l:cmd
    else
        silent echon 'Failure! ' . l:cmd
    endif
endfunction
" }}} nvim functions "
" }}} Private functions "

function! utils#exec#term#run(cmd, open_qf, err_fmt) abort
    " if there is a job or if the buffer is open, abort
    if !empty(s:cmake4vim_term)
        call utils#common#Warning('Async execute is already running')
        return -1
    endif
    cclose
    let l:cmake4vim_term = 'cmake4vim_execute'
    let l:currentnr = winnr()
    let l:termbufnr = 0
    let s:cmake4vim_term = {
                \ 'cmd': a:cmd,
                \ 'open_qf': a:open_qf,
                \ 'cout': [],
                \ 'err_fmt': a:err_fmt
                \ }
    if has('nvim')
        execute '10split'
        execute 'enew'
        let l:job = termopen(a:cmd, {
                    \ 'on_stdout': function('s:nVimOut'),
                    \ 'on_stderr': function('s:nVimOut'),
                    \ 'on_exit': function('s:nVimExit'),
                    \ })
        normal! G
        let l:termbufnr = bufnr()
    else
        let l:cmd = has('win32') ? a:cmd : [&shell, '-c', a:cmd]
        let l:job = term_start(l:cmd, {
                    \ 'term_name': l:cmake4vim_term,
                    \ 'exit_cb': function('s:vimClose'),
                    \ 'out_cb': function('s:vimOut'),
                    \ 'term_finish': 'close',
                    \ 'term_rows': 10,
                    \ 'out_modifiable' : 0,
                    \ 'err_modifiable' : 0,
                    \ 'norestore': 1,
                    \ })
    endif
    if has('nvim')
        let s:cmake4vim_term['termbuf'] = l:termbufnr
    endif
    let s:cmake4vim_term['job'] = l:job
    exec l:currentnr.'wincmd w'
    return l:job
endfunction

function! utils#exec#term#status() abort
    return s:cmake4vim_term
endfunction

function! utils#exec#term#append(cmd, open_qf, err_fmt) abort
    " if there is a job or if the buffer is open, abort
    if !empty(s:cmake4vim_term)
        let s:cmake4vim_jobs_pool += [
                    \ {
                        \ 'cmd': a:cmd,
                        \ 'open_qf': a:open_qf,
                        \ 'err_fmt': a:err_fmt
                    \ }
                \]
        return
    endif
    call utils#exec#term#run(a:cmd, a:open_qf, a:err_fmt)
endfunction
