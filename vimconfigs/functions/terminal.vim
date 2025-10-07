" Умное автодополнение путей как в терминале
function! TerminalTabComplete()
    let cmdline = getcmdline()

    " Если вводим путь с / - дополняем как путь
    if cmdline =~ '.*/.*'
        return "\<C-x>\<C-f>"
    " Если команда начинается с :e, :find и т.д. - дополняем файлы
    elseif cmdline =~ '^:\?\(e\|find\|edit\)\s'
        return "\<C-x>\<C-f>"
    " Для других случаев - обычное дополнение
    else
        return "\<C-x>\<C-p>"
    endif
endfunction

function! SafeBufferSwitch()
    if &filetype != 'nerdtree'
        :b#
    endif
endfunction

" === ФУНКЦИЯ ДЛЯ БЕЗОПАСНОГО ОТКРЫТИЯ ФАЙЛОВ ===
function! SafeEdit()
    if &filetype != 'nerdtree'
        let file_path = input('Open file: ', '', 'file')
        if file_path != ''
            try
                execute 'edit ' . fnameescape(file_path)
            catch
                echo "Error opening file: " . v:exception
            endtry
        endif
    endif
endfunction