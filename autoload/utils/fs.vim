" autoload/utils/fs.vim - contains function to work with the file system
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>

" Create directory
function! utils#fs#makeDir(dir) abort
    let l:directory = finddir( a:dir, fnameescape(getcwd()) )
    if !empty( l:directory )
        return fnamemodify( l:directory, ':p:h' )
    endif

    let l:created = 0
    try
        let l:created =  mkdir(a:dir, 'p')
    catch
    endtry
    if l:created == 0
        call utils#common#Warning( 'Cannot create a build directory: '.a:dir )
        return ''
    endif

    return fnamemodify( a:dir, ':p:h' )
endfunction

" Remove directory
function! utils#fs#removeDirectory(file) abort
    if has('win32')
        silent call system('rd /S /Q ' . utils#fs#fnameescape(a:file))
    else
        silent call system('rm -rf ' . utils#fs#fnameescape(a:file))
    endif
endfunction

" Remove file
function! utils#fs#removeFile(file) abort
    if has('win32')
        silent call system('del /F /Q ' . utils#fs#fnameescape(a:file))
    else
        silent call system('rm -rf ' . utils#fs#fnameescape(a:file))
    endif
endfunction

" Create a link
function! utils#fs#createLink(src, dst) abort
    " Need to wait for end of Dispatch Make
    " if !filereadable(a:src)
    "     return
    " endif
    silent call utils#fs#removeFile(a:dst)
    if has('win32')
        silent call system('copy ' . utils#fs#fnameescape(a:src) . ' ' . utils#fs#fnameescape(a:dst))
    else
        silent call system('ln -s ' . utils#fs#fnameescape(a:src) . ' ' . utils#fs#fnameescape(a:dst))
    endif
endfunction

" Extends default fnameescape, adds double quotes for Windows
function! utils#fs#fnameescape(file) abort
    " TODO: could this be replaced with shellescape()?
    if has('win32')
        let l:path = substitute(a:file, '\/', '\\', 'g')
        if l:path !=# ''
            let l:path = '"' . l:path . '"'
        endif
        return l:path
    else
        return fnameescape(a:file)
    endif
endfunction
