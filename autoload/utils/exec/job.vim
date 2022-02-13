" autoload/utils/exec/job.vim - contains executable helpers
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

" Private functions {{{ "
let s:cmake4vim_job = {}
let s:cmake4vim_buf = 'cmake4vim_execute'
let s:cmake4vim_jobs_pool = []

function! s:closeBuffer() abort
    let l:bufnr = bufnr(s:cmake4vim_buf)
    if l:bufnr == -1
        return
    endif

    let l:winnr = bufwinnr(l:bufnr)
    if l:winnr != -1
        exec l:winnr.'wincmd c'
    endif

    silent exec 'bwipeout ' . l:bufnr
endfunction

function! s:createQuickFix() abort
    " just to be sure all messages were processed
    sleep 100m
    let l:bufnr = bufnr(s:cmake4vim_buf)
    if l:bufnr == -1
        return
    endif
    let l:old_error = &errorformat
    if s:cmake4vim_job['err_fmt'] !=# ''
        let &errorformat = s:cmake4vim_job['err_fmt']
    endif

    silent execute 'cgetbuffer ' . l:bufnr
    silent call setqflist( [], 'a', { 'title' : s:cmake4vim_job[ 'cmd' ] } )
    if s:cmake4vim_job['err_fmt'] !=# ''
        let &errorformat = l:old_error
    endif
    " Remove cmake4vim job
    let s:cmake4vim_job = {}
    call s:closeBuffer()
    if !empty(s:cmake4vim_jobs_pool)
        let [ l:next_job; s:cmake4vim_jobs_pool  ] = s:cmake4vim_jobs_pool
        silent call utils#exec#job#run(l:next_job['cmd'], l:next_job['open_qf'], l:next_job['cwd'], l:next_job['err_fmt'])
    endif
endfunction

function! s:vimClose(channel) abort
    let l:open_qf = get(s:cmake4vim_job, 'open_qf', 0)

    let l:ret_code = job_info(s:cmake4vim_job['job'])['exitval']
    if l:ret_code == 0
        echon 'Success! ' . s:cmake4vim_job['cmd']
    else
        echon 'Failure! ' . s:cmake4vim_job['cmd']
    endif

    " Clean the job pool if exit code is not equal to 0
    if l:ret_code != 0
        let s:cmake4vim_jobs_pool = []
    endif
    call s:createQuickFix()

    if l:open_qf == 0
        silent execute g:cmake_build_executor_height . 'cwindow'
    else
        silent execute g:cmake_build_executor_height . 'copen'
    endif
    cbottom
endfunction

function! s:nVimOut(job_id, data, event) abort
    let l:bufnr = bufnr(s:cmake4vim_buf)
    call setbufvar(l:bufnr, '&modifiable', 1)
    for val in filter(a:data, '!empty(v:val)')
        silent call appendbufline(l:bufnr, '$', trim(val, "\r\n"))
        normal! G
    endfor
    call setbufvar(l:bufnr, '&modifiable', 0)
endfunction

function! s:nVimExit(job_id, data, event) abort
    let l:open_qf = s:cmake4vim_job['open_qf']

    " using only appendbufline results in an empty first line
    let l:bufnr = bufnr(s:cmake4vim_buf)
    call setbufvar(l:bufnr, '&modifiable', 1)
    call deletebufline( l:bufnr, 1 )
    call setbufvar(l:bufnr, '&modifiable', 0)

    " Clean the job pool if exit code is not equal to 0
    if a:data != 0
        let s:cmake4vim_jobs_pool = []
    endif
    call s:createQuickFix()
    if a:data != 0 || l:open_qf != 0
        silent execute g:cmake_build_executor_height . 'copen'
    endif
endfunction

function! s:createJobBuf() abort
    let l:cursor_was_in_quickfix = getwininfo(win_getid())[0]['quickfix']

    call s:closeBuffer()
    " qflist is open somewhere
    if !empty(filter(range(1, winnr('$')), 'getwinvar(v:val, "&ft") ==# "qf"'))
        " move the cursor there
        silent execute g:cmake_build_executor_height . 'copen'
        silent execute 'keepalt edit ' . s:cmake4vim_buf
    else
        silent execute printf('keepalt belowright %dsplit %s', g:cmake_build_executor_height, s:cmake4vim_buf)
    endif
    setlocal bufhidden=hide buftype=nofile buflisted nolist
    setlocal noswapfile nowrap nomodifiable
    nmap <buffer> <C-c> :call utils#exec#job#stop()<CR>
    if !l:cursor_was_in_quickfix
        wincmd p
    endif
    return bufnr(s:cmake4vim_buf)
endfunction
" }}} Private functions "

function! utils#exec#job#getJobsPool() abort
    return s:cmake4vim_jobs_pool
endfunction

function! utils#exec#job#stop() abort
    if empty(s:cmake4vim_job)
        call s:closeBuffer()
        return
    endif
    let l:job = s:cmake4vim_job['job']
    if has('nvim')
        call jobstop(l:job)
    else
        call job_stop(l:job)
    endif
    let s:cmake4vim_jobs_pool = []
    call s:createQuickFix()
    silent execute g:cmake_build_executor_height . 'copen'
    call utils#common#Warning('Job is cancelled!')
endfunction

function! utils#exec#job#run(cmd, open_qf, cwd, err_fmt) abort
    " if there is a job or if the buffer is open, abort
    if !empty(s:cmake4vim_job) || bufnr(s:cmake4vim_buf) != -1
        call utils#common#Warning('Async execute is already running')
        return -1
    endif
    let l:outbufnr = s:createJobBuf()
    let s:cmake4vim_job = { 'cmd': a:cmd, 'open_qf': a:open_qf, 'err_fmt': a:err_fmt }
    if has('nvim')
        let l:job = jobstart(a:cmd, {
                    \ 'on_stdout': function('s:nVimOut'),
                    \ 'on_stderr': function('s:nVimOut'),
                    \ 'on_exit': function('s:nVimExit'),
                    \ 'cwd': a:cwd,
                    \ })
    else
        let l:cmd = has('win32') ? a:cmd : [&shell, '-c', a:cmd]
        let l:job = job_start(l:cmd, {
                    \ 'close_cb': function('s:vimClose'),
                    \ 'out_io' : 'buffer', 'out_buf' : l:outbufnr,
                    \ 'err_io' : 'buffer', 'err_buf' : l:outbufnr,
                    \ 'out_modifiable' : 0,
                    \ 'err_modifiable' : 0,
                    \ 'cwd': a:cwd,
                    \ })
    endif
   let s:cmake4vim_job['job'] = l:job
    if !has('nvim')
       let s:cmake4vim_job['channel'] = job_getchannel(l:job)
    endif
    return l:job
endfunction

function! utils#exec#job#status() abort
    return s:cmake4vim_job
endfunction

function! utils#exec#job#append(cmd, open_qf, cwd, err_fmt) abort
    if !empty(s:cmake4vim_job)
        let s:cmake4vim_jobs_pool += [
                    \ {
                        \ 'cmd': a:cmd,
                        \ 'cwd': a:cwd,
                        \ 'open_qf': a:open_qf,
                        \ 'err_fmt': a:err_fmt
                    \ }
                \ ]
        return 0
    endif
    return utils#exec#job#run(a:cmd, a:open_qf, a:cwd, a:err_fmt)
endfunction
