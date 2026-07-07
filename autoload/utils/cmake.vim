" autoload/utils/cmake.vim - contains cmake helpers
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

" Private functions {{{ "
let s:populated_build_types = []
let s:cached_usr_args       = {}

function! s:detectCMakeBuildType() abort
    if !empty(g:cmake_build_type)
        return g:cmake_build_type
    endif
    let l:cmake_info = utils#cmake#common#getInfo()
    if !empty(l:cmake_info) && !empty(get(l:cmake_info['cmake'], 'build_type', ''))
        return l:cmake_info['cmake']['build_type']
    endif
    " WA for recursive DetectBuildDir, try to find the first valid cmake directory
    let l:build_dir = ''
    if empty(g:cmake_build_dir)
        if !empty(g:cmake_build_path_pattern)
            let l:build_dir = finddir(s:getCMakeBuildPattern())
        endif
        for l:type in keys(utils#cmake#getCMakeVariants())
            let l:build_dir = 'cmake-build-' . l:type
            let l:build_dir = finddir(l:build_dir, fnameescape(getcwd()))
            if !empty(l:build_dir)
                break
            endif
        endfor
    else
        let l:build_dir = utils#cmake#findBuildDir()
    endif

    if !empty(l:build_dir)
        let l:build_dir = fnamemodify(l:build_dir, ':p:h')
        let l:cmake_info = utils#cmake#common#getInfo(l:build_dir)
        if !empty(l:cmake_info) && !empty(l:cmake_info['cmake']['build_type'])
            return l:cmake_info['cmake']['build_type']
        endif
    endif

    return 'Release'
endfunction

function! s:getCMakeBuildPattern() abort
    let [l:fmt, l:args] = g:cmake_build_path_pattern
    return eval(printf('printf("%s", %s)', l:fmt, l:args))
endfunction

function! s:detectCMakeBuildDir() abort
    if !empty(g:cmake_build_dir)
        return g:cmake_build_dir
    endif
    let l:cmake_info = utils#cmake#common#getInfo()
    if !empty(l:cmake_info) && !empty(l:cmake_info['cmake']['build_dir'])
        return l:cmake_info['cmake']['build_dir']
    endif
    let l:build_type = s:detectCMakeBuildType()
    if len(g:cmake_build_path_pattern) == 2
        return s:getCMakeBuildPattern()
    endif
    return g:cmake_build_dir_prefix . l:build_type
endfunction

function! s:detectCMakeSrcDir() abort
    if !empty(g:cmake_src_dir)
        return g:cmake_src_dir
    endif
    return getcwd()
endfunction

function! s:populateDefaultCMakeVariants() abort
    for build_type in filter(utils#cmake#getDefaultBuildTypes(), "v:val !=# ''")
        if (!has_key(g:cmake_variants, build_type))
            let s:populated_build_types += [build_type]
            let g:cmake_variants[build_type] =
                \ {
                \   'cmake_build_type' : build_type,
                \   'cmake_usr_args'   : utils#cmake#splitUserArgs(g:cmake_usr_args)
                \ }
        endif
    endfor
    " Change usr_arguments if global usr_args
    if utils#cmake#splitUserArgs(g:cmake_usr_args) !=# s:cached_usr_args
        let s:cached_usr_args = utils#cmake#splitUserArgs(g:cmake_usr_args)
        for l:populated_type in s:populated_build_types
            let g:cmake_variants[l:populated_type]['cmake_usr_args'] = utils#cmake#splitUserArgs(g:cmake_usr_args)
        endfor
    endif
endfunction
" }}} Private functions "
"
function! utils#cmake#setEnv(name) abort
    let l:cmake_kit = get(utils#cmake#kits#getCMakeKits(), a:name, {})
    for [key, val] in items(get(l:cmake_kit, 'environment_variables', {}))
        execute printf('let $%s="%s"', key, val)
    endfor
endfunction

function! utils#cmake#unsetEnv(name) abort
    let l:cmake_kit = get(utils#cmake#kits#getCMakeKits(), a:name, {})
    for key in keys(get(l:cmake_kit, 'environment_variables', {}))
        execute printf('unlet $%s', key)
    endfor
endfunction

function! utils#cmake#joinUserArgs(cmakeArguments) abort
    if type(a:cmakeArguments) == v:t_string
        return a:cmakeArguments
    endif

    let l:ret = []
    for [key, val] in items(a:cmakeArguments)
        if !empty(val)
            let l:ret += [printf('-D%s=%s', key, val)]
        else
            let l:ret += [key]
        endif
    endfor
    return join(l:ret)
endfunction

function! utils#cmake#splitUserArgs(cmakeArguments) abort
    if type(a:cmakeArguments) == v:t_dict
        return a:cmakeArguments
    endif

    let l:ret = {}
    for cmake_arg in split(a:cmakeArguments)
        if stridx(cmake_arg, '=') != -1
            let [key, val] = split(cmake_arg[ 2: ], '=')
            let l:ret[key] = val
        else
            let l:ret[cmake_arg] = ''
        endif
    endfor
    return l:ret
endfunction

" Returns the list of default CMake build types
function! utils#cmake#getDefaultBuildTypes() abort
    return ['Release', 'Debug', 'RelWithDebInfo', 'MinSizeRel', '']
endfunction

" Returns the currently selected/detected CMake build type (configuration)
function! utils#cmake#getBuildType() abort
    return s:detectCMakeBuildType()
endfunction

" Returns the path to build directory if directory was found and returns empty string in other case.
" Use build directory from the cmake cache or try to find it at the current folder
" Creates directory if it doesn't exist
function! utils#cmake#getBuildDir() abort
    let l:build_dir = s:detectCMakeBuildDir()
    let l:build_dir = utils#fs#makeDir(l:build_dir)
    let l:build_dir = fnamemodify(l:build_dir, ':p:h')
    return l:build_dir
endfunction

" Return the names of possible builds, includes default CMake build types
function! utils#cmake#getCMakeVariants() abort
    call s:populateDefaultCMakeVariants()
    return g:cmake_variants
endfunction

" Gets CMake version
" Returns array [major, minor, patch]
" Kept as a thin wrapper for backward compatibility; the implementation
" (with caching) lives in utils#cmake#version#getVersion().
function! utils#cmake#getVersion() abort
    return utils#cmake#version#getVersion()
endfunction



" Set CMake build target
function! utils#cmake#setBuildTarget(build_dir, target) abort
    " Use all target if a:target and g:cmake_target are empty
    let l:cmake_target = a:target
    if empty(a:target)
        let l:cmake_target = utils#gen#common#getDefaultTarget()
    endif
    let g:cmake_build_target = l:cmake_target

    return l:cmake_target
endfunction

" Generates CMake build command
function! utils#cmake#getBuildCommand(build_dir, target) abort
    if !empty(g:cmake_compile_commands_link)
        let l:src = a:build_dir . '/compile_commands.json'
        let l:dst = g:cmake_compile_commands_link . '/compile_commands.json'
        call utils#fs#createLink(l:src, l:dst)
    endif

    " Build through the selected build preset when set
    if !empty(g:cmake_build_preset)
        let l:cmd = printf('%s --build --preset %s', g:cmake_executable, g:cmake_build_preset)
        if !empty(a:target)
            let l:cmd .= ' --target ' . a:target
        endif
        if !empty(g:cmake_build_args)
            let l:cmd .= ' ' . g:cmake_build_args
        endif
        return l:cmd
    endif

    " For multi-config generators the build type is selected at build time via
    " --config, since CMAKE_BUILD_TYPE is ignored at configure time.
    let l:build_args = g:cmake_build_args
    let l:build_type = s:detectCMakeBuildType()
    if utils#gen#common#isMultiConfig(utils#gen#common#getGenerator()) && !empty(l:build_type)
        let l:build_args = trim(printf('--config %s %s', l:build_type, l:build_args))
    endif

    return utils#gen#common#getBuildCommand(a:build_dir, a:target, l:build_args, g:make_arguments)
endfunction

" Returns the configuration command that would actually be run: the preset
" based one when a configure preset is selected, otherwise the generator one.
function! utils#cmake#getActiveGenerationCommand() abort
    if !empty(g:cmake_configure_preset)
        return utils#cmake#getCMakePresetGenerationCommand()
    endif
    return utils#cmake#getCMakeGenerationCommand()
endfunction

" Generates the CMake configuration command using the selected configure preset
" Additional cmake arguments can be passed as arguments of this function
function! utils#cmake#getCMakePresetGenerationCommand(...) abort
    let l:cmake_args = ['--preset', g:cmake_configure_preset]

    if g:cmake_compile_commands
        let l:cmake_args += ['-DCMAKE_EXPORT_COMPILE_COMMANDS=ON']
    endif
    if !empty(g:cmake_compat_policy_version)
        let l:cmake_args += ['-DCMAKE_POLICY_VERSION_MINIMUM=' . g:cmake_compat_policy_version]
    endif

    let l:cmake_args += a:000
    return printf('%s %s', g:cmake_executable, join(l:cmake_args))
endfunction

" Generates the command line for CMake generator
" Additional cmake arguments can be passed as arguments of this function
function! utils#cmake#getCMakeGenerationCommand(...) abort
    let l:build_dir = utils#cmake#findBuildDir()
    let l:src_dir   = utils#cmake#findSrcDir()
    let l:cmake_variant = utils#cmake#getCMakeVariants()[ s:detectCMakeBuildType() ]
    let l:cmake_args = []

    " Set build type
    let l:cmake_args += ['-DCMAKE_BUILD_TYPE=' . l:cmake_variant['cmake_build_type']]
    let l:cmake_project_generator = ''
    let l:cmake_toolchain_file    = ''
    let l:cmake_c_compiler        = ''
    let l:cmake_cxx_compiler      = ''

    " CMakeKit can contain:
    " * additional user arguments
    " * project generator
    " * toolchain file
    " * compilers
    if !empty(g:cmake_selected_kit) && has_key(utils#cmake#kits#getCMakeKits(), g:cmake_selected_kit)
        silent call utils#cmake#setEnv(g:cmake_selected_kit) " just in case the user has set the variable manually
        let l:active_kit = utils#cmake#kits#getCMakeKits()[g:cmake_selected_kit]
        let l:cmake_project_generator = get(l:active_kit, 'generator', l:cmake_project_generator)
        let l:cmake_toolchain_file    = get(l:active_kit, 'toolchain_file', l:cmake_toolchain_file)
        let l:cmake_kit_usr_args      = [utils#cmake#joinUserArgs(get(l:active_kit, 'cmake_usr_args', {}))]
        if !has_key(l:active_kit, 'toolchain_file') && has_key(l:active_kit, 'compilers')
            let l:cmake_c_compiler   = get(l:active_kit['compilers'], 'C', l:cmake_c_compiler)
            let l:cmake_cxx_compiler = get(l:active_kit['compilers'], 'CXX', l:cmake_cxx_compiler)
        endif
    endif

    " Specify generator
    if !empty(l:cmake_project_generator)
        let l:cmake_args += [printf('-G "%s"', l:cmake_project_generator)]
    endif
    " Set toolchain file ( it has priority over compilers )
    if !empty(l:cmake_toolchain_file)
        let l:cmake_args += ['-DCMAKE_TOOLCHAIN_FILE=' . l:cmake_toolchain_file]
    else
        " Set c and c++ compilers
        if !empty(l:cmake_c_compiler)
            let l:cmake_args += ['-DCMAKE_C_COMPILER=' . l:cmake_c_compiler]
        endif
        if !empty(l:cmake_cxx_compiler)
            let l:cmake_args += ['-DCMAKE_CXX_COMPILER=' . l:cmake_cxx_compiler]
        endif
    endif

    " Add command to export compilation database
    if g:cmake_compile_commands
        let l:cmake_args += ['-DCMAKE_EXPORT_COMPILE_COMMANDS=ON']
    endif

    " Allow configuring old projects with CMake 4.x, which removed
    " compatibility with cmake_minimum_required() below 3.5
    if !empty(g:cmake_compat_policy_version)
        let l:cmake_args += ['-DCMAKE_POLICY_VERSION_MINIMUM=' . g:cmake_compat_policy_version]
    endif

    " Add user arguments
    let l:cmake_variant_usr_args = [utils#cmake#joinUserArgs(l:cmake_variant['cmake_usr_args'])]

    let l:cmake_args += l:cmake_variant_usr_args + get(l:, 'cmake_kit_usr_args', [])
    let l:cmake_args += a:000

    " Check that we have at least CMake 3.13 for the -B option, fallback for
    " older versions (GenerateCMake changes into the build directory for them)
    if utils#cmake#version#verNewerOrEq([3, 13])
        let l:cmake_args += ['-B', utils#fs#fnameescape(l:build_dir), '-S', utils#fs#fnameescape(l:src_dir)]
    else
        " For older CMake versions, use the current directory as source
        let l:cmake_args += [utils#fs#fnameescape(getcwd())]
    endif

    " Generates the command line
    return printf('%s %s', g:cmake_executable, join(l:cmake_args))
endfunction

" Check that build directory exists
function! utils#cmake#findBuildDir() abort
    let l:build_dir = finddir(s:detectCMakeBuildDir(), fnameescape(getcwd()))
    if !empty(l:build_dir)
        let l:build_dir = fnamemodify(l:build_dir, ':p:h')
    endif
    " Get cmake information
    call utils#cmake#common#getInfo(l:build_dir)
    return l:build_dir
endfunction

" Check that src directory exists
function! utils#cmake#findSrcDir() abort
    let l:src_dir = finddir(s:detectCMakeSrcDir(), fnameescape(getcwd()))
    if !empty(l:src_dir)
        let l:src_dir = fnamemodify(l:src_dir, ':p:h')
    endif
    return l:src_dir
endfunction

function! utils#cmake#getBinaryPath(...) abort
    let l:build_dir = utils#cmake#getBuildDir()
    let l:cmake_info = utils#cmake#common#getInfo(l:build_dir)
    let l:build_type = s:detectCMakeBuildType()
    if has_key(l:cmake_info, 'targets') && has_key(l:cmake_info['targets'], l:build_type) && has_key(l:cmake_info['targets'][l:build_type], g:cmake_build_target)
        let l:target = l:cmake_info['targets'][l:build_type][g:cmake_build_target]
        if l:target['type'] !=# 'EXECUTABLE'
            let v:errmsg = 'Target ' . g:cmake_build_target . ' is not an executable'
            if !a:0
                call utils#common#Warning(v:errmsg)
            endif
            return ''
        endif
        if !has('win32')
            let l:exec_path = ''
            " Check absolute path /...
            if l:target['pathes'][0][0] !=# '/'
                let l:exec_path = l:build_dir . '/'
            endif
            let l:exec_path .= l:target['pathes'][0]
            return l:exec_path
        else
            for l:path in l:target['pathes']
                if l:path =~# '\.exe'
                    let l:exec_path = ''
                    " Check absolute path C:...
                    if l:path[1] !=# ':'
                        let l:exec_path = l:build_dir . '/'
                    endif
                    let l:exec_path .= l:path
                    return l:exec_path
                endif
            endfor
        endif
    endif
    let l:exec_filename = ''
    if has('win32')
        let l:exec_filename = g:cmake_build_target . '.exe'
    else
        let l:exec_filename = g:cmake_build_target
    endif

    let l:exec_path = findfile(exec_filename, utils#fs#fnameescape(l:build_dir) . '/**')
    if !empty(l:exec_path)
        let l:exec_path = fnamemodify(l:exec_path, ':p')
    endif
    return l:exec_path
endfunction

function! utils#cmake#resetCache() abort
    call utils#cmake#kits#resetCMakeKitsCache()
    let s:populated_build_types = []
    let s:cached_usr_args       = {}
endfunction
