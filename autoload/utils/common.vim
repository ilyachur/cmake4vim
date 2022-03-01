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
function! utils#common#executeCommands(cmds, open_result) abort
    " add all fields
    let l:commands = []
    for l:cmd in a:cmds
        call add(l:commands, {
                    \ 'cmd': l:cmd['cmd'],
                    \ 'cwd': get( l:cmd, 'cwd', getcwd() ),
                    \ 'errFormat': get( l:cmd, 'errFormat', '' )
                    \ })
    endfor
    if (g:cmake_build_executor ==# 'dispatch') || (g:cmake_build_executor ==# '' && exists(':Dispatch'))
        " Close quickfix list to discard custom error format
        silent! cclose
        let l:cmd_line = ''
        let l:pcwd = getcwd()
        let l:errFormat = ''
        " Dispatch doesn't support pool of tasks
        for l:cmd in l:commands
            " generate common command
            if l:cmd_line !=# ''
                let l:cmd_line .= ' && '
            endif
            let l:cwd = l:cmd['cwd']
            if l:cwd['errFormat'] !=# ''
                let l:errFormat = l:cwd['errFormat']
            endif
            if l:cwd != l:pcwd
                let l:cmd_line .= 'cd ' . utils#fs#fnameescape(l:cwd) . ' && '
                let l:pcwd = l:cwd
            endif
            let l:cmd_line .= l:cmd['cmd']
        endfor
        if l:pcwd != getcwd()
            let l:cmd_line .= ' && cd ' . utils#fs#fnameescape(getcwd())
        endif
        call utils#exec#dispatch#run(l:cmd_line, a:open_result, l:errFormat)
    elseif (g:cmake_build_executor ==# 'job') || (g:cmake_build_executor ==# '' && ((has('job') && has('channel')) || has('nvim')))
        " job#run behaves differently if the qflist is open or closed
        let [l:cmd; l:cmds] = l:commands

        call utils#exec#job#run(s:add_noglob(l:cmd['cmd']), a:open_result, l:cmd['cwd'], l:cmd['errFormat'])
        for l:command in l:cmds
            call utils#exec#job#append(s:add_noglob(l:command['cmd']), a:open_result, l:command['cwd'], l:command['errFormat'])
        endfor
    elseif (g:cmake_build_executor ==# 'term') || (g:cmake_build_executor ==# '' && (has('terminal') || has('nvim')))
        let [l:cmd; l:cmds] = l:commands

        call utils#exec#term#run(s:add_noglob(l:cmd['cmd']), a:open_result, l:cmd['cwd'], l:cmd['errFormat'])
        for l:command in l:cmds
            call utils#exec#term#append(s:add_noglob(l:command['cmd']), a:open_result, l:command['cwd'], l:command['errFormat'])
        endfor
    else
        " Close quickfix list to discard custom error format
        for l:cmd_dict in l:commands
            silent! cclose
            " system is synchronous executor
            let l:cmd = s:add_noglob(l:cmd_dict['cmd'])
            let l:cwd = l:cmd_dict['cwd']
            let l:errFormat = l:cmd_dict['errFormat']
            if l:cwd != getcwd()
                let l:cmd = 'cd ' . utils#fs#fnameescape(l:cwd) . ' && ' . l:cmd . ' && cd ' . utils#fs#fnameescape(getcwd())
            endif
            let l:ret_code = utils#exec#system#run(l:cmd, a:open_result, l:errFormat)
            if l:ret_code != 0
                break
            endif
        endfor
    endif
endfunction

function! utils#common#executeCommand(cmd, open_result, ...) abort
    let l:cwd = get(a:, 1, getcwd())
    let l:errFormat = get(a:, 2, '')

    call utils#common#executeCommands([{'cmd': a:cmd, 'cwd': l:cwd, 'errFormat': l:errFormat}], a:open_result)
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
