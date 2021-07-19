function! SetUp()
    silent call Remove( '.vimspector.json' )
    silent call RemoveCMakeDirs()

    silent call ResetPluginOptions()
    let g:cmake_vimspector_support = 1

    " to shorten test time
    let g:cmake_build_type = 'Debug'
endfunction

function! s:CheckConfigValidity( config )
    call assert_true( has_key( a:config, 'configurations'                                               ), 'Config should have configurations'          )
    call assert_true( has_key( a:config[ 'configurations' ], 'test_app'                                 ), 'Config should have test_app'                )
    call assert_true( has_key( a:config[ 'configurations' ][ 'test_app' ], 'configuration'              ), 'Test_app should have configuration'         )
    call assert_true( has_key( a:config[ 'configurations' ][ 'test_app' ][ 'configuration' ], 'program' ), 'Test_app configuration should have program' )
endfunction

function! Test_Vimspector_Do_not_create_default_vimspector_config()
    let g:cmake_vimspector_support = 0
    call assert_false( filereadable( '.vimspector.json' ), 'Vimspector config should not exist' )
    call utils#config#vimspector#updateConfig( {} )
    call assert_false( filereadable( '.vimspector.json' ), 'Vimspector config should not exist' )
endfunction

function! Test_Vimspector_Create_default_vimspector_config()
    call assert_false( filereadable( '.vimspector.json' ), 'Vimspector config should not exist' )
    silent let l:config = utils#config#vimspector#updateConfig({})
    call assert_true( filereadable( '.vimspector.json' ), 'Vimspector config should exist' )
    call assert_true( has_key( l:config, 'configurations' ), 'Config should have configurations'  )
endfunction

function! Test_Vimspector_Avoid_incorrect_vimspector_configs()
    call assert_false( filereadable( '.vimspector.json' ), 'Vimspector config should not exist' )
    " Create incorrect config
    silent call writefile( [ '{  }' ], '.vimspector.json' )

    call assert_true( filereadable( '.vimspector.json' ), 'Vimspector config should exist' )
    silent let l:config = utils#config#vimspector#updateConfig( {} )
    call assert_true( filereadable( '.vimspector.json' ), 'Vimspector config should exist' )
    call assert_true( empty( l:config ), 'Config should be empty!' )
endfunction

if !has( 'win32' )
    function! Test_Vimspector_Read_incorrect_vimspector_config()
        call assert_false( filereadable( '.vimspector.json' ), 'Vimspector config should not exist' )
        " Create incorrect config
        silent call writefile( readfile( '../../tests/integration/vimspector.vim' ), '.vimspector.json' )

        call assert_true( filereadable( '.vimspector.json' ), 'Vimspector config should exist' )
        silent let l:config = utils#config#vimspector#updateConfig( {} )
        call assert_true( filereadable( '.vimspector.json' ), 'Vimspector config should exist' )
        call assert_true( empty( l:config ), 'Config should be empty!' )
    endfunction

    function! Test_Vimspector_Read_correct_vimspector_config()
        call assert_false( filereadable( '.vimspector.json' ), 'Vimspector config should not exist' )
        " Create incorrect config
        silent call writefile( readfile( '../../tests/integration/.vimspector.json' ), '.vimspector.json' )

        call assert_true( filereadable( '.vimspector.json' ), 'Vimspector config should exist' )
        silent let l:config = utils#config#vimspector#updateConfig( {} )
        call assert_true( filereadable( '.vimspector.json' ), 'Vimspector config should exist' )

        call s:CheckConfigValidity( l:config )

        call assert_equal( '${workspaceRoot}/test_app',
                    \     l:config[ 'configurations' ][ 'test_app' ][ 'configuration' ][ 'program' ] )
        call assert_equal( 4,
                    \len( l:config[ 'configurations' ][ 'test_app' ][ 'configuration' ][ 'args' ] ) )

        call assert_true( has_key( l:config[ 'configurations' ], 'something_else' ), 'Config should have something_else' )
    endfunction

    function! Test_Vimspector_Change_correct_vimspector_config()
        call assert_false( filereadable( '.vimspector.json' ), 'Vimspector config should not exist' )
        " Create incorrect config
        silent call writefile( readfile( '../../tests/integration/.vimspector.json' ), '.vimspector.json' )

        call assert_true( filereadable( '.vimspector.json' ), 'Vimspector config should exist' )

        silent let l:config = utils#config#vimspector#updateConfig( { 'test_app': { 'app': 'new_bin/test_app', 'args': [] } } )
        call assert_true( filereadable( '.vimspector.json' ), 'Vimspector config should exist' )

        call s:CheckConfigValidity( l:config )

        call assert_true( empty  ( l:config[ 'configurations' ][ 'test_app' ][ 'configuration' ][ 'args' ] ) )
        call assert_equal( 'new_bin/test_app', l:config[ 'configurations' ][ 'test_app' ][ 'configuration' ][ 'program' ] )

        call assert_true( has_key( l:config[ 'configurations' ], 'something_else' ), 'Config should have something_else' )
    endfunction

    function! Test_Vimspector_Change_correct_vimspector_config_to_incorrect_data()
        call assert_false( filereadable( '.vimspector.json' ), 'Vimspector config should not exist' )
        " Create config
        silent call writefile( readfile( '../../tests/integration/.vimspector.json' ), '.vimspector.json' )

        call assert_true( filereadable( '.vimspector.json' ), 'Vimspector config should exist' )
        silent let l:config = utils#config#vimspector#updateConfig( {'test_app': {}} )
        call assert_true( empty( l:config), 'Config should be empty!' )
    endfunction
