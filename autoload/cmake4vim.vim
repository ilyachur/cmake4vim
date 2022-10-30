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
    return join(sort(keys(utils#cmake#kits#getCMakeKits()), 'i'), "\n")
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
    call utils#common#executeCommand(l:cmake_cmd, 0, getcwd(), s:getCMakeErrorFormat())
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
    " CMake 3.24 supports the same functionality
    " call utils#common#executeCommand('cmake --fresh -B ' . utils#fs#fnameescape(l:build_dir), 0, getcwd(), s:getCMakeErrorFormat())
    silent call cmake4vim#ResetCMakeCache()
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
        call utils#common#Warning('CMake targets were not found!')
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
    call utils#common#executeCommand(l:result, 0)
endfunction

" Builds current source
function! cmake4vim#CompileSource( ... ) abort
    let l:source_name = get( a:, 1, expand('%') )
    let l:extension = fnamemodify( l:source_name, ':e' )
    if empty( l:extension ) || index( [ 'h', 'hpp' ], tolower( l:extension ) ) >= 0
        call utils#common#Warning( 'Given file is not a source file!' )
        return
    endif

    let l:build_dir = utils#cmake#findBuildDir()
    if empty( l:build_dir )
        call utils#common#Warning( 'CMake project was not found!' )
        return
    endif

    " needed to detect the generator
    let l:cache_info = utils#cmake#cache#collectInfo( l:build_dir )
    if empty( l:cache_info )
        call utils#common#Warning( 'CMake cache was not found!' )
        return
    endif

    " it seems ninja doesn't work with relative paths with newest cmake
    " and with cmake v2.8.12.2 it doesn't work with absolute paths
    " TODO: find the middle point

    let l:generator = l:cache_info[ 'cmake' ][ 'generator' ]

    let l:target_name = ''
    if l:generator =~# 'Unix Makefiles' || utils#cmake#verNewerOrEq( [ 3, 14 ] )
        let l:target_name = utils#gen#common#getSingleUnitTargetName( l:generator, l:source_name )
    else
        let l:prefix = ''
        let l:build_dir = l:cache_info[ 'cmake' ][ 'build_dir' ]
        " build folder is below getcwd()
        if l:generator =~# 'Ninja' && stridx( l:build_dir, getcwd() ) == 0
                let l:subfolders = split(trim( split( l:build_dir, getcwd() )[0], '/'), '/')
                for i in range( len( l:subfolders ) )
                    let l:prefix .= '../'
                endfor
                if utils#cmake#verNewerOrEq( [ 3, 13 ] )
                    let l:target_name = '"' . l:prefix . l:source_name . '^' . '"'
                else
                    let l:target_name = l:prefix . fnameescape( l:source_name ) . '^'
                endif
        endif
    endif

    " TODO: find the middle point
    if !utils#cmake#verNewerOrEq( [ 3, 13 ] )
        let l:target_name = printf( '"%s"', l:target_name )
    endif

    let l:cmd = utils#cmake#getBuildCommand( l:build_dir, l:target_name )
    call utils#common#executeCommand( l:cmd, 1 )
endfunction

" Run Ctest
function! cmake4vim#CTest(bang, ...) abort
    let l:build_dir = utils#cmake#findBuildDir()
    if l:build_dir ==# ''
        call utils#common#Warning('CMake project was not found!')
        return
    endif
    let l:cw_dir = getcwd()
    let l:cmd = 'ctest '
    if !utils#cmake#verNewerOrEq([3, 20])
        " Change work directory
        silent exec 'cd' l:build_dir
    else
        let l:cmd .= '--test-dir ' . utils#fs#fnameescape(l:build_dir) . ' '
    endif
    let l:cmd = printf('%s %s %s',l:cmd, a:bang ? '' : g:cmake_ctest_args, join(a:000))
    " Run
    call utils#common#executeCommand(l:cmd, 1)
    if !utils#cmake#verNewerOrEq([3, 20])
        " Change work directory to old work directory
        silent exec 'cd' l:cw_dir
    endif
endfunction

function! cmake4vim#CTestCurrent(bang, ...) abort
    let l:args = join(a:000) . ' -R ' . g:cmake_build_target
    call cmake4vim#CTest(a:bang, l:args)
endfunction

" Functions allows to switch between build types
function! cmake4vim#SelectBuildType(buildType) abort
    let g:cmake_build_type = a:buildType
    call cmake4vim#GenerateCMake()
endfunction

" Functions allows to switch between cmake kits
function! cmake4vim#SelectKit(name) abort
    if !has_key( utils#cmake#kits#getCMakeKits(), a:name )
        call utils#common#Warning(printf("CMake kit '%s' not found", a:name))
        return
    endif

    call utils#cmake#unsetEnv(g:cmake_selected_kit)
    call utils#cmake#setEnv(a:name)
    let g:cmake_selected_kit = a:name
endfunction

function! cmake4vim#RunTarget(bang, ...) abort
    if empty( g:cmake_build_target )
        call utils#common#Warning('Please select target first!')
        return
    endif

    let l:args = a:000
    let l:old_conf = utils#config#vimspector#getTargetConfig(g:cmake_build_target)
    if empty(l:args) && !a:bang
        let l:args = l:old_conf['args']
    endif
    let l:cwd = l:old_conf['cwd']

    let l:build_command = cmake4vim#SelectTarget(g:cmake_build_target)
    let l:exec_path = utils#cmake#getBinaryPath()
    let l:conf = { g:cmake_build_target : { 'app': l:exec_path, 'args': l:args } }
    if strlen(l:exec_path)
        call utils#common#executeCommands([
                    \ { 'cmd': l:build_command, 'cwd': getcwd() },
                    \ { 'cmd': join([utils#fs#fnameescape(l:exec_path)] + l:args, ' '), 'cwd': l:cwd }], 1)
        call utils#config#vimspector#updateConfig(l:conf)
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
