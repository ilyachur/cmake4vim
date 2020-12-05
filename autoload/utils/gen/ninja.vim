" autoload/gen/vs.vim - contains helpers for Ninja generator
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

function! s:skipTarget(line) abort
    if stridx(a:line, 'ninja: warning:') != -1 || stridx(a:line, '[') == 0
        return 1
    endif
    return 0
endfunction

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
    let l:res = split(system('cmake --build ' . utils#fs#fnameescape(a:build_dir) . ' --target help'), "\n")
    let l:list_targets = []
    let l:all_exist = 0
    for l:value in l:res
        if l:value !=# '' && s:skipTarget(l:value) == 0
            let l:target = split(l:value, ':')[0]
            if l:target ==# 'all'
                let l:all_exist = 1
            endif
            let l:list_targets += [l:target]
        endif
    endfor
    if l:all_exist == 0 && !empty(l:list_targets)
        let l:list_targets += ['all']
    endif
    return l:list_targets
endfunction

" Returns the cmake build command for CMake generator
function! utils#gen#ninja#getBuildCommand(build_dir, target, make_arguments) abort
    let l:cmd = 'cmake --build ' . utils#fs#fnameescape(a:build_dir) . ' --target ' . a:target . ' -- '
    if stridx(a:make_arguments, '-C ') == -1 && a:target !=# utils#gen#ninja#getCleanTarget()
        let l:cmd .= '-C ' . utils#fs#fnameescape(fnamemodify(a:build_dir, ':p:h')) . ' '
    endif
    let l:cmd .= a:make_arguments
    return l:cmd
endfunction
