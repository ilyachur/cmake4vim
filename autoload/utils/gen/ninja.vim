" autoload/gen/vs.vim - contains helpers for Ninja generator
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

" Returns the name of CMake generator
function! utils#gen#ninja#getGeneratorName() abort
    return 'Ninja'
endfunction

" Returns the default target for current CMake generator
function! utils#gen#ninja#getDefaultTarget() abort
    return 'all'
endfunction

" Returns the clean target for CMake generator
function! utils#gen#ninja#getCleanTarget() abort
    return 'clean'
endfunction

" Returns the list of targets for CMake generator
function! utils#gen#ninja#getTargets(build_dir) abort
    let l:res = split(system(g:cmake_executable . ' --build ' . utils#fs#fnameescape(a:build_dir) . ' --target help'), "\n")
    let l:list_targets = []
    let l:targets_found = 0
    for l:value in l:res
        if l:targets_found == 0
            if l:value =~# 'All primary targets'
                let l:targets_found = 1
            endif
            continue
        endif

        if l:value !=# ''
            let l:target = split(l:value, ':')[0]
            let l:list_targets += [l:target]
        endif
    endfor
    return l:list_targets
endfunction

" Returns the cmake build command for CMake generator
function! utils#gen#ninja#getBuildCommand(build_dir, target, make_arguments) abort
    let l:cmd = g:cmake_executable . ' --build ' . utils#fs#fnameescape(a:build_dir) . ' --target ' . a:target . ' -- '
    if stridx(a:make_arguments, '-C ') == -1 && a:target !=# utils#gen#ninja#getCleanTarget()
        let l:cmd .= '-C ' . utils#fs#fnameescape(fnamemodify(a:build_dir, ':p:h')) . ' '
    endif
    let l:cmd .= a:make_arguments
    return l:cmd
endfunction
