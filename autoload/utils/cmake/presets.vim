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

" Read includes relative to their containing file. A completed file may be
" included again, but a file on the current include chain would form a cycle.
function! s:loadFile(file, all, loaded, chain) abort
    let l:file = simplify(fnamemodify(a:file, ':p'))
    if index(a:chain, l:file) >= 0
        throw 'cmake4vim: cyclic preset include'
    endif
    if has_key(a:loaded, l:file)
        return
    endif
    let l:data = json_decode(join(readfile(l:file), "\n"))
    let l:context = {'file': l:file, 'includeVersion': l:data.version}
    for l:include in get(l:data, 'include', [])
        let l:path = l:data.version >= 7 ? s:expandMacros(l:include, l:context, [], l:file) : l:include
        if l:path !~# '^[/\\]' && l:path !~# '^\a:[/\\]'
            let l:path = fnamemodify(l:file, ':h') . '/' . l:path
        endif
        call s:loadFile(l:path, a:all, a:loaded, a:chain + [l:file])
    endfor
    for l:preset in get(l:data, 'configurePresets', [])
        if has_key(a:all, l:preset.name)
            throw 'cmake4vim: duplicate configure preset'
        endif
        let a:all[l:preset.name] = {'preset': l:preset, 'file': l:file, 'version': l:data.version}
    endfor
    let a:loaded[l:file] = 1
endfunction

function! s:loadConfigurePresets() abort
    let l:presets = {}
    let l:loaded = {}
    for l:file in ['CMakePresets.json', 'CMakeUserPresets.json']
        if filereadable(l:file)
            call s:loadFile(l:file, l:presets, l:loaded, [])
        endif
    endfor
    return l:presets
endfunction

" Resolve only fields needed for binaryDir. Environment entries inherit
" individually; null blocks inherited values and falls back to the process.
function! s:resolveConfigure(name, all, chain) abort
    if !has_key(a:all, a:name) || index(a:chain, a:name) >= 0
        throw 'cmake4vim: missing or cyclic configure preset'
    endif
    let l:entry = a:all[a:name]
    let l:preset = l:entry.preset
    let l:inherits = get(l:preset, 'inherits', [])
    if type(l:inherits) == v:t_string
        let l:inherits = [l:inherits]
    endif
    let l:result = {'environment': {}, 'envFiles': {}}
    for l:parent in reverse(copy(l:inherits))
        let l:base = s:resolveConfigure(l:parent, a:all, a:chain + [a:name])
        call extend(l:result.environment, remove(l:base, 'environment'))
        call extend(l:result.envFiles, remove(l:base, 'envFiles'))
        call extend(l:result, l:base)
    endfor
    for l:field in ['binaryDir', 'generator']
        if has_key(l:preset, l:field)
            let l:result[l:field] = l:preset[l:field]
        endif
    endfor
    " Version 12 expands fileDir at the field's origin; older schemas use
    " the file defining the selected preset, including for inherited fields.
    if has_key(l:preset, 'binaryDir')
        let l:result.binaryFile = l:entry.version >= 12 ? l:entry.file : ''
    endif
    call extend(l:result.environment, get(l:preset, 'environment', {}))
    for l:name in keys(get(l:preset, 'environment', {}))
        let l:result.envFiles[l:name] = l:entry.version >= 12 ? l:entry.file : ''
    endfor
    return l:result
endfunction

function! s:parentEnvironment(name) abort
    let l:value = getenv(a:name)
    return l:value is v:null ? '' : l:value
endfunction

function! s:expandMacro(namespace, name, context, chain, file) abort
    let l:include_version = get(a:context, 'includeVersion', 0)
    if l:include_version && (a:namespace ==# 'env' || (empty(a:namespace) && index(['presetName', 'generator'], a:name) >= 0)
                \ || (l:include_version < 9 && a:namespace !=# 'penv'))
        throw 'cmake4vim: unsupported include macro'
    endif
    if a:namespace ==# 'penv'
        return s:parentEnvironment(a:name)
    elseif a:namespace ==# 'env'
        let l:value = get(a:context.environment, a:name, v:null)
        if l:value is v:null
            return s:parentEnvironment(a:name)
        endif
        if index(a:chain, a:name) >= 0
            throw 'cmake4vim: cyclic preset environment'
        endif
        let l:file = get(a:context.envFiles, a:name, '')
        return s:expandMacros(l:value, a:context, a:chain + [a:name], empty(l:file) ? a:context.file : l:file)
    elseif !empty(a:namespace)
        throw 'cmake4vim: unsupported preset macro'
    endif
    let l:source_dir = getcwd()
    let l:macros = {
        \ 'sourceDir': l:source_dir,
        \ 'sourceParentDir': fnamemodify(l:source_dir, ':h'),
        \ 'sourceDirName': fnamemodify(l:source_dir, ':t'),
        \ 'presetName': get(a:context, 'name', ''),
        \ 'generator': get(a:context, 'generator', ''),
        \ 'fileDir': fnamemodify(a:file, ':h'),
        \ 'dollar': '$',
        \ 'pathListSep': has('win32') ? ';' : ':'}
    if a:name ==# 'hostSystemName'
        return has('win32') ? 'Windows' : trim(system('uname -s'))
    endif
    if !has_key(l:macros, a:name)
        throw 'cmake4vim: unknown preset macro'
    endif
    return l:macros[a:name]
endfunction

" Expand each original token once: literal dollars and process environment
" values must not accidentally become new macros during later replacements.
function! s:expandMacros(value, context, chain, file) abort
    return substitute(a:value, '\$\(\w*\){\([^}]*\)}',
        \ '\=s:expandMacro(submatch(1), submatch(2), a:context, a:chain, a:file)', 'g')
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
    try
        let l:all = s:loadConfigurePresets()
        let l:resolved = s:resolveConfigure(a:name, l:all, [])
        let l:resolved.name = a:name
        let l:resolved.file = l:all[a:name].file
        let l:file = get(l:resolved, 'binaryFile', '')
        let l:binary_dir = s:expandMacros(get(l:resolved, 'binaryDir', getcwd()),
            \ l:resolved, [], empty(l:file) ? l:resolved.file : l:file)
        " CMake interprets relative paths (and an omitted binaryDir) at the source.
        return simplify(fnamemodify((empty(l:binary_dir) ? getcwd() : l:binary_dir) . '/', ':p:h'))
    catch
        return ''
    endtry
endfunction
