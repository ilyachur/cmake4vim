" autoload/cmake4vim.vim - Cmake4vim common functionality
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

" Private functions {{{ "
function! s:getCMakeErrorFormat() abort
    return ' %#%f:%l %#(%m),'
                \ .'See also "%f".,'
                \ .'%E%>CMake Error at %f:%l:,'
                \ .'%Z  %m,'
                \ .'%E%>CMake Error at %f:%l (%[%^)]%#):,'
                \ .'%Z  %m,'
                \ .'%W%>Cmake Deprecation Warning at %f:%l (%[%^)]%#):,'
                \ .'%Z  %m,'
                \ .'%W%>Cmake Warning at %f:%l (%[%^)]%#):,'
                \ .'%Z  %m,'
                \ .'%E%>CMake Error: Error in cmake code at,'
                \ .'%C%>%f:%l:,'
                \ .'%Z%m,'
                \ .'%E%>CMake Error in %.%#:,'
                \ .'%C%>  %m,'
                \ .'%C%>,'
                \ .'%C%>    %f:%l (if),'
                \ .'%C%>,'
                \ .'%Z  %m,'
endfunction
" }}} Private functions
" Public functions {{{ "

" Completes CMake target names
function! cmake4vim#CompleteTarget(arg_lead, cmd_line, cursor_pos) abort
    let l:sorted_targets = cmake4vim#GetAllTargets()
    return join(l:sorted_targets, "\n")
endfunction

