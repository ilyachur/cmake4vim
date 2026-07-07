" autoload/utils/cmake/presets.vim - CMakePresets.json support
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>
"
" Preset names are listed through `cmake --list-presets`, so CMake itself
" resolves `hidden`, `inherits` and conditions. The binary directory of a
" configure preset is resolved by parsing the preset files, because CMake does
" not expose it on the command line and the plugin needs it up front to place
" the file API query.

" Private functions {{{ "

" Lists preset names of the given type ('configure', 'build', 'test',
" 'package') using `cmake --list-presets[=<type>]`.
function! s:listPresets(type) abort
    let l:flag = a:type ==# 'configure' ? '--list-presets' : '--list-presets=' . a:type
    let l:out = system(printf('%s %s', g:cmake_executable, l:flag))
    if v:shell_error != 0
        return []
    endif
    let l:names = []
    for l:line in split(l:out, "\n")
        let l:matched = matchlist(l:line, '^\s*"\(.\{-}\)"')
        if !empty(l:matched)
            call add(l:names, l:matched[1])
        endif
    endfor
    return l:names
endfunction

" Loads configurePresets from CMakePresets.json and CMakeUserPresets.json into
" a dictionary keyed by preset name. The `include` field is not expanded.
function! s:loadConfigurePresets() abort
    let l:presets = {}
    for l:file in ['CMakePresets.json', 'CMakeUserPresets.json']
        if !filereadable(l:file)
            continue
        endif
        try
            let l:data = json_decode(join(readfile(l:file), "\n"))
        catch
            continue
        endtry
        for l:preset in get(l:data, 'configurePresets', [])
            if has_key(l:preset, 'name')
                let l:presets[l:preset['name']] = l:preset
            endif
        endfor
    endfor
    return l:presets
endfunction

" Resolves a configure preset applying `inherits` (child overrides parent,
" earlier parents override later ones).
function! s:resolveConfigure(name, all) abort
    if !has_key(a:all, a:name)
        return {}
    endif
    let l:preset = a:all[a:name]
    let l:inherits = get(l:preset, 'inherits', [])
    if type(l:inherits) == v:t_string
        let l:inherits = [l:inherits]
    endif

    let l:result = {}
    for l:parent in reverse(copy(l:inherits))
        call extend(l:result, s:resolveConfigure(l:parent, a:all))
    endfor
    call extend(l:result, l:preset)
    return l:result
endfunction

" Expands the subset of preset macros that can appear in binaryDir.
function! s:expandMacros(value, name, source_dir, generator) abort
    let l:result = a:value
    let l:result = substitute(l:result, '${sourceDir}', escape(a:source_dir, '\&~'), 'g')
    let l:result = substitute(l:result, '${sourceParentDir}', escape(fnamemodify(a:source_dir, ':h'), '\&~'), 'g')
    let l:result = substitute(l:result, '${sourceDirName}', escape(fnamemodify(a:source_dir, ':t'), '\&~'), 'g')
    let l:result = substitute(l:result, '${presetName}', escape(a:name, '\&~'), 'g')
    let l:result = substitute(l:result, '${generator}', escape(a:generator, '\&~'), 'g')
    let l:result = substitute(l:result, '${hostSystemName}', escape(substitute(system('uname -s'), '\n', '', 'g'), '\&~'), 'g')
    let l:result = substitute(l:result, '$penv{\([^}]\+\)}', '\=getenv(submatch(1)) isnot v:null ? getenv(submatch(1)) : ""', 'g')
    let l:result = substitute(l:result, '$env{\([^}]\+\)}', '\=getenv(submatch(1)) isnot v:null ? getenv(submatch(1)) : ""', 'g')
    let l:result = substitute(l:result, '${dollar}', '$', 'g')
    return l:result
endfunction
" }}} Private functions "

" Returns 1 if the current directory contains a preset file
function! utils#cmake#presets#hasPresets() abort
    return filereadable('CMakePresets.json') || filereadable('CMakeUserPresets.json')
endfunction

function! utils#cmake#presets#getConfigurePresets() abort
    return s:listPresets('configure')
endfunction

function! utils#cmake#presets#getBuildPresets() abort
    return s:listPresets('build')
endfunction

function! utils#cmake#presets#getTestPresets() abort
    return s:listPresets('test')
endfunction

function! utils#cmake#presets#getWorkflowPresets() abort
    return s:listPresets('workflow')
endfunction

" Resolves the absolute binary directory of a configure preset
function! utils#cmake#presets#getConfigureBinaryDir(name) abort
    let l:all = s:loadConfigurePresets()
    let l:resolved = s:resolveConfigure(a:name, l:all)
    if empty(l:resolved)
        return ''
    endif

    let l:source_dir = getcwd()
    let l:generator  = get(l:resolved, 'generator', '')
    let l:binary_dir = get(l:resolved, 'binaryDir', l:source_dir . '/build')
    let l:binary_dir = s:expandMacros(l:binary_dir, a:name, l:source_dir, l:generator)
    " Make absolute without dropping the last path component (':h' would)
    let l:binary_dir = fnamemodify(l:binary_dir, ':p')
    return substitute(l:binary_dir, '[\\/]$', '', '')
endfunction
