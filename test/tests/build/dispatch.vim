function! SetUp()
    silent call RemoveCMakeDirs()

    silent call ResetPluginOptions()
    let g:cmake_build_executor = 'dispatch'
endfunction


function! Test_Dispatch_executor_Generate_cmake_project_with_default_settings()
    if !has( 'win32' ) " Skip for Windows
        let l:old_rtp = &runtimepath
        set runtimepath+=$HOME/.vim/plugged/vim-dispatch
        set runtimepath+=$HOME/.vim/plugged/vim-dispatch/autoload
        set runtimepath+=$HOME/.vim/plugged/vim-dispatch/plugin
        source $HOME/.vim/plugged/vim-dispatch/plugin/dispatch.vim
        call assert_false( isdirectory( 'cmake-build-Release' ), 'Build directory should not exist' )
        silent CMake
        let l:iter = 0
        while l:iter < 30 && !filereadable( 'cmake-build-Release/CMakeCache.txt' )
            sleep 1
            let l:iter += 1
        endwhile
        call assert_true( filereadable( 'cmake-build-Release/CMakeCache.txt' ), 'CMakeCache.txt should be generated' )
        let &runtimepath = l:old_rtp
        quit
    endif
endfunction
