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

function! s:writeJson(json_content) abort
    " Apply pretty format if vim supports python3 (vimspector requires py3).
    " The python3 branch keeps the original key order and carries over '//' and
    " '/* */' comments from the previous file content, attaching each comment to
    " the JSON path (including array indices) of the key it belongs to.
    if has('python3')
py3 << EOF
import json
import os
import vim
from collections import OrderedDict


# Scan text line by line, tracking the JSON path. For every line it reports the
# stripped code, the comment (if any), the paths of the keys declared on it and
# the paths of the containers whose closing bracket appears on it. Paths are
# tuples of dict keys and array indices, so every position is unique.
def _scan_lines(text):
    stack = []
    pending = None
    last_str = None
    in_string = escaped = in_block = False
    cur = []
    results = []
    for raw in text.split('\n'):
        block_start = in_block
        code = []
        comment = []
        keys = []
        closes = []
        i, n = 0, len(raw)
        while i < n:
            ch = raw[i]
            if in_block:
                if ch == '*' and i + 1 < n and raw[i + 1] == '/':
                    comment.append('*/')
                    in_block = False
                    i += 2
                    continue
                comment.append(ch)
                i += 1
                continue
            if in_string:
                code.append(ch)
                if escaped:
                    escaped = False
                    cur.append(ch)
                elif ch == '\\':
                    escaped = True
                    cur.append(ch)
                elif ch == '"':
                    in_string = False
                    last_str = ''.join(cur)
                else:
                    cur.append(ch)
                i += 1
                continue
            if ch == '"':
                in_string = True
                cur = []
                code.append(ch)
                i += 1
                continue
            if ch == '/' and i + 1 < n and raw[i + 1] == '/':
                comment.append(raw[i:])
                break
            if ch == '/' and i + 1 < n and raw[i + 1] == '*':
                in_block = True
                comment.append('/*')
                i += 2
                continue
            if ch in '{[':
                parent = stack[-1] if stack else None
                if parent is not None and parent['type'] == 'array':
                    component = parent['idx']
                elif pending is not None:
                    component = pending
                else:
                    component = None
                parent_path = parent['path'] if parent is not None else ()
                path = parent_path + (component,) if component is not None else parent_path
                stack.append({'type': 'dict' if ch == '{' else 'array',
                              'path': path, 'idx': 0})
                pending = None
                last_str = None
                code.append(ch)
                i += 1
                continue
            if ch in '}]':
                if stack:
                    closes.append(stack.pop()['path'])
                pending = None
                last_str = None
                code.append(ch)
                i += 1
                continue
            if ch == ':':
                if last_str is not None:
                    parent_path = stack[-1]['path'] if stack else ()
                    pending = last_str
                    keys.append(parent_path + (last_str,))
                    last_str = None
                code.append(ch)
                i += 1
                continue
            if ch == ',':
                last_str = None
                if stack and stack[-1]['type'] == 'array':
                    stack[-1]['idx'] += 1
                code.append(ch)
                i += 1
                continue
            code.append(ch)
            i += 1
        results.append({
            'raw': raw,
            'code': ''.join(code).strip(),
            'comment': ''.join(comment).strip(),
            'keys': keys,
            'closes': closes,
            'block_start': block_start,
        })
    return results


# Strip '//' and '/* */' comments, reusing the single tokenizer in _scan_lines
# so the read and write paths can never disagree on what a comment is.
def _strip_json_comments(text):
    return '\n'.join(line['code'] for line in _scan_lines(text))


def _flush_buffered(buffered):
    # Drop blank lines that trail the group right before its anchor.
    while buffered and not buffered[-1].strip():
        buffered.pop()
    return buffered