" Completes CMake build types
function! cmake4vim#CompleteBuildType(arg_lead, cmd_line, cursor_pos) abort
    return join( sort( keys( utils#cmake#getCMakeVariants() ), 'i' ), "\n")
endfunction

function! cmake4vim#CompleteKit(arg_lead, cmd_line, cursor_pos) abort
    return join(sort(keys(g:cmake_kits), 'i'), "\n")
endfunction

" Method remove build directory and reset the cmake cache
function! cmake4vim#ResetCMakeCache() abort
    let l:build_dir = utils#cmake#findBuildDir()
    if l:build_dir !=# ''
        call utils#fs#removeDirectory(l:build_dir)
    endif
    call utils#cmake#common#resetCache()
    echon 'Cmake cache was removed!'
endfunction

" Generates CMake project
" Additional cmake arguments can be passed as arguments of this function
function! cmake4vim#GenerateCMake(...) abort
    " Reset old cmake cache
    call utils#cmake#common#resetCache()
    " Creates build directory
    let l:build_dir = utils#cmake#getBuildDir()

    " Prepare requests to CMake system
    call utils#cmake#common#makeRequests(l:build_dir)

    " Generates a command for CMake
    let l:cmake_cmd = utils#cmake#getCMakeGenerationCommand(join(a:000))

    " For old CMake version need to change the directory to generate CMake project
    " -B option was introduced only in CMake 3.13
    let l:cw_dir = getcwd()
    if !utils#cmake#verNewerOrEq([3, 13])
        " Change work directory
        silent exec 'cd' l:build_dir
    endif
    " Generates CMake project
    call utils#common#executeCommand(l:cmake_cmd, s:getCMakeErrorFormat())
    if !utils#cmake#verNewerOrEq([3, 13])
        " Change work directory to old work directory
        silent exec 'cd' l:cw_dir
    endif

    " Collect CMake Information
    call utils#cmake#common#collectCMakeInfo(l:build_dir)

    " Select the cmake target if plugin changes the build command
    if g:cmake_change_build_command
        silent call cmake4vim#SelectTarget(g:cmake_build_target)
    endif
endfunction

" Reset and reload cmake project. Reset the current build directory and
" generate cmake project
function! cmake4vim#ResetAndReloadCMake(...) abort
    call cmake4vim#ResetCMakeCache()
    call cmake4vim#GenerateCMake(join(a:000))
endfunction

" The function is called when user saves cmake scripts
function! cmake4vim#CMakeFileSaved() abort
    if g:cmake_reload_after_save
        " Reloads CMake project if it is needed
        call cmake4vim#GenerateCMake()
    endif
endfunction

" Cleans CMake project
function! cmake4vim#CleanCMake() abort
    " Get generator specific clean target name
    let l:clean_target = utils#gen#common#getCleanTarget()
    if l:clean_target ==# ''
        call utils#common#Warning('CMake generator is not supported!')
        return
    endif

    let l:current_cmake_target = g:cmake_build_target
    call cmake4vim#CMakeBuild(l:clean_target)
    call cmake4vim#SelectTarget(l:current_cmake_target)
endfunction

" Returns all CMake targets
function! cmake4vim#GetAllTargets() abort
    let l:build_dir = utils#cmake#findBuildDir()
    if l:build_dir ==# ''
        call utils#common#Warning('Cmake targets were not found!')
    endif
    return utils#gen#common#getTargets(l:build_dir)
endfunction

" Selects CMake target
" Returns command line for target build
function! cmake4vim#SelectTarget(target) abort
    let l:build_dir = utils#cmake#findBuildDir()
    if l:build_dir ==# ''
        call utils#common#Warning('CMake project was not found!')
        return ''
    endif
    let l:cmake_target = utils#cmake#setBuildTarget(l:build_dir, a:target)
    let l:cmd = utils#cmake#getBuildCommand(l:build_dir, l:cmake_target)

    if g:cmake_vimspector_support
        let l:conf = utils#config#vimspector#getTargetConfig(l:cmake_target)
        let g:cmake_run_target_args = l:conf['args']
    endif

    if g:cmake_change_build_command
        let &makeprg = l:cmd
    endif
    echon 'CMake target: ' . l:cmake_target . ' selected!'
    return l:cmd
endfunction

" Builds CMake project
function! cmake4vim#CMakeBuild(...) abort
    if empty( utils#cmake#findBuildDir() )
        call utils#common#Warning('CMake project was not found!')
        return
    endif
    let l:cmake_target = a:0 ? a:1 : g:cmake_build_target

    " Select target
    let l:result = cmake4vim#SelectTarget(l:cmake_target)
    " Build
    call utils#common#executeCommand(l:result)
endfunction

" Run Ctest
function! cmake4vim#CTest(bang, ...) abort
    let l:build_dir = utils#cmake#findBuildDir()
    if l:build_dir ==# ''
        call utils#common#Warning('CMake project was not found!')
        return
    endif
    let l:cw_dir = getcwd()
    " Change work directory
    silent exec 'cd' l:build_dir
    let l:cmd = printf('ctest %s %s', a:bang ? '' : g:cmake_ctest_args, join( a:000 ) )
    " Run
    call utils#common#executeCommand(l:cmd)
    " Change work directory to old work directory
    silent exec 'cd' l:cw_dir
endfunction

" Functions allows to switch between build types
function! cmake4vim#SelectBuildType(buildType) abort
    let g:cmake_build_type = a:buildType
    call cmake4vim#GenerateCMake()
endfunction

" Functions allows to switch between cmake kits
function! cmake4vim#SelectKit(name) abort
    if !has_key( g:cmake_kits, a:name )
        call utils#common#Warning(printf("CMake kit '%s' not found", a:name))
        return
    endif

    call utils#cmake#unsetEnv(g:cmake_selected_kit)
    call utils#cmake#setEnv(a:name)
    let g:cmake_selected_kit = a:name
endfunction

function! cmake4vim#RunTarget(bang, ...) abort
    if empty( 'g:cmake_build_target' )
        call utils#common#Warning('Please select target first!')
        return
    endif

    let l:args = a:000
    if empty(l:args) && !a:bang
        let l:old_conf = utils#config#vimspector#getTargetConfig(g:cmake_build_target)
        let l:args = l:old_conf['args']
    endif

    let l:exec_path = utils#cmake#getBinaryPath()
    let l:conf = { g:cmake_build_target : { 'app': l:exec_path, 'args': l:args } }
    call utils#config#vimspector#updateConfig(l:conf)
    if strlen(l:exec_path)
        if has('win32')
            let l:status = ''
        else
            silent! let l:status = system('command -v noglob')
        endif
        if l:status !~# '\w\+'
            let l:noglob = ''
        else
            let l:noglob = 'noglob'
        endif
        call utils#common#executeCommand(join([l:noglob, utils#fs#fnameescape(l:exec_path)] + l:args))
    else
        let v:errmsg = 'Executable "' . g:cmake_build_target . '" was not found'
        call utils#common#Warning(v:errmsg)
    endif
endfunction

" Complete CCMake window modes
function! cmake4vim#CompleteCCMakeModes(arg_lead, cmd_line, cursor_pos) abort
    let l:modes = ['hsplit', 'vsplit', 'tab']
    return join(l:modes, "\n")
endfunction

" Open CCMake window
function! cmake4vim#CCMake(...) abort
    " Supported modes:
    " * empty, h - Open ccmake in horizontal split
    " * v - Open ccmake in vertical split
    " * t - Open ccmake in new tab
    let l:mode = a:0 ? a:1 : 'hsplit'
    let l:supported_modes = split(cmake4vim#CompleteCCMakeModes(0, 0, 0), '\n')

    if index(l:supported_modes, l:mode) == -1
        call utils#common#Warning('Unsupported window mode: ' . l:mode)
        return
    endif

    let l:cmd = 'terminal '
    if !has('nvim')
        let l:cmd .= '++close '
    endif
    let l:cmd .= 'ccmake ' . utils#fs#fnameescape(utils#cmake#getBuildDir())
    if has('nvim')
        let l:modes = { 'hsplit': 'vsp | ', 'vsplit': 'sp ', 'tab': 'tabnew | ' }
    else
        let l:modes = { 'hsplit': '', 'vsplit': 'vertical ', 'tab': 'tab ' }
    endif
    exec l:modes[l:mode] l:cmd
endfunction
" }}} Public functions "
