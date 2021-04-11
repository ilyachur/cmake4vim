" autoload/utils/exec/job.vim - contains executable helpers
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

" Private functions {{{ "
let s:cmake4vim_job = {}
let s:cmake4vim_buf = 'cmake4vim_execute'
let s:err_fmt = ''

function! s:appendLine(text) abort
    let l:oldnr = winnr()
    let l:winnr = bufwinnr(s:cmake4vim_buf)

    if l:oldnr != l:winnr
        if l:winnr == -1
            silent exec 'sp ' . escape(bufname(bufnr(s:cmake4vim_buf)), ' \')
            setlocal modifiable
            silent call append('$', a:text)
            silent hide
        else
            exec l:winnr.'wincmd w'
            setlocal modifiable
            silent call append('$', a:text)
        endif
    else
        setlocal modifiable
        silent call append('$', a:text)
    endif
    $
    setlocal nomodifiable
    exec l:oldnr.'wincmd w'
endfunction

function! s:closeBuffer() abort
    let l:oldnr = winnr()
    let l:winnr = bufwinnr(s:cmake4vim_buf)
    let l:bufnr = bufnr(s:cmake4vim_buf)

    if l:oldnr != l:winnr && l:winnr != -1
        exec l:winnr.'wincmd c'
    endif
    if l:bufnr != -1
        try
            silent exec 'bwipeout ' . escape(bufname(l:bufnr), ' \')
        catch
        endtry
    endif
endfunction

function! s:createQuickFix() abort
    let l:bufnr = bufnr(s:cmake4vim_buf)
    if l:bufnr == -1
        return
    endif
    cexpr ''
    let l:old_error = &errorformat
    if s:err_fmt !=# ''
        let &errorformat = s:err_fmt
    endif
    execute 'cbuffer ' . l:bufnr
    call s:closeBuffer()
    if s:err_fmt !=# ''
        let &errorformat = l:old_error
    endif
endfunction

function! s:vimOut(channel, message) abort
    if empty(s:cmake4vim_job) || a:channel != s:cmake4vim_job['channel']
        return
    endif
    call s:appendLine(a:message)
endfunction

function! s:vimExit(channel, message) abort
    if empty(s:cmake4vim_job) || a:channel != s:cmake4vim_job['job']
        return
    endif
    call s:createQuickFix()
    if a:message != 0
        copen
    endif
endfunction

function! s:vimClose(channel) abort
    if empty(s:cmake4vim_job) || a:channel != s:cmake4vim_job['channel']
        return
    endif
    let s:cmake4vim_job = {}
endfunction

function! s:nVimOut(job_id, data, event) abort
    if empty(s:cmake4vim_job) || a:job_id != s:cmake4vim_job['job']
        return
    endif
    for val in a:data
        call s:appendLine(val)
    endfor
endfunction

function! s:nVimExit(job_id, data, event) abort
    if empty(s:cmake4vim_job) || a:job_id != s:cmake4vim_job['job']
        return
    endif
    let s:cmake4vim_job = {}
    call s:createQuickFix()
    if a:data != 0
        copen
    endif
endfunction

function! s:createJobBuf() abort
    silent execute 'belowright 10split ' . s:cmake4vim_buf
    setlocal bufhidden=hide buftype=nofile buflisted nolist
    setlocal noswapfile nowrap nomodifiable
    nmap <buffer> <C-c> :call utils#exec#job#stop()<CR>
    let l:bufnum = winbufnr(0)
    wincmd p
    return l:bufnum
endfunction
" }}} Private functions "

function! utils#exec#job#stop() abort
    if empty(s:cmake4vim_job)
        return
    endif
    let l:job = s:cmake4vim_job['job']
    let s:cmake4vim_job = {}
    try
        if has('nvim')
            call jobstop(l:job)
        else
            call job_stop(l:job)
        endif
    catch
    endtry
    call s:closeBuffer()
    echom 'Job is canceled!'
endfunction

" Use job
function! utils#exec#job#run(cmd, err_fmt) abort
    " Create a new quickfix
    let l:openbufnr = bufnr(s:cmake4vim_buf)
    if l:openbufnr != -1
        call utils#common#Warning('Async execute is already running')
        return -1
    endif
    let l:outbufnr = s:createJobBuf()
    let s:err_fmt = a:err_fmt
    if has('nvim')
        let l:job = jobstart(a:cmd, {
                    \ 'on_stdout': function('s:nVimOut'),
                    \ 'on_stderr': function('s:nVimOut'),
                    \ 'on_exit': function('s:nVimExit'),
                    \ })
        let s:cmake4vim_job = {
                    \ 'job': l:job
                    \ }
    else
        let l:job = job_start(a:cmd, {
                    \ 'out_cb': function('s:vimOut'),
                    \ 'err_cb': function('s:vimOut'),
                    \ 'exit_cb': function('s:vimExit'),
                    \ 'close_cb': function('s:vimClose'),
                    \ })
        let s:cmake4vim_job = {
                    \ 'job': l:job,
                    \ 'channel': job_getchannel(l:job)
                    \ }
    endif
    return l:job
endfunction
