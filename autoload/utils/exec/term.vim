" autoload/utils/exec/term.vim - contains executable helpers
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

" Private functions {{{ "
let s:cmake4vim_term = {}
let s:cmake4vim_jobs_pool = []

function! s:createQuickFix(status) abort
    let l:Callback = get(s:cmake4vim_term, 'on_exit', 0)
    let l:old_error = &errorformat
    if !empty(s:cmake4vim_term['err_fmt'])
        let &errorformat = s:cmake4vim_term['err_fmt']
    endif
    " just to be sure all messages were processed
    sleep 100m
    cgetexpr join(s:cmake4vim_term['cout'], "\n")
    silent call setqflist([], 'a', {'title' : s:cmake4vim_term['cmd']})
    if !empty(s:cmake4vim_term['err_fmt'])
        let &errorformat = l:old_error
    endif
    " Remove cmake4vim job
    let s:cmake4vim_term = {}
    call utils#common#complete(l:Callback, a:status)
    if !empty(s:cmake4vim_jobs_pool)
        let [l:next_job; s:cmake4vim_jobs_pool] = s:cmake4vim_jobs_pool
        call utils#exec#term#run(l:next_job['cmd'], l:next_job['open_qf'], l:next_job['cwd'], l:next_job['err_fmt'], l:next_job['on_exit'])
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
    if empty(s:cmake4vim_term) || a:channel != get(s:cmake4vim_term, 'channel', a:channel)
        return
    endif
    " Collect outputs
    let s:cmake4vim_term['cout'] += s:prepareOut(a:msg)
endfunction

function! s:vimExit(job, status) abort
    if empty(s:cmake4vim_term) || job_getchannel(a:job) != get(s:cmake4vim_term, 'channel', job_getchannel(a:job))
        return
    endif
    let s:cmake4vim_term.exit_status = a:status
    call s:vimFinish()
endfunction

function! s:vimClose(channel) abort
    if empty(s:cmake4vim_term) || a:channel != get(s:cmake4vim_term, 'channel', a:channel)
        return
    endif
    let s:cmake4vim_term.channel_closed = 1
    call s:vimFinish()
endfunction

function! s:vimFinish() abort
    " Process exit and channel closure can arrive in either order. Both are
    " needed: exit provides the status, closure guarantees all output was read.
    if !has_key(s:cmake4vim_term, 'exit_status') || !get(s:cmake4vim_term, 'channel_closed', 0)
                \ || get(s:cmake4vim_term, 'finishing', 0)
        return
    endif
    let s:cmake4vim_term.finishing = 1
    let l:status = s:cmake4vim_term.exit_status
    let l:open_qf = get(s:cmake4vim_term, 'open_qf', 0)

    let l:cmd = s:cmake4vim_term['cmd']
    if l:status != 0
        let s:cmake4vim_jobs_pool = []
    endif
    call s:createQuickFix(l:status)

    if l:open_qf == 0
        silent execute printf('%sbotright %d cwindow', g:cmake_build_executor_split_mode ==# 'sp' ? '' : 'vert ', utils#common#getWindowSize())
    else
        silent execute printf('%sbotright %d copen', g:cmake_build_executor_split_mode ==# 'sp' ? '' : 'vert ', utils#common#getWindowSize())
    endif
    cbottom

    if l:status == 0
        silent echon 'Success! ' . l:cmd
    else
        silent echon 'Failure! ' . l:cmd
    endif
endfunction
" }}} Vim functions "

" nvim functions {{{ "
function! s:nVimOut(job_id, data, event) abort
    if empty(s:cmake4vim_term) || a:job_id != get(s:cmake4vim_term, 'job', -1)
        return
    endif
    " Collect outputs
    for val in filter(a:data, '!empty(v:val)')
        let s:cmake4vim_term['cout'] += s:prepareOut(val)
    endfor
endfunction

function! s:nVimExit(job_id, data, event) abort
    if empty(s:cmake4vim_term) || a:job_id != get(s:cmake4vim_term, 'job', -1)
        return
    endif
    let l:cmd = s:cmake4vim_term['cmd']

    let l:open_qf = get(s:cmake4vim_term, 'open_qf', 0)
    silent exec 'bwipeout! ' . s:cmake4vim_term['termbuf']

    " Clean the job pool if exit code is not equal to 0
    if a:data != 0
        let s:cmake4vim_jobs_pool = []
    endif
    call s:createQuickFix(a:data)

    if a:data != 0 || l:open_qf != 0
        silent execute printf('%sbotright %d copen', g:cmake_build_executor_split_mode ==# 'sp' ? '' : 'vert ', utils#common#getWindowSize())
    endif
    if a:data == 0
        silent echon 'Success! ' . l:cmd
    else
        silent echon 'Failure! ' . l:cmd
    endif
endfunction
" }}} nvim functions "
" }}} Private functions "

function! utils#exec#term#run(cmd, open_qf, cwd, err_fmt, ...) abort
    " if there is a job or if the buffer is open, abort
    if !empty(s:cmake4vim_term)
        call utils#common#Warning('Async execute is already running')
        return -1
    endif
    if !isdirectory(a:cwd)
        call utils#common#Warning('Cannot run job. Work directory: ' . a:cwd . 'does not exist.')
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
                \ 'err_fmt': a:err_fmt,
                \ 'on_exit': get(a:, 1, 0)
                \ }
    if has('nvim')
        silent execute printf('keepalt botright %d %s', utils#common#getWindowSize(), g:cmake_build_executor_split_mode)
        execute 'enew'
        let l:job = termopen(a:cmd, {
                    \ 'on_stdout': function('s:nVimOut'),
                    \ 'on_stderr': function('s:nVimOut'),
                    \ 'on_exit': function('s:nVimExit'),
                    \ 'cwd': a:cwd,
                    \ })
        normal! G
        let l:termbufnr = bufnr()
    else
        let l:cmd = has('win32') ? a:cmd : [&shell, '-c', a:cmd]
        silent execute printf('keepalt botright %d %s', utils#common#getWindowSize(), g:cmake_build_executor_split_mode)
        let l:options = {
                    \ 'term_name': l:cmake4vim_term,
                    \ 'exit_cb': function('s:vimExit'),
                    \ 'close_cb': function('s:vimClose'),
                    \ 'out_cb': function('s:vimOut'),
                    \ 'term_finish': 'close',
                    \ g:cmake_build_executor_split_mode ==# 'sp' ? 'term_rows' : 'term_cols': utils#common#getWindowSize(),
                    \ 'out_modifiable' : 0,
                    \ 'err_modifiable' : 0,
                    \ 'norestore': 1,
                    \ 'curwin': 1,
                    \ 'cwd': a:cwd
                    \ }
        let l:job = term_start(l:cmd, l:options)
        let s:cmake4vim_term.channel = job_getchannel(term_getjob(l:job))
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

function! utils#exec#term#append(cmd, open_qf, cwd, err_fmt, ...) abort
    if !empty(s:cmake4vim_term)
        let s:cmake4vim_jobs_pool += [
                    \ {
                        \ 'cmd': a:cmd,
                        \ 'cwd': a:cwd,
                        \ 'open_qf': a:open_qf,
                        \ 'err_fmt': a:err_fmt,
                        \ 'on_exit': get(a:, 1, 0)
                    \ }
                \]
        return 0
    endif
    return utils#exec#term#run(a:cmd, a:open_qf, a:cwd, a:err_fmt, get(a:, 1, 0))
endfunction
