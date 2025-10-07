" === ФУНКЦИЯ: Полное закрытие всех Git-сплитов ===
function! GitSaveAndClose()
    " Сохраняем буфер, если он изменён
    if &modifiable && &modified
        write
        echo "💾 Git buffer saved"
    endif

    " Проверяем, Git ли это
    if &filetype =~# 'git\|gitcommit\|gitrebase\|gitconfig'
        " Получаем список всех окон
        let l:wins = range(1, winnr('$'))

        " Закрываем все окна с Git-буферами с конца
        for w in reverse(l:wins)
            let l:buf = winbufnr(w)
            if getbufvar(l:buf, '&filetype') =~# 'git\|gitcommit\|gitrebase\|gitconfig'
                execute w . 'wincmd c'
            endif
        endfor

        echo "🚪 All Git splits closed"
    else
        bd
    endif
endfunction