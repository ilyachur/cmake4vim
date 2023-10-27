" autoload/gen/vs.vim - contains helpers for Visual Studio generator
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

" Returns the name of CMake generator
function! utils#gen#vs#getGeneratorName() abort
    return 'Visual Studio'
endfunction

" Returns the default target for current CMake generator
function! utils#gen#vs#getDefaultTarget() abort
    return 'ALL_BUILD'
endfunction

" Returns the clean target for CMake generator
function! utils#gen#vs#getCleanTarget() abort
    return 'clean'
endfunction

" Returns the list of targets for CMake generator
function! utils#gen#vs#getTargets(build_dir) abort
    " Parse VS projects
    let l:list_targets = []
    if !isdirectory(a:build_dir)
        return l:list_targets
    endif
    let l:res = split(system('dir *.vcxproj /S /B'), "\n")
    for l:value in l:res
        if !empty(l:value)
            let l:file = l:value[len(a:build_dir):]
            " Exclude projects from CMakeFiles folder
            if stridx(l:file, 'CMakeFiles') != -1
                continue
            endif
            let l:files = split(l:file, '\\')
            let l:list_targets += [fnamemodify(l:files[-1], ':r')]
        endif
    endfor
    return l:list_targets
endfunction

" Returns the cmake build command for CMake generator
function! utils#gen#vs#getBuildCommand(build_dir, target, cmake_build_args, make_arguments) abort
    let l:cmd = g:cmake_executable . ' --build ' . utils#fs#fnameescape(a:build_dir) . ' --target ' . a:target . ' ' . a:cmake_build_args . ' -- ' . a:make_arguments
    return l:cmd
endfunction
