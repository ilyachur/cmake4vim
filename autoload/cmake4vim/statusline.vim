" autoload/cmake4vim/statusline.vim - lightweight getters for status lines
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>
"
" These functions are meant to be cheap enough to call on every redraw, so
" they avoid spawning cmake and only read already collected information.

" Returns 1 if the current directory looks like a CMake project
function! cmake4vim#statusline#IsCMakeProject() abort
    return filereadable('CMakeLists.txt')
                \ || !empty(g:cmake_configure_preset)
                \ || utils#cmake#presets#hasPresets()
endfunction

" Returns the currently selected build target
function! cmake4vim#statusline#GetBuildTarget() abort
    return g:cmake_build_target
endfunction

" Returns the currently selected/detected build type (configuration)
function! cmake4vim#statusline#GetBuildType() abort
    if !empty(g:cmake_build_type)
        return g:cmake_build_type
    endif
    let l:info = utils#cmake#common#getInfo()
    return !empty(l:info) ? get(l:info['cmake'], 'build_type', '') : ''
endfunction

" Returns the currently selected kit
function! cmake4vim#statusline#GetKit() abort
    return g:cmake_selected_kit
endfunction

" Returns the currently selected configure preset
function! cmake4vim#statusline#GetConfigurePreset() abort
    return g:cmake_configure_preset
endfunction

" Returns a compact one-line summary suitable for a status line, e.g.
" 'CMake[preset:default Debug test_app]'. Returns an empty string when the
" current directory is not a CMake project.
function! cmake4vim#statusline#Status() abort
    if !cmake4vim#statusline#IsCMakeProject()
        return ''
    endif

    let l:parts = []
    if !empty(g:cmake_configure_preset)
        call add(l:parts, 'preset:' . g:cmake_configure_preset)
    elseif !empty(g:cmake_selected_kit)
        call add(l:parts, 'kit:' . g:cmake_selected_kit)
    endif

    let l:build_type = cmake4vim#statusline#GetBuildType()
    if !empty(l:build_type)
        call add(l:parts, l:build_type)
    endif

    if !empty(g:cmake_build_target)
        call add(l:parts, g:cmake_build_target)
    endif

    return empty(l:parts) ? 'CMake' : 'CMake[' . join(l:parts, ' ') . ']'
endfunction
