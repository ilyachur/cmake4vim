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
        return {}
    endtry
endfunction

function! s:writeVimspectorConfig(content) abort
    let l:config = s:getVimspectorConfig()
    new setlocal buftype=nofile bufhidden=hide noswapfile nobuflisted
    put=a:content
    execute 'w! ' l:config
    q!
endfunction

function! s:writeJson(json_content) abort
    let l:result = json_encode(a:json_content)
    " Apply pretty format if vim supports python3 (vimspector requires py3)
    if has('python3')
py3 << EOF
import vim
import json
try:
    json_content = vim.eval("l:result")
    content = json.loads(json_content)
    sorted_content = json.dumps(content, indent=4, sort_keys=True)
    sorted_content = sorted_content.split('\n')
    print(sorted_content)
    vim.command("let l:result = " + str(sorted_content))
except Exception as e:
    print(e)
EOF
        if type(l:result) == type([])
            let l:result = join(l:result, "\n")
        endif
    endif

    call s:writeVimspectorConfig(l:result)
endfunction

function! s:generateEmptyVimspectorConfig() abort
    let l:config = {}
    let l:config['configurations'] = {}
    call s:writeJson(l:config)
endfunction

function! s:createNewTarget() abort
    let l:configuration = {}
    let l:configuration['type'] = ''
    let l:configuration['request'] = 'launch'
    let l:configuration['cwd'] = '${workspaceRoot}'
    let l:configuration['Mimode'] = ''
    let l:configuration['args'] = []
    let l:configuration['program'] = ''

    let l:config = {}
    let l:config['adapter'] = ''
    let l:config['configuration'] = l:configuration

    return l:config
endfunction

function! s:updateConfig(vimspector_config, targets_config) abort
    let l:res_config = a:vimspector_config
    for [target, config] in items(a:targets_config)
        if !has_key(l:res_config, target)
            let l:res_config[target] = s:createNewTarget()
        endif
        " Each target should have configuration section
        if !has_key(l:res_config[target], 'configuration') || !has_key(config, 'app') || !has_key(config, 'args')
            return {}
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
    if !g:cmake_gen_vimspector
        return {}
    endif
    if !filereadable(s:getVimspectorConfig())
        call s:generateEmptyVimspectorConfig()
    endif
    let l:vimspector_config = s:readVimspectorConfig()
    if has_key(l:vimspector_config, 'configurations')
        let l:vimspector_config['configurations'] = s:updateConfig(l:vimspector_config['configurations'], a:config)
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
                if has_key(l:conf[a:target]['configuration'], 'program')
                    let l:result['app'] = l:conf[a:target]['configuration']['program']
                endif
                if has_key(l:conf[a:target]['configuration'], 'args')
                    let l:result['args'] = l:conf[a:target]['configuration']['args']
                endif
            endif
        endif
    endif
    return l:result
endfunction
