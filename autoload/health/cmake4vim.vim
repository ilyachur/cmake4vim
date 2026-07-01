" autoload/health/cmake4vim.vim - :checkhealth cmake4vim provider (Neovim)
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

function! s:start(name) abort
    call v:lua.vim.health.start(a:name)
endfunction

function! s:ok(msg) abort
    call v:lua.vim.health.ok(a:msg)
endfunction

function! s:info(msg) abort
    call v:lua.vim.health.info(a:msg)
endfunction

function! s:warn(msg) abort
    call v:lua.vim.health.warn(a:msg)
endfunction

function! s:error(msg) abort
    call v:lua.vim.health.error(a:msg)
endfunction

function! health#cmake4vim#check() abort
    call s:start('cmake4vim')

    " cmake
    if !executable(g:cmake_executable)
        call s:error(printf('cmake executable "%s" was not found', g:cmake_executable))
        return
    endif
    let l:version = utils#cmake#version#getVersion()
    let l:version_str = join(l:version, '.')
    if utils#cmake#version#verNewerOrEq([3, 21])
        call s:ok(printf('cmake %s (>= 3.21 required)', l:version_str))
    else
        call s:warn(printf('cmake %s is older than the required 3.21', l:version_str))
    endif

    " ctest ships with cmake but check explicitly
    if executable('ctest')
        call s:ok('ctest found')
    else
        call s:warn('ctest was not found (:CTest will not work)')
    endif

    " ninja is optional but recommended
    if executable('ninja')
        call s:ok('ninja found')
    else
        call s:info('ninja was not found (optional, needed for the Ninja generators)')
    endif

    " Active configuration
    if !empty(g:cmake_configure_preset)
        call s:info('configure preset: ' . g:cmake_configure_preset)
    elseif !empty(g:cmake_selected_kit)
        call s:info('selected kit: ' . g:cmake_selected_kit)
    endif
    if !empty(g:cmake_build_target)
        call s:info('build target: ' . g:cmake_build_target)
    endif

    " Preset files
    if utils#cmake#presets#hasPresets()
        call s:ok('CMakePresets.json detected')
    endif
endfunction
