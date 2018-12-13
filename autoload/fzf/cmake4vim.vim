" autoload/fzf.vim - FZF functionality for cmake4vim plugin
" Maintainer:   Ilya Churaev <https://github.com/ilyachur>
" Version:      0.2
if exists("loaded_fzf_cmake4vim")
  finish
endif
let loaded_ctrlp_cmake4vim = 1

function! fzf#cmake4vim#SelectTarget(...)
    if exists(':FZF')
        return fzf#run({
                    \ 'source': cmake4vim#GetAllTargets(),
                    \ 'options': '+m -d "\t" --with-nth 1,4.. -n 1 --tiebreak=index',
                    \ 'down':    '40%',
                    \ 'sink':    function('cmake4vim#SelectTarget')})
    endif
endfunction