def _extract_comments(text):
    # leading[path]        comments printed above the key's line
    # inline[path]         comment appended to the key's line
    # trailing[container]  comments printed just before the container's close
    # close_inline[cont]   comment appended to the container's closing line
    leading = {}
    inline = {}
    trailing = {}
    close_inline = {}
    buffered = []
    for line in _scan_lines(text):
        if line['keys']:
            if _flush_buffered(buffered):
                leading.setdefault(line['keys'][0], []).extend(buffered)
            buffered = []
            if line['comment']:
                inline[line['keys'][-1]] = line['comment']
        elif line['closes']:
            # A structural line (closing bracket). Comments buffered before it
            # belong to the container being closed, not to the next sibling key.
            if _flush_buffered(buffered):
                trailing.setdefault(line['closes'][0], []).extend(buffered)
            buffered = []
            if line['comment']:
                close_inline[line['closes'][-1]] = line['comment']
        elif line['comment'] and not line['code']:
            # Keep the original line (with its leading whitespace) so the
            # relative indentation can be restored on write.
            buffered.append(line['raw'].rstrip())
        elif not line['code'] and not line['comment'] and (line['block_start'] or buffered):
            # Blank line inside a commented out block: keep the formatting
            buffered.append('')
    return leading, inline, trailing, close_inline


def _emit_group(out, group, indent):
    # Drop the common leading whitespace and re-indent the whole group to the
    # anchor, keeping the relative indentation between its lines. Blank lines are
    # emitted empty and ignored when measuring the base.
    base = min((len(c) - len(c.lstrip()) for c in group if c.strip()), default=0)
    for comment in group:
        out.append(indent + comment[base:] if comment.strip() else '')


def _reinsert_comments(body, leading, inline, trailing, close_inline):
    if not (leading or inline or trailing or close_inline):
        return body
    out = []
    for line in _scan_lines(body):
        raw = line['raw']
        indent = raw[:len(raw) - len(raw.lstrip())]
        if line['closes'] and line['closes'][0] in trailing:
            # Trailing comments sit inside the container, one level deeper than
            # its closing bracket.
            _emit_group(out, trailing[line['closes'][0]], indent + '    ')
        if line['keys'] and line['keys'][0] in leading:
            _emit_group(out, leading[line['keys'][0]], indent)
        suffix = ''
        if line['keys'] and line['keys'][-1] in inline:
            suffix = ' ' + inline[line['keys'][-1]]
        elif line['closes'] and line['closes'][-1] in close_inline:
            suffix = ' ' + close_inline[line['closes'][-1]]
        out.append(raw + suffix)
    return '\n'.join(out)


# Rebuild the object taking values from the freshly generated config while
# keeping the key order of the previous file; brand new keys are appended in a
# stable sorted order so a fresh config is written deterministically.
def _merge_order(new_value, old_value):
    if isinstance(new_value, dict):
        old_value = old_value if isinstance(old_value, dict) else {}
        result = OrderedDict()
        for key in old_value:
            if key in new_value:
                result[key] = _merge_order(new_value[key], old_value[key])
        for key in sorted(k for k in new_value if k not in result):
            result[key] = _merge_order(new_value[key], None)
        return result
    return new_value


def _warn(message):
    vim.command("call utils#common#Warning('" + message.replace("'", "''") + "')")


_cfg_path = vim.eval('s:getVimspectorConfig()')
_new_obj = vim.eval('a:json_content')
_old_raw = ''
if os.path.exists(_cfg_path):
    try:
        with open(_cfg_path, encoding='utf-8') as _f:
            _old_raw = _f.read()
    except Exception as _e:
        _warn('Could not read existing vimspector config: ' + str(_e))

try:
    _old_obj = (json.loads(_strip_json_comments(_old_raw), object_pairs_hook=OrderedDict)
                if _old_raw.strip() else None)
except Exception:
    _old_obj = None

# ensure_ascii=False keeps non-ASCII keys/values literal so they match the
# comment paths extracted from the original (UTF-8) file.
_body = json.dumps(_merge_order(_new_obj, _old_obj), indent=4, ensure_ascii=False)

try:
    _body = _reinsert_comments(_body, *_extract_comments(_old_raw))
except Exception as _e:
    _warn('Could not preserve comments in vimspector config: ' + str(_e))

with open(_cfg_path, 'w', encoding='utf-8') as _f:
    _f.write(_body)
EOF
    else " nvim doesn't have python3
        silent call writefile([json_encode(a:json_content)], s:getVimspectorConfig())
    endif

    let l:bufnr = bufnr('.vimspector.json')
    if  l:bufnr != -1
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
            let l:res_config[target] = g:cmake_vimspector_default_configuration
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
