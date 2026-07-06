" autoload/gen/common.vim - contains common helpers for CMake generators
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

" Private functions {{{ "
function! s:getCMakeGenerator() abort
    let l:cmake_gen = ''
    let l:cmake_info = utils#cmake#common#getInfo()
    if !empty(l:cmake_info)
        let l:cmake_gen = l:cmake_info['cmake']['generator']
    endif

    return l:cmake_gen
endfunction

function! s:restoreCMakeGenerator() abort
    let l:cmake_gen = s:getCMakeGenerator()
    " Need to restore cmake_generator for case when plugin changes make
    " command
    if empty(l:cmake_gen)
        " By default win32 CMakeGenerator should be VS, other systems make
        if has('win32')
            let l:cmake_gen = 'Visual Studio'
        else
            let l:cmake_gen = 'Make'
        endif
    endif
    return l:cmake_gen
endfunction
" }}} Private functions "

" Returns the CMake generator that is (or will be) used, falling back to the
" platform default when it cannot be detected yet
function! utils#gen#common#getGenerator() abort
    return s:restoreCMakeGenerator()
endfunction

" Returns 1 if the generator is a multi-config one (build type is chosen at
" build time via --config, not at configure time via CMAKE_BUILD_TYPE)
function! utils#gen#common#isMultiConfig(generator) abort
    return a:generator =~# 'Visual Studio'
                \ || a:generator ==# 'Xcode'
                \ || a:generator =~# 'Multi-Config'
endfunction

" Returns 1 if the generator can emit compile_commands.json. Only the
" Makefile and Ninja generators support CMAKE_EXPORT_COMPILE_COMMANDS. Match
" 'Make' (not 'Makefiles') so the generic make fallback name is covered too.
function! utils#gen#common#supportsCompileCommands(generator) abort
    return a:generator =~# 'Make' || a:generator =~# 'Ninja'
endfunction

" Returns the default target for current CMake generator
" If Generator is not supported returns default target for Unix Makefiles
" Returns empty string if CMake generator is not supported
function! utils#gen#common#getDefaultTarget() abort
    let l:cmake_gen = s:restoreCMakeGenerator()
    if stridx(l:cmake_gen, utils#gen#vs#getGeneratorName()) != -1
        return utils#gen#vs#getDefaultTarget()
    elseif stridx(l:cmake_gen, utils#gen#ninja#getGeneratorName()) != -1
        return utils#gen#ninja#getDefaultTarget()
    elseif stridx(l:cmake_gen, utils#gen#make#getGeneratorName()) != -1
        return utils#gen#make#getDefaultTarget()
    endif
endfunction

" Returns the clean target for CMake generator
" Returns empty string if CMake generator is not supported
function! utils#gen#common#getCleanTarget() abort
    let l:cmake_gen = s:getCMakeGenerator()
    if stridx(l:cmake_gen, utils#gen#vs#getGeneratorName()) != -1
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
    let l:cmake_gen = s:getCMakeGenerator()
    if stridx(l:cmake_gen, utils#gen#vs#getGeneratorName()) != -1
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
function! utils#gen#common#getBuildCommand(build_dir, target, cmake_build_args, make_arguments) abort
    let l:cmake_gen = s:restoreCMakeGenerator()
    if stridx(l:cmake_gen, utils#gen#vs#getGeneratorName()) != -1
        return utils#gen#vs#getBuildCommand(a:build_dir, a:target, a:cmake_build_args, a:make_arguments)
    elseif stridx(l:cmake_gen, utils#gen#ninja#getGeneratorName()) != -1
        return utils#gen#ninja#getBuildCommand(a:build_dir, a:target, a:cmake_build_args, a:make_arguments)
    elseif stridx(l:cmake_gen, utils#gen#make#getGeneratorName()) != -1
        return utils#gen#make#getBuildCommand(a:build_dir, a:target, a:cmake_build_args, a:make_arguments)
    endif
endfunction

" Returns the cmake target for a single source file
function! utils#gen#common#getSingleUnitTargetName( generator, filename ) abort
    if a:generator =~# 'Unix Makefiles'
        " make replaces all spaces with underscores in filepaths when creating build targets
        return fnameescape( substitute( fnamemodify( a:filename, ':r' ) . '.o', ' ', '_', 'g' ) )
    elseif a:generator =~# 'Ninja'
        " Matches both 'Ninja' and the multi-config 'Ninja Multi-Config'
        return fnameescape( fnamemodify( a:filename, ':p' ) . '^' )
    endif

    call utils#common#Warning('Generator not supported for building single unit!')
    return ''
endfunction
