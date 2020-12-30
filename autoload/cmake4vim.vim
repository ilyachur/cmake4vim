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
    let l:sorted_targets = utils#cmake#getDefaultBuildTypes()
    return join(l:sorted_targets, "\n")
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
    let l:src_dir = utils#cmake#findSrcDir()
    if !utils#cmake#verNewerOrEq([3, 13])
        " Change work directory
        silent exec 'cd' l:build_dir
    endif
    " Generates CMake project
    call utils#common#executeCommand(l:cmake_cmd, s:getCMakeErrorFormat())
    if !utils#cmake#verNewerOrEq([3, 13])
        " Change work directory to source folder
        silent exec 'cd' l:src_dir
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

    call cmake4vim#CMakeBuild(l:clean_target)
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
    if g:cmake_change_build_command
        let &makeprg = l:cmd
    endif
    echon 'Cmake target: ' . l:cmake_target . ' selected!'
    return l:cmd
endfunction

" Builds CMake project
function! cmake4vim#CMakeBuild(...) abort
    let l:build_dir = utils#cmake#findBuildDir()
    if l:build_dir ==# ''
        call utils#common#Warning('CMake project was not found!')
        return
    endif
    let l:cmake_target = g:cmake_build_target
    if exists('a:1') && a:1 !=# ''
        let l:cmake_target = a:1
    endif
    " Select target
    let l:result = cmake4vim#SelectTarget(l:cmake_target)
    " Build
    call utils#common#executeCommand(l:result)
endfunction

" Run Ctest
function! cmake4vim#CTest(...) abort
    let l:build_dir = utils#cmake#findBuildDir()
    if l:build_dir ==# ''
        call utils#common#Warning('CMake project was not found!')
        return
    endif
    let l:old_target = g:cmake_build_target
    let l:cmake_target = 'test'
    let l:result = cmake4vim#SelectTarget(l:cmake_target) . ' ARGS="' . join(a:000) . '"'
    " Run
    call utils#common#executeCommand(l:result)
    " Set old target
    call cmake4vim#SelectTarget(l:old_target)
endfunction

" Functions allows to switch between build types
function! cmake4vim#SelectBuildType(buildType) abort
    let g:cmake_build_type = a:buildType

    call cmake4vim#GenerateCMake()
endfunction

function! cmake4vim#RunTarget(...) abort
    if !exists('g:cmake_build_target')
        echom 'Please select target first!'
        return
    endif

    let l:exec_path = utils#cmake#getBinaryPath()
    if strlen(l:exec_path)
        call utils#common#executeCommand(join([l:exec_path] + a:000, ' '))
    else
        let v:errmsg = 'Executable "' . g:cmake_build_target . '" was not found'
        call utils#common#Warning(v:errmsg)
    endif
endfunction
" }}} Public functions "
