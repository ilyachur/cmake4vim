" autoload/utils/config/vimspector.vim - contains functions to generate vimspector config
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

" Private functions {{{ "
" Returns the path to vimspector config
function! s:getVimspectorConfig() abort
    return getcwd() . '/.vimspector.json'
endfunction

function! s:readVimspectorConfig() abort
    try
        return json_decode(join(readfile(s:getVimspectorConfig()), ''))
    catch
        call utils#common#Warning( 'Exception reading vimspector config: ' . v:exception )
        return {}
    endtry
endfunction

function! s:writeJson(json_content) abort
    " Apply pretty format if vim supports python3 (vimspector requires py3)
    if has('python3')
py3 << EOF
import json
with open( vim.eval('s:getVimspectorConfig()'), 'w' ) as vimspector_json:
    sorted_content = json.dump(vim.eval('a:json_content'), vimspector_json, indent=4, sort_keys=True)
EOF
    else " nvim doesn't have python3
        silent call writefile( [ json_encode( a:json_content ) ], s:getVimspectorConfig() )
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
    let l:result = {'app': '', 'args': []}
    if filereadable(s:getVimspectorConfig())
        let l:config = utils#config#vimspector#updateConfig({})
        if !empty(l:config)
            let l:conf = l:config['configurations']
            if has_key(l:conf, a:target) && has_key(l:conf[a:target], 'configuration')
                let l:result['app' ] = get( l:conf[a:target]['configuration'], 'program', l:result['app' ] )
                let l:result['args'] = get( l:conf[a:target]['configuration'], 'args'   , l:result['args'] )
            endif
        endif
    endif
    return l:result
endfunction
