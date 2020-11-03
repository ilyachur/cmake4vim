" autoload/gen/vs.vim - contains helpers for Makefiles generator
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

function! utils#gen#make#getGeneratorName() abort
    return 'Make'
endfunction

function! utils#gen#make#getDefaultTarget() abort
    return 'all'
endfunction

function! utils#gen#make#getTargets(targets_list) abort
    let l:res = a:targets_list
    let l:list_targets = []
    " Remove the first line which is not a target
    call remove(l:res, 0)
    for l:value in l:res
        if l:value !=# ''
            let l:list_targets += [split(l:value)[1]]
        endif
    endfor
    return l:list_targets
endfunction
