" autoload/gen/vs.vim - contains helpers for Makefiles generator
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

" Returns the name of CMake generator
function! utils#gen#make#getGeneratorName() abort
    return 'Make'
endfunction

" Returns the default target for current CMake generator
function! utils#gen#make#getDefaultTarget() abort
    return 'all'
endfunction

" Returns the clean target for CMake generator
function! utils#gen#make#getCleanTarget() abort
    return 'clean'
endfunction

" Returns the list of targets for CMake generator
function! utils#gen#make#getTargets(build_dir) abort
    let l:res = split(system(g:cmake_executable . ' --build ' . utils#fs#fnameescape(a:build_dir) . ' --target help'), "\n")
    let l:list_targets = []
    " Remove the first line which is not a target
    call remove(l:res, 0)
    for l:value in l:res
        let l:parced_target = split(l:value)
        if !empty(l:value) && len(l:parced_target) > 1
            let l:list_targets += [l:parced_target[1]]
        endif
    endfor
    return l:list_targets
endfunction

" Returns the cmake build command for CMake generator
function! utils#gen#make#getBuildCommand(build_dir, target, cmake_build_args, make_arguments) abort
    let l:cmd = g:cmake_executable . ' --build ' . utils#fs#fnameescape(a:build_dir) . ' --target ' . a:target . ' ' . a:cmake_build_args . ' -- ' . a:make_arguments
    return l:cmd
endfunction