endif

if !has( 'win32' ) || utils#cmake#verNewerOrEq( [ 3, 14 ] )
    function! Test_Vimspector_Run_test_app_target_and_change_vimspector_config()
        silent CMake
        silent CMakeSelectTarget test_app
        silent CMakeBuild
        call assert_false( filereadable( '.vimspector.json' ), 'Vimspector config should not exist' )
        silent CMakeRun 1 2 3
        silent cclose
        call assert_true( filereadable( '.vimspector.json' ), 'Vimspector config should exist' )

        silent let l:config = utils#config#vimspector#updateConfig({})

        call s:CheckConfigValidity( l:config )

        if !has( 'win32' )
            call assert_equal( utils#cmake#getBuildDir() . '/app/test_app'          , config[ 'configurations' ][ 'test_app' ][ 'configuration' ][ 'program' ] )
        else
            call assert_equal( utils#cmake#getBuildDir() . '/app/Debug/test_app.exe', config[ 'configurations' ][ 'test_app' ][ 'configuration' ][ 'program' ] )
        endif
        call assert_equal( 3, len( l:config[ 'configurations' ][ 'test_app' ][ 'configuration' ][ 'args' ] ) )
        call assert_equal( [ '1', '2', '3' ], l:config[ 'configurations' ][ 'test_app' ][ 'configuration' ][ 'args' ] )

        call assert_equal( '1 2 3 F1', getqflist()[ 0 ].text )
    endfunction

    function! Test_Vimspector_Run_test_app_target_with_vimspector_args()
        call assert_false( filereadable( '.vimspector.json' ), 'Vimspector config should not exist' )

        " Create config
        silent call writefile( readfile( '../../tests/integration/.vimspector.json' ), '.vimspector.json' )

        call assert_true( filereadable( '.vimspector.json' ), 'Vimspector config should exist' )
        silent CMake
        silent CMakeSelectTarget test_app
        silent CMakeBuild
        silent CMakeRun
        silent cclose
        call assert_true( filereadable( '.vimspector.json' ), 'Vimspector config should exist' )
        silent let l:config = utils#config#vimspector#updateConfig({})

        call s:CheckConfigValidity( l:config )

        if !has( 'win32' )
            call assert_equal( utils#cmake#getBuildDir() . '/app/test_app'          , config[ 'configurations' ][ 'test_app' ][ 'configuration' ][ 'program' ] )
        else
            call assert_equal( utils#cmake#getBuildDir() . '/app/Debug/test_app.exe', config[ 'configurations' ][ 'test_app' ][ 'configuration' ][ 'program' ] )
        endif
        call assert_equal( 4, len( l:config[ 'configurations' ][ 'test_app' ][ 'configuration' ][ 'args' ] ) )

        call assert_equal( '1 2 3* 4 F1', getqflist()[ 0 ].text )
    endfunction

    function! Test_Vimspector_Run_test_app_target_with_reset_vimspector_args()
        call assert_false( filereadable( '.vimspector.json' ), 'Vimspector config should not exist' )
        " Create config
        silent call writefile( readfile( '../../tests/integration/.vimspector.json' ), '.vimspector.json' )

        call assert_true( filereadable( '.vimspector.json' ), 'Vimspector config should exist' )
        silent CMake
        silent CMakeSelectTarget test_app
        silent CMakeBuild
        silent CMakeRun!
        silent cclose
        call assert_true( filereadable( '.vimspector.json' ), 'Vimspector config should exist' )

        silent let l:config = utils#config#vimspector#updateConfig({})

        call s:CheckConfigValidity( l:config )

        if !has( 'win32' )
            call assert_equal( utils#cmake#getBuildDir() . '/app/test_app'          , l:config[ 'configurations' ][ 'test_app' ][ 'configuration' ][ 'program' ] )
        else
            call assert_equal( utils#cmake#getBuildDir() . '/app/Debug/test_app.exe', l:config[ 'configurations' ][ 'test_app' ][ 'configuration' ][ 'program' ] )
        endif
        call assert_true( empty( l:config[ 'configurations' ][ 'test_app' ][ 'configuration' ][ 'args' ] ) )

        call assert_equal( 'F1', getqflist()[ 0 ].text )
    endfunction

    function! Test_Vimspector_Read_vimspector_config_containing_backslashes()
        call assert_false( filereadable( '.vimspector.json' ), 'Vimspector config should not exist' )
        " Create config
        silent call writefile( readfile( '../../tests/integration/.vimspector.json' ), '.vimspector.json' )

        call assert_true( filereadable( '.vimspector.json' ), 'Vimspector config should exist' )
        silent CMake
        silent CMakeSelectTarget test_app
        silent CMakeBuild
        silent CMakeRun!
        silent cclose
        call assert_true( filereadable( '.vimspector.json' ), 'Vimspector config should exist' )
        silent let l:config = utils#config#vimspector#updateConfig( {} )
        call assert_true( has_key( l:config, 'configurations'                       ), 'Config should have configurations'                   )
        call assert_true( has_key( l:config[ 'configurations' ], 'with_backslashes' ), 'Config should have the target with_backslashes'      )
        call assert_equal( [ '--gtest_filter="Hello"' ], l:config[ 'configurations' ][ 'with_backslashes' ][ 'configuration' ][ 'args' ] )

        if !has( 'nvim' )
            call assert_equal( '"--gtest_filter=\"Hello\""', trim( readfile( '.vimspector.json' )[ 32 ] )  )
        endif
    endfunction
endif
