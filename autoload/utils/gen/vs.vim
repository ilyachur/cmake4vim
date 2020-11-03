" autoload/gen/vs.vim - contains helpers for Visual Studio generator
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

function! utils#gen#vs#getGeneratorName() abort
    return 'Visual Studio'
endfunction

function! utils#gen#vs#getDefaultTarget() abort
    return 'ALL_BUILD'
endfunction

function! utils#gen#vs#getTargets(targets_list) abort
    " Parse VS projects
    let l:list_targets = []
    let l:res = split(system('dir *.vcxproj /S /B'), "\n")
    if v:shell_error != 0
        let l:error_msg = 'Error: cannot detect targets!'
    else
        for l:value in l:res
            if l:value !=# ''
                let l:files = split(l:value, l:build_dir)
                if len(l:files) != 2
                    continue
                endif
                " Exclude projects from CMakeFiles folder
                let l:files = split(l:files[1], 'CMakeFiles')
                if len(l:files) != 1
                    continue
                endif
                let l:files = split(l:files[0], '\\')
                let l:list_targets += [fnamemodify(l:files[-1], ':r')]
            endif
        endfor
    endif
    return l:list_targets
endfunction
