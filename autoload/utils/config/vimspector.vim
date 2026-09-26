" autoload/utils/config/vimspector.vim - contains functions to generate vimspector config
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

" Private functions {{{ "
" Returns the path to vimspector config
function! s:getVimspectorConfig() abort
    return getcwd() . '/.vimspector.json'
endfunction

" Strips '//' line comments and '/* */' block comments (both allowed by
" vimspector) so that json_decode can parse the config. Comment markers inside
" JSON strings are preserved, so values like URLs or Windows paths are kept
" intact. Block comments may span multiple lines.
function! s:stripJsonComments(lines) abort
    let l:result = []
    let l:in_string = 0
    let l:escaped = 0
    let l:in_block = 0
    for l:line in a:lines
        let l:out = ''
        let l:i = 0
        let l:len = strlen(l:line)
        while l:i < l:len
            let l:ch = l:line[l:i]
            if l:in_block
                if l:ch ==# '*' && l:i + 1 < l:len && l:line[l:i + 1] ==# '/'
                    let l:in_block = 0
                    let l:i += 2
                    continue
                endif
                let l:i += 1
                continue
            elseif l:in_string
                let l:out .= l:ch
                if l:escaped
                    let l:escaped = 0
                elseif l:ch ==# '\'
                    let l:escaped = 1
                elseif l:ch ==# '"'
                    let l:in_string = 0
                endif
            elseif l:ch ==# '"'
                let l:in_string = 1
                let l:out .= l:ch
            elseif l:ch ==# '/' && l:i + 1 < l:len && l:line[l:i + 1] ==# '/'
                " The rest of the line is a comment
                break
            elseif l:ch ==# '/' && l:i + 1 < l:len && l:line[l:i + 1] ==# '*'
                let l:in_block = 1
                let l:i += 2
                continue
            else
                let l:out .= l:ch
            endif
            let l:i += 1
        endwhile
        call add(l:result, l:out)
    endfor
    return l:result
endfunction

function! s:readVimspectorConfig() abort
    try
        let l:lines = s:stripJsonComments(readfile(s:getVimspectorConfig()))
        return json_decode(join(l:lines, ''))
    catch
        call utils#common#Warning('Exception reading vimspector config: ' . v:exception)
        return {}
    endtry
endfunction

" Keep byte offsets into the original JSONC text; comments are never edits.
function! s:jsonTokens(text) abort
    let l:tokens = []
    let l:pos = 0
    let l:pattern = '\%(\_s\|\r\)\+\|//.\{-}\ze\%(\n\|$\)\|/\*\_.\{-}\*/\|"\%([^"\\]\|\\.\)*"\|[{}\[\],:]' .
                \ '\|-\=\d\+\%(\.\d\+\)\=\%([eE][+-]\=\d\+\)\=\|true\|false\|null'
    while l:pos < strlen(a:text)
        let [l:value, l:start, l:end] = matchstrpos(a:text, l:pattern, l:pos)
        if l:start != l:pos
            throw 'Unsupported JSON token'
        endif
        if l:value !~# '^\%(\_s\|\r\)' && l:value !~# '^/[/\*]'
            call add(l:tokens, {'text': l:value, 'start': l:start, 'end': l:end})
        endif
        let l:pos = l:end
    endwhile
    return l:tokens
endfunction

function! s:jsonNode(state) abort
    let l:first = a:state.pos
    let l:token = a:state.tokens[l:first].text
    let a:state.pos += 1
    let l:children = []
    if l:token ==# '{' || l:token ==# '['
        let l:close = l:token ==# '{' ? '}' : ']'
        while a:state.tokens[a:state.pos].text !=# l:close
            let l:key = len(l:children)
            if l:token ==# '{'
                let l:key = json_decode(a:state.tokens[a:state.pos].text)
                let a:state.pos += 2 " key and colon (input has already been decoded)
            endif
            let l:child = s:jsonNode(a:state)
            let l:child.key = l:key
            call add(l:children, l:child)
            if a:state.tokens[a:state.pos].text ==# ','
                let a:state.pos += 1
            endif
        endwhile
        let a:state.pos += 1
    endif
    return {'first': l:first, 'last': a:state.pos - 1, 'children': l:children, 'kind': l:token}
