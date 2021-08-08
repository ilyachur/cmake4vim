" autoload/utils/common.vim - contains cmake helpers
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

" Private functions {{{ "
function! s:add_noglob(cmd) abort
    if has('win32')
        return a:cmd
    endif

    silent! let l:status = system('command -v noglob')

    if l:status =~# '\w\+'
        return 'noglob ' . a:cmd
    endif

    return a:cmd
endfunction
" }}} Private functions "

" Executes the command
function! utils#common#executeCommands(cmds, open_result, ...) abort
    let l:errFormat = get(a:, 1, '')

    if (g:cmake_build_executor ==# 'dispatch') || (g:cmake_build_executor ==# '' && exists(':Dispatch'))
        " Close quickfix list to discard custom error format
        silent! cclose
        " Dispatch doesn't support pool of tasks
        let l:cmd = join(a:cmds, ' && ')
        silent call utils#exec#dispatch#run(l:cmd, a:open_result, l:errFormat)
    elseif (g:cmake_build_executor ==# 'job') || (g:cmake_build_executor ==# '' && ((has('job') && has('channel')) || has('nvim')))
        " job#run behaves differently if the qflist is open or closed
        let l:count = 0
        for l:cmd in a:cmds
            let l:cmd = s:add_noglob(l:cmd)
            if l:count == 0
                silent call utils#exec#job#run(l:cmd, a:open_result, l:errFormat)
            else
                silent call utils#exec#job#append(l:cmd, a:open_result, l:errFormat)
            endif
            let l:count += 1
        endfor
    elseif (g:cmake_build_executor ==# 'term') || (g:cmake_build_executor ==# '' && (has('terminal') || has('nvim')))
        let l:count = 0
        for l:cmd in a:cmds
            let l:cmd = s:add_noglob(l:cmd)
            if l:count == 0
                silent call utils#exec#term#run(l:cmd, a:open_result, l:errFormat)
            else
                silent call utils#exec#term#append(l:cmd, a:open_result, l:errFormat)
            endif
            let l:count += 1
        endfor
    else
        " Close quickfix list to discard custom error format
        silent! cclose
        for l:cmd in a:cmds
            " system is synchronous executor
            let l:cmd = s:add_noglob(l:cmd)
            silent call utils#exec#system#run(l:cmd, a:open_result, l:errFormat)
        endfor
    endif
endfunction

function! utils#common#executeCommand(cmd, open_result, ...) abort
    let l:errFormat = get(a:, 1, '')

    silent call utils#common#executeCommands([a:cmd], a:open_result, l:errFormat)
endfunction

function! utils#common#executeStatus() abort
    let l:status = {}
    if g:cmake_build_executor ==# 'job'
        let l:status = utils#exec#job#status()
    elseif g:cmake_build_executor ==# 'term'
        let l:status = utils#exec#term#status()
    endif
    return l:status
endfunction

" Prints warning message
function! utils#common#Warning(msg) abort
    echohl WarningMsg |
                \ echomsg a:msg |
                \ echohl None
endfunction
