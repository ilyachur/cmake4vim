function! SetUp()
    silent call RemoveCMakeDirs()

    silent call ResetPluginOptions()
endfunction

function! TearDown()
    " close CCMake
    call feedkeys('q', 'nx')
    " give vim time to close it
    sleep 1
endfunction

function! Test_CCMake_Run_ccmake_in_default_mode()
    call assert_equal( 'system', g:cmake_build_executor )
    if !has( 'win32' )
        silent CMake
        cclose
        CCMake
        sleep 1
        call assert_true ( winnr('$')   > 1             )
        call assert_true ( getline(1) =~# 'Page 1'      )
        call assert_false( getline(2) =~# 'CMake Error' )
    endif
endfunction

function! Test_CCMake_Run_ccmake_in_horizontal_mode()
    if !has( 'win32' )
        silent CMake
        cclose
        CCMake hsplit
        sleep 1
        call assert_true ( winnr('$')   > 1             )
        call assert_true ( getline(1) =~# 'Page 1'      )
        call assert_false( getline(2) =~# 'CMake Error' )
    endif
endfunction

function! Test_CCMake_Run_ccmake_in_vertical_mode()
    if !has( 'win32' )
        silent CMake
        cclose
        CCMake vsplit
        sleep 1
        call assert_true ( winnr('$')   > 1             )
        call assert_true ( getline(1) =~# 'Page 1'      )
        call assert_false( getline(2) =~# 'CMake Error' )
    endif
endfunction

function! Test_CCMake_Run_ccmake_in_tab_mode()
    if !has( 'win32' )
        silent CMake
        CCMake tab
        sleep 1
        call assert_true ( tabpagenr('$')   > 1             )
        call assert_true ( getline(1)     =~# 'Page 1'      )
        call assert_false( getline(2)     =~# 'CMake Error' )
    endif
endfunction

function! Test_CCMake_Run_ccmake_with_unsuported_Window_mode()
    if !has( 'win32' )
        silent CMake
        CCMake unknown
        sleep 1
        redir => l:error_message
        1messages
        redir END
        call assert_equal( "\nUnsupported window mode: unknown", l:error_message )
    endif
endfunction
