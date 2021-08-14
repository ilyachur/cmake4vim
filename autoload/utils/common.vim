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

" Executes commands
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
        let [l:cmd; l:cmds] = mapnew(a:cmds, {_, val -> s:add_noglob(val)})
        silent call utils#exec#job#run(l:cmd, a:open_result, l:errFormat)
        for l:command in l:cmds
            silent call utils#exec#job#append(l:command, a:open_result, l:errFormat)
        endfor
    elseif (g:cmake_build_executor ==# 'term') || (g:cmake_build_executor ==# '' && (has('terminal') || has('nvim')))
        let [l:cmd; l:cmds] = mapnew(a:cmds, {_, val -> s:add_noglob(val)})
        silent call utils#exec#term#run(l:cmd, a:open_result, l:errFormat)
        for l:command in l:cmds
            silent call utils#exec#term#append(l:command, a:open_result, l:errFormat)
        endfor
    else
        " Close quickfix list to discard custom error format
        for l:cmd in a:cmds
            silent! cclose
            " system is synchronous executor
            let l:cmd = s:add_noglob(l:cmd)
            let l:ret_code = utils#exec#system#run(l:cmd, a:open_result, l:errFormat)
            if l:ret_code != 0
                break
            endif
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
