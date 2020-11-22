" autoload/gen/common.vim - contains common helpers for CMake generators
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

" Returns the default target for current CMake generator
" If Generator is not supported returns default target for Unix Makefiles
" Returns empty string if CMake generator is not supported
function! utils#gen#common#getDefaultTarget() abort
    let l:cmake_gen = ''
    let l:cmake_info = utils#cmake#common#getInfo()
    if !empty(l:cmake_info)
        let l:cmake_gen = l:cmake_info['cmake']['generator']
    endif
    if (l:cmake_gen ==# '' && has('win32')) || stridx(l:cmake_gen, utils#gen#vs#getGeneratorName()) != -1
        return utils#gen#vs#getDefaultTarget()
    elseif stridx(l:cmake_gen, utils#gen#ninja#getGeneratorName()) != -1
        return utils#gen#ninja#getDefaultTarget()
    elseif l:cmake_gen ==# '' || stridx(l:cmake_gen, utils#gen#make#getGeneratorName()) != -1
        return utils#gen#make#getDefaultTarget()
    endif
    return ''
endfunction

" Returns the clean target for CMake generator
" Returns empty string if CMake generator is not supported
function! utils#gen#common#getCleanTarget() abort
    let l:cmake_gen = ''
    let l:cmake_info = utils#cmake#common#getInfo()
    if !empty(l:cmake_info)
        let l:cmake_gen = l:cmake_info['cmake']['generator']
    endif
    if (l:cmake_gen ==# '' && has('win32')) || stridx(l:cmake_gen, utils#gen#vs#getGeneratorName()) != -1
        return utils#gen#vs#getCleanTarget()
    elseif stridx(l:cmake_gen, utils#gen#ninja#getGeneratorName()) != -1
        return utils#gen#ninja#getCleanTarget()
    elseif stridx(l:cmake_gen, utils#gen#make#getGeneratorName()) != -1
        return utils#gen#make#getCleanTarget()
    endif
    return ''
endfunction

" Returns the list of targets for CMake generator
" Returns the empty list if CMake generator is not supported
function! utils#gen#common#getTargets(build_dir) abort
    let l:cmake_gen = ''
    let l:cmake_info = utils#cmake#common#getInfo()
    if !empty(l:cmake_info)
        let l:cmake_gen = l:cmake_info['cmake']['generator']
    endif
    if (l:cmake_gen ==# '' && has('win32')) || stridx(l:cmake_gen, utils#gen#vs#getGeneratorName()) != -1
        return utils#gen#vs#getTargets(a:build_dir)
    elseif stridx(l:cmake_gen, utils#gen#ninja#getGeneratorName()) != -1
        return utils#gen#ninja#getTargets(a:build_dir)
    elseif stridx(l:cmake_gen, utils#gen#make#getGeneratorName()) != -1
        return utils#gen#make#getTargets(a:build_dir)
    endif
    return []
endfunction

" Returns the cmake build command for CMake generator
" Returns empty string if CMake generator is not supported
function! utils#gen#common#getBuildCommand(build_dir, target, make_arguments) abort
    let l:cmake_gen = ''
    let l:cmake_info = utils#cmake#common#getInfo()
    if !empty(l:cmake_info)
        let l:cmake_gen = l:cmake_info['cmake']['generator']
    endif
    if (l:cmake_gen ==# '' && has('win32')) || stridx(l:cmake_gen, utils#gen#vs#getGeneratorName()) != -1
        return utils#gen#vs#getBuildCommand(a:build_dir, a:target, a:make_arguments)
    elseif stridx(l:cmake_gen, utils#gen#ninja#getGeneratorName()) != -1
        return utils#gen#ninja#getBuildCommand(a:build_dir, a:target, a:make_arguments)
    elseif stridx(l:cmake_gen, utils#gen#make#getGeneratorName()) != -1
        return utils#gen#make#getBuildCommand(a:build_dir, a:target, a:make_arguments)
    endif
    return ''
endfunction