endfunction

function! s:jsonIndent(text, pos) abort
    return matchstr(split(strpart(a:text, 0, a:pos), "\n", 1)[-1], '^\s*')
endfunction

" Only new objects need formatting; existing text retains its own layout.
function! s:formatJson(value, indent, step) abort
    if type(a:value) != v:t_dict || empty(a:value)
        return json_encode(a:value)
    endif
    let l:lines = []
    for l:key in sort(keys(a:value))
        call add(l:lines, a:indent . a:step . json_encode(l:key) . ': ' .
                    \ s:formatJson(a:value[l:key], a:indent . a:step, a:step))
    endfor
    return "{\n" . join(l:lines, ",\n") . "\n" . a:indent . '}'
endfunction

function! s:patchJson(text, tokens, node, value, edits) abort
    let l:start = a:tokens[a:node.first].start
    let l:end = a:tokens[a:node.last].end
    let l:old = json_decode(join(s:stripJsonComments(split(strpart(a:text, l:start, l:end - l:start), "\n", 1)), "\n"))
    if type(l:old) == type(a:value) && l:old ==# a:value
        return
    endif
    if (a:node.kind ==# '{' && type(a:value) == v:t_dict) || (a:node.kind ==# '[' && type(a:value) == v:t_list)
        for l:child in a:node.children
            if type(a:value) == v:t_dict || l:child.key < len(a:value)
                call s:patchJson(a:text, a:tokens, l:child, a:value[l:child.key], a:edits)
            else
                " Removing array values must leave their surrounding comments intact.
                for l:index in range(l:child.first, l:child.last)
                    call add(a:edits, [a:tokens[l:index].start, a:tokens[l:index].end, ''])
                endfor
            endif
        endfor
        if type(a:value) == v:t_list && len(a:value) < len(a:node.children)
            for l:index in range(len(a:node.children) - 1)
                if l:index >= len(a:value) - 1
                    let l:comma = a:tokens[a:node.children[l:index].last + 1]
                    call add(a:edits, [l:comma.start, l:comma.end, ''])
                endif
            endfor
        endif
        let l:indent = s:jsonIndent(a:text, l:start)
        let l:step = matchstr(a:text, '\n\zs[ \t]\+\ze"')
        if empty(l:step)
            let l:step = '    '
        endif
        if !empty(a:node.children)
            let l:child_indent = s:jsonIndent(a:text, a:tokens[a:node.children[0].first].start)
            if strlen(l:child_indent) > strlen(l:indent)
                let l:step = strpart(l:child_indent, strlen(l:indent))
            endif
        endif
        let l:added = []
        if type(a:value) == v:t_dict
            for l:key in sort(keys(a:value))
                if !has_key(l:old, l:key)
                    call add(l:added, json_encode(l:key) . ': ' . s:formatJson(a:value[l:key], l:indent . l:step, l:step))
                endif
            endfor
        elseif len(a:value) > len(a:node.children)
            let l:added = map(copy(a:value[len(a:node.children):]), 'json_encode(v:val)')
        endif
        if !empty(l:added)
            let l:newline = stridx(a:text, "\r\n") >= 0 ? "\r\n" : "\n"
            let l:added = map(l:added, 'substitute(v:val, "\n", l:newline, "g")')
            let l:separator = l:newline . l:indent . l:step
            if !empty(a:node.children)
                let l:pos = a:tokens[a:node.children[-1].last].end
                call add(a:edits, [l:pos, l:pos, ','])
            endif
            " Append after existing comments, so an inline comment stays with its value.
            let l:pos = a:tokens[a:node.last].start
            let l:prefix = split(strpart(a:text, 0, l:pos), "\n", 1)[-1]
            let l:insert = l:indent . l:step . join(l:added, ',' . l:separator) . l:newline
            if l:prefix =~# '^[ \t]*$'
                let l:pos -= strlen(l:prefix)
            else
                let l:insert = l:newline . l:insert . l:indent
            endif
            if !empty(a:node.children) && l:pos == a:tokens[a:node.children[-1].last].end
                let a:edits[-1][2] .= l:insert
            else
                call add(a:edits, [l:pos, l:pos, l:insert])
            endif
        endif
    else
        call add(a:edits, [l:start, l:end, json_encode(a:value)])
    endif
endfunction

function! s:writeJson(json_content) abort
    let l:path = s:getVimspectorConfig()
    try
        if filereadable(l:path)
            let l:original = join(readfile(l:path, 'b'), "\n")
            let l:state = {'tokens': s:jsonTokens(l:original), 'pos': 0}
            let l:root = s:jsonNode(l:state)
            let l:edits = []
            call s:patchJson(l:original, l:state.tokens, l:root, a:json_content, l:edits)
            let l:body = l:original
            " Apply from the end so the original byte offsets remain valid.
            for l:edit in sort(l:edits, {left, right -> right[0] - left[0]})
                let l:body = strpart(l:body, 0, l:edit[0]) . l:edit[2] . strpart(l:body, l:edit[1])
            endfor
        else
            let l:original = ''
            let l:body = s:formatJson(a:json_content, '', '    ') . "\n"
        endif
        if json_decode(join(s:stripJsonComments(split(l:body, "\n", 1)), "\n")) !=# a:json_content
            throw 'Updated JSON does not match the requested configuration'
        endif
        if l:body !=# l:original
            call writefile(split(l:body, "\n", 1), l:path, 'b')
        endif
    catch
        call utils#common#Warning('Could not update vimspector config: ' . v:exception)
        return
    endtry
    let l:bufnr = bufnr('.vimspector.json')
    if l:bufnr != -1
        execute 'checktime ' . l:bufnr
    endif
endfunction

function! s:generateEmptyVimspectorConfig() abort
    let l:config = {}
    let l:config['configurations'] = {}
    call s:writeJson(l:config)
endfunction

function! s:updateConfig(vimspector_config, targets_config) abort
    let l:res_config = a:vimspector_config
    for [target, config] in items(a:targets_config)
        if !has_key(l:res_config, target)
            let l:res_config[target] = deepcopy(g:cmake_vimspector_default_configuration)
        endif
        " Each target should have configuration section
        if !has_key(l:res_config[target], 'configuration') || !has_key(config, 'app') || !has_key(config, 'args')
            throw 'Unsupported target configuration!'
        endif
        let l:res_config[target]['configuration']['program'] = config['app']
        let l:res_config[target]['configuration']['args'] = config['args']
    endfor
    return l:res_config
endfunction

function! s:normalizeWorkDir(cwd) abort
    let l:cwd = substitute(a:cwd, '${workspaceRoot}', getcwd(), 'g')
    return l:cwd
endfunction
" }}} Private functions "

" Config has the next format:
"     {
"           "target_name": {"app": "path", "args", [...]}
"     }
function! utils#config#vimspector#updateConfig(config) abort
    if !g:cmake_vimspector_support
        return {}
    endif
    if !filereadable(s:getVimspectorConfig())
        call s:generateEmptyVimspectorConfig()
    endif
    let l:vimspector_config = s:readVimspectorConfig()
    if has_key(l:vimspector_config, 'configurations')
        try
            let l:vimspector_config['configurations'] = s:updateConfig(l:vimspector_config['configurations'], a:config)
        catch
            let l:vimspector_config = {}
        endtry
    endif
    if !has_key(l:vimspector_config, 'configurations')
        call utils#common#Warning('Unsupported vimspector format!')
        return {}
    endif
    if !empty(a:config)
        call s:writeJson(l:vimspector_config)
    endif
    return l:vimspector_config
endfunction

function! utils#config#vimspector#getTargetConfig(target) abort
    let l:result = {'app': '', 'args': [], 'cwd': getcwd()}
    if filereadable(s:getVimspectorConfig())
        let l:config = utils#config#vimspector#updateConfig({})
        if !empty(l:config)
            let l:conf = l:config['configurations']
            if has_key(l:conf, a:target) && has_key(l:conf[a:target], 'configuration')
                let l:result['app'] = get(l:conf[a:target]['configuration'], 'program', l:result['app'])
                let l:result['args'] = get(l:conf[a:target]['configuration'], 'args', l:result['args'])
                let l:result['cwd'] = s:normalizeWorkDir(get(l:conf[a:target]['configuration'], 'cwd', l:result['cwd']))
            endif
        endif
    endif
    return l:result
endfunction
