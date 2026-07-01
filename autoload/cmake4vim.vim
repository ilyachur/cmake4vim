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
    return join(sort(keys(utils#cmake#getCMakeVariants()), 'i' ), "\n")
endfunction

function! cmake4vim#CompleteKit(arg_lead, cmd_line, cursor_pos) abort
    return join(sort(keys(utils#cmake#kits#getCMakeKits()), 'i'), "\n")
endfunction

" Method remove build directory and reset the cmake cache
function! cmake4vim#ResetCMakeCache() abort
    let l:build_dir = utils#cmake#findBuildDir()
    if !empty(l:build_dir)
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

    " When a configure preset is selected drive CMake through it
    if !empty(g:cmake_configure_preset)
        let l:build_dir = utils#cmake#getBuildDir()
        call utils#cmake#common#makeRequests(l:build_dir)
        let l:cmake_cmd = call('utils#cmake#getCMakePresetGenerationCommand', a:000)
    else
        " Creates build directory
        let l:build_dir = utils#cmake#getBuildDir()

        " Prepare requests to CMake system
        call utils#cmake#common#makeRequests(l:build_dir)

        " Generates a command for CMake
        let l:cmake_cmd = call('utils#cmake#getCMakeGenerationCommand', a:000)
    endif

    " For old CMake versions the directory must be changed to generate the
    " project, since the -B option was introduced only in CMake 3.13
    let l:cw_dir = getcwd()
    if !utils#cmake#version#verNewerOrEq([3, 13])
        silent exec 'cd' fnameescape(l:build_dir)
    endif
    " Generates CMake project
    call utils#common#executeCommand(l:cmake_cmd, 0, getcwd(), s:getCMakeErrorFormat())
    if !utils#cmake#version#verNewerOrEq([3, 13])
        silent exec 'cd' fnameescape(l:cw_dir)
    endif

    " Collect CMake Information
    call utils#cmake#common#collectCMakeInfo(l:build_dir)

    " Warn if a compilation database was requested but the generator cannot
    " produce one (only Makefile and Ninja generators support it)
    if g:cmake_compile_commands
        let l:generator = utils#gen#common#getGenerator()
        if !utils#gen#common#supportsCompileCommands(l:generator)
            call utils#common#Warning(printf('compile_commands.json is not produced by the "%s" generator. Use a Makefile or Ninja generator.', l:generator))
        endif
    endif

    " Select the cmake target if plugin changes the build command
    if g:cmake_change_build_command
        silent call cmake4vim#SelectTarget(g:cmake_build_target)
    endif
endfunction

" Reset and reload cmake project. Reset the current build directory and
" generate cmake project
function! cmake4vim#ResetAndReloadCMake(...) abort
    " Remove the whole build directory before regenerating. 'cmake --fresh'
    " only wipes the cache and would leave stale build artifacts (e.g. the
    " binaries of targets that were removed from CMakeLists.txt) behind.
    silent call cmake4vim#ResetCMakeCache()
    call call('cmake4vim#GenerateCMake', a:000)
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
    if empty(l:clean_target)
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
    if empty(l:build_dir)
        call utils#common#Warning('CMake targets were not found!')
    endif
    return utils#gen#common#getTargets(l:build_dir)
endfunction

" Selects CMake target
" Returns command line for target build
function! cmake4vim#SelectTarget(target) abort
    let l:build_dir = utils#cmake#findBuildDir()
    if empty(l:build_dir)
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
    if empty(utils#cmake#findBuildDir())
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
function! cmake4vim#CompileSource(...) abort
    let l:source_name = get(a:, 1, expand('%'))
    let l:extension = fnamemodify( l:source_name, ':e' )
    if empty(l:extension) || index(['h', 'hpp'], tolower(l:extension)) >= 0
        call utils#common#Warning('Given file is not a source file!')
        return
    endif

    let l:build_dir = utils#cmake#findBuildDir()
    if empty(l:build_dir)
        call utils#common#Warning('CMake project was not found!')
        return
    endif

    " needed to detect the generator
    let l:cache_info = utils#cmake#cache#collectInfo(l:build_dir)
    if empty( l:cache_info )
        call utils#common#Warning('CMake cache was not found!')
        return
    endif

    " it seems ninja doesn't work with relative paths with newest cmake
    " and with cmake v2.8.12.2 it doesn't work with absolute paths
    " TODO: find the middle point
    let l:generator = l:cache_info['cmake']['generator']

    let l:target_name = ''
    if l:generator =~# 'Unix Makefiles' || utils#cmake#version#verNewerOrEq([ 3, 14 ])
        let l:target_name = utils#gen#common#getSingleUnitTargetName(l:generator, l:source_name)
    else
        let l:prefix = ''
        let l:build_dir = l:cache_info['cmake']['build_dir']
        " build folder is below getcwd()
        if l:generator =~# 'Ninja' && stridx(l:build_dir, getcwd()) == 0
            let l:subfolders = split(trim(split(l:build_dir, getcwd())[0], '/'), '/')
            for i in range(len(l:subfolders))
                let l:prefix .= '../'
            endfor
            if utils#cmake#version#verNewerOrEq([3, 13])
                let l:target_name = '"' . l:prefix . l:source_name . '^' . '"'
            else
                let l:target_name = l:prefix . fnameescape(l:source_name) . '^'
            endif
        endif
    endif

    " TODO: find the middle point
    if !utils#cmake#version#verNewerOrEq([ 3, 13 ])
        let l:target_name = printf('"%s"', l:target_name)
    endif

    let l:cmd = utils#cmake#getBuildCommand(l:build_dir, l:target_name)
    call utils#common#executeCommand(l:cmd, 1)
endfunction

" Run Ctest
function! cmake4vim#CTest(bang, ...) abort
    let l:build_dir = utils#cmake#findBuildDir()
    if empty(l:build_dir)
        call utils#common#Warning('CMake project was not found!')
        return
    endif
    let l:cmd = 'ctest'
    let l:args = []
    call extend(l:args, a:000)
    if !a:bang
        if type(g:cmake_ctest_args) == v:t_list
            let l:args += g:cmake_ctest_args
        else
            call extend(l:args, [g:cmake_ctest_args])
        endif
    endif

    let l:has_test_dir = utils#cmake#version#verNewerOrEq([3, 20])
    if !empty(g:cmake_test_preset)
        " The test preset already carries the test directory and configuration
        call insert(l:args, g:cmake_test_preset)
        call insert(l:args, '--preset')
    else
        " --test-dir is available since CMake 3.20; on older versions ctest must
        " be run from inside the build directory instead.
        if l:has_test_dir
            call extend(l:args, ['--test-dir', utils#fs#fnameescape(l:build_dir)])
        endif

        " Multi-config generators need the configuration selected explicitly
        let l:build_type = utils#cmake#getBuildType()
        if utils#gen#common#isMultiConfig(utils#gen#common#getGenerator()) && !empty(l:build_type)
            call extend(l:args, ['-C', l:build_type])
        endif
    endif

    " Run
    let l:cw_dir = getcwd()
    if !l:has_test_dir
        silent exec 'cd' utils#fs#fnameescape(l:build_dir)
    endif
    call utils#common#executeCommand(printf('%s %s', l:cmd, join(l:args)), 1)
    if !l:has_test_dir
        silent exec 'cd' utils#fs#fnameescape(l:cw_dir)
    endif
endfunction

function! cmake4vim#CTestCurrent(bang, ...) abort
    let l:args = [a:bang, '-R', g:cmake_build_target]
    call extend(l:args, a:000)
    call call('cmake4vim#CTest', l:args)
endfunction

" Functions allows to switch between build types
function! cmake4vim#SelectBuildType(buildType) abort
    let g:cmake_build_type = a:buildType
    call cmake4vim#GenerateCMake()
endfunction

" Functions allows to switch between cmake kits
function! cmake4vim#SelectKit(name) abort
    if !has_key(utils#cmake#kits#getCMakeKits(), a:name)
        call utils#common#Warning(printf("CMake kit '%s' not found", a:name))
        return
    endif

    call utils#cmake#unsetEnv(g:cmake_selected_kit)
    call utils#cmake#setEnv(a:name)
    let g:cmake_selected_kit = a:name
endfunction

" CMakePresets completion {{{ "
function! cmake4vim#CompleteConfigurePreset(arg_lead, cmd_line, cursor_pos) abort
    return join(utils#cmake#presets#getConfigurePresets(), "\n")
endfunction

function! cmake4vim#CompleteBuildPreset(arg_lead, cmd_line, cursor_pos) abort
    return join(utils#cmake#presets#getBuildPresets(), "\n")
endfunction

function! cmake4vim#CompleteTestPreset(arg_lead, cmd_line, cursor_pos) abort
    return join(utils#cmake#presets#getTestPresets(), "\n")
endfunction

function! cmake4vim#CompleteWorkflowPreset(arg_lead, cmd_line, cursor_pos) abort
    return join(utils#cmake#presets#getWorkflowPresets(), "\n")
endfunction
" }}} CMakePresets completion "

" Selects a configure preset and configures the project through it
function! cmake4vim#SelectConfigurePreset(name) abort
    if index(utils#cmake#presets#getConfigurePresets(), a:name) == -1
        call utils#common#Warning(printf("CMake configure preset '%s' not found", a:name))
        return
    endif
    let l:binary_dir = utils#cmake#presets#getConfigureBinaryDir(a:name)
    if empty(l:binary_dir)
        call utils#common#Warning(printf("Cannot resolve binary directory for preset '%s'", a:name))
        return
    endif
    let g:cmake_configure_preset = a:name
    " Point the plugin at the preset's binary directory so target detection,
    " building and running keep working.
    let g:cmake_build_dir = l:binary_dir
    call cmake4vim#GenerateCMake()
endfunction

" Selects a build preset used by :CMakeBuild
function! cmake4vim#SelectBuildPreset(name) abort
    if index(utils#cmake#presets#getBuildPresets(), a:name) == -1
        call utils#common#Warning(printf("CMake build preset '%s' not found", a:name))
        return
    endif
    let g:cmake_build_preset = a:name
    echon 'CMake build preset: ' . a:name . ' selected!'
endfunction

" Selects a test preset used by :CTest
function! cmake4vim#SelectTestPreset(name) abort
    if index(utils#cmake#presets#getTestPresets(), a:name) == -1
        call utils#common#Warning(printf("CMake test preset '%s' not found", a:name))
        return
    endif
    let g:cmake_test_preset = a:name
    echon 'CMake test preset: ' . a:name . ' selected!'
endfunction

" Runs a workflow preset (cmake --workflow --preset, CMake 3.25+)
function! cmake4vim#CMakeWorkflow(...) abort
    let l:name = a:0 ? a:1 : ''
    if empty(l:name)
        call utils#common#Warning('Please specify a workflow preset name!')
        return
    endif
    if index(utils#cmake#presets#getWorkflowPresets(), l:name) == -1
        call utils#common#Warning(printf("CMake workflow preset '%s' not found", l:name))
        return
    endif
    call utils#common#executeCommand(printf('%s --workflow --preset %s', g:cmake_executable, l:name), 0, getcwd(), s:getCMakeErrorFormat())
endfunction

function! cmake4vim#RunTarget(bang, ...) abort
    if empty(g:cmake_build_target)
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
    let l:modes = ['split', 'vsplit', 'tab']
    return join(l:modes, "\n")
endfunction

" Open CCMake window
function! cmake4vim#CCMake(...) abort
    " Supported modes:
    " * empty, h - Open ccmake in horizontal split
    " * v - Open ccmake in vertical split
    " * t - Open ccmake in new tab
    let l:mode = a:0 ? a:1 : g:cmake_build_executor_split_mode ==# 'sp' ? 'split' : 'vsplit'
    let l:supported_modes = split(cmake4vim#CompleteCCMakeModes(0, 0, 0), '\n')

    if index(l:supported_modes, l:mode) == -1
        call utils#common#Warning('Unsupported window mode: ' . l:mode)
        return
    endif

    let l:cmd = 'terminal '
    if !has('nvim')
        let l:cmd .= '++close '
    endif
    let l:cmd .= 'ccmake -B ' . utils#fs#fnameescape(utils#cmake#getBuildDir())
    if has('nvim')
        let l:modes = { 'split': 'sp ', 'vsplit': 'vsp | ', 'tab': 'tabnew | ' }
    else
        let l:modes = { 'split': '', 'vsplit': 'vertical ', 'tab': 'tab ' }
    endif
    exec l:modes[l:mode] l:cmd
endfunction

function! cmake4vim#init() abort
    " Common properties
    let g:cmake_executable            = get(g:, 'cmake_executable'           , 'cmake'       )
    let g:cmake_reload_after_save     = get(g:, 'cmake_reload_after_save'    , 0             )
    let g:cmake_change_build_command  = get(g:, 'cmake_change_build_command' , 1             )
    let g:cmake_compile_commands      = get(g:, 'cmake_compile_commands'     , 0             )
    let g:cmake_compile_commands_link = get(g:, 'cmake_compile_commands_link', ''            )
    " Value for -DCMAKE_POLICY_VERSION_MINIMUM. Useful to configure old
    " projects (cmake_minimum_required < 3.5) with CMake 4.x, which otherwise
    " errors out. Empty means the flag is not passed.
    let g:cmake_compat_policy_version = get(g:, 'cmake_compat_policy_version', ''            )
    let g:cmake_vimspector_support    = get(g:, 'cmake_vimspector_support'   , 0             )
    let g:cmake_vimspector_default_configuration = get(g:, 'cmake_vimspector_default_configuration', {
                \ 'adapter': '',
                \ 'configuration': {
                \ 'request': 'launch',
                \ 'cwd': '${workspaceRoot}',
                \ 'Mimode': '',
                \ 'args': [],
                \ 'program': ''
                \ }
                \ })

    " Optional variable allow to specify the build executor
    " Possible values: 'job', 'dispatch', 'system', 'term', ''
    let g:cmake_build_executor                = get(g:, 'cmake_build_executor'            , '')

    " Possible values: sp - horizontal mode, vsp - vertical mode
    let g:cmake_build_executor_split_mode     = get(g:, 'cmake_build_executor_split_mode' , 'sp')
    let g:cmake_build_executor_window_size    = get(g:, 'cmake_build_executor_window_size', 10)

    " Build path
    let g:cmake_build_path_pattern    = get(g:, 'cmake_build_path_pattern'   , ''            )
    let g:cmake_build_dir             = get(g:, 'cmake_build_dir'            , ''            )
    let g:cmake_build_dir_prefix      = get(g:, 'cmake_build_dir_prefix'     , 'cmake-build-')

    " CMake build
    let g:make_arguments              = get(g:, 'make_arguments'             , ''            )
    let g:cmake_build_args            = get(g:, 'cmake_build_args'           , ''            )
    let g:cmake_build_target          = get(g:, 'cmake_build_target'         , ''            )
    let g:cmake_build_type            = get(g:, 'cmake_build_type'           , ''            )
    let g:cmake_src_dir               = get(g:, 'cmake_src_dir'              , ''            )
    let g:cmake_usr_args              = get(g:, 'cmake_usr_args'             , ''            )
    let g:cmake_ctest_args            = get(g:, 'cmake_ctest_args'           , ''            )
    let g:cmake_variants              = get(g:, 'cmake_variants'             , {}            )
    let g:cmake_selected_kit          = get(g:, 'cmake_selected_kit'         , ''            )
    let g:cmake_kits                  = get(g:, 'cmake_kits'                 , {}            )
    let g:cmake_kits_global_path      = get(g:, 'cmake_kits_global_path'     , ''            )

    " CMakePresets.json support. When a configure preset is selected the
    " project is configured with `cmake --preset`; the build/test presets are
    " used by :CMakeBuild / :CTest when set.
    let g:cmake_configure_preset      = get(g:, 'cmake_configure_preset'     , ''            )
    let g:cmake_build_preset          = get(g:, 'cmake_build_preset'         , ''            )
    let g:cmake_test_preset           = get(g:, 'cmake_test_preset'          , ''            )
endfunction
" }}} Public functions "
