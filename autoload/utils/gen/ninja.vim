" autoload/gen/vs.vim - contains helpers for Ninja generator
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

function! utils#gen#ninja#getGeneratorName() abort
    return 'Ninja'
endfunction

function! utils#gen#ninja#getDefaultTarget() abort
    return 'all'
endfunction

function! utils#gen#ninja#getCleanTarget() abort
    return 'clean'
endfunction

function! utils#gen#ninja#getTargets(targets_list) abort
    let l:res = a:targets_list
    let l:list_targets = []
    " Remove the first line which is not a target
    call remove(l:res, 0)
    for l:value in l:res
        if l:value !=# ''
            let l:list_targets += [split(l:value, ":")[0]]
        endif
    endfor
    return l:list_targets
endfunction

function! utils#gen#ninja#getBuildCommand(build_dir, target, make_arguments) abort
    let l:cmd = 'cmake --build ' . shellescape(a:build_dir) . ' --target ' . a:target . ' -- '
    if stridx(a:make_arguments, "-C ") == -1
        let l:cmd .= '-C ' . fnamemodify(a:build_dir, ':p:h') . ' '
    endif
    let l:cmd .= a:make_arguments
    return l:cmd
endfunction
