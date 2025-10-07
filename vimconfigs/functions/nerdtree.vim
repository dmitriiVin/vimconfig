" === ФУНКЦИЯ СОЗДАНИЯ ФАЙЛА/ДИРЕКТОРИИ В NERDTREE === 
function! CreateFileOrDirectoryInNERDTree()
    if &filetype == 'nerdtree'
        " Получаем путь к текущему узлу NERDTree
        let current_path = g:NERDTreeFileNode.GetSelected().path.str()
        if empty(current_path)
            echo "Не удалось получить путь"
            return
        endif
        
        " Определяем директорию
        if isdirectory(current_path)
            let target_dir = current_path
        else
            let target_dir = fnamemodify(current_path, ':h')
        endif
        
        " Выбор типа: файл или папка
        let choice = confirm("Создать:", "&Файл\n&Папку", 1)
        
        if choice == 1
            " Создание файла
            let new_filename = input('Имя файла (с расширением): ', target_dir . '/')
            if new_filename != ''
                " Создаем файл
                let cmd = 'touch "' . new_filename . '"'
                let output = system(cmd)
                
                if v:shell_error
                    echo "Ошибка при создании файла: " . output
                else
                    echo "Создан файл: " . fnamemodify(new_filename, ':t')
                    " Обновляем NERDTree
                    NERDTreeRefreshRoot
                endif
            endif
            
        elseif choice == 2
            " Создание папки
            let new_dirname = input('Имя папки: ', target_dir . '/')
            if new_dirname != ''
                " Создаем папку
                let cmd = 'mkdir -p "' . new_dirname . '"'
                let output = system(cmd)
                
                if v:shell_error
                    echo "Ошибка при создании папки: " . output
                else
                    echo "Создана папка: " . fnamemodify(new_dirname, ':t')
                    " Обновляем NERDTree
                    NERDTreeRefreshRoot
                endif
            endif
        endif
    else
        echo "Эта команда работает только в NERDTree"
    endif
endfunction

" === ФУНКЦИЯ УДАЛЕНИЯ ФАЙЛА/ДИРЕКТОРИИ В NERDTREE ===
function! DeleteFileOrDirectory()
    if &filetype == 'nerdtree'
        " Получаем путь к выбранному файлу/папке
        let current_node = g:NERDTreeFileNode.GetSelected()
        if !empty(current_node)
            let path = current_node.path.str()
            let name = current_node.path.getLastPathComponent(1)

            " Подтверждение удаления
            let choice = confirm("Удалить '" . name . "'?", "&Yes\n&No", 2)
            if choice == 1
                " Удаляем файл или папку
                if isdirectory(path)
                    " Удаляем папку рекурсивно
                    let cmd = 'rm -rf "' . path . '"'
                else
                    " Удаляем файл
                    let cmd = 'rm "' . path . '"'
                endif

                " Выполняем удаление
                let output = system(cmd)
                if v:shell_error
                    echo "Ошибка при удалении: " . output
                else
                    echo "Удалено: " . name
                    " Обновляем NERDTree
                    NERDTreeRefreshRoot
                endif
            endif
        else
            echo "Не выбран файл или папка"
        endif
    else
        echo "Эта команда работает только в NERDTree"
    endif
endfunction

" === ПЕРЕХОД МЕЖДУ NERDTREE И РАБОЧЕЙ ОБЛАСТЬЮ ===
function! SwitchBetweenNERDTreeAndCode()
    " Если сейчас в NERDTree - переходим в рабочее окно
    if &filetype == 'nerdtree'
        wincmd l
        " Если не получилось перейти (нет других окон), создаем новое
        if &filetype == 'nerdtree'
            wincmd l
        endif
    " Если в рабочем окне - ищем NERDTree и переходим в него
    else
        " Ищем окно с NERDTree
        let nerdtree_winnr = -1
        for winnr in range(1, winnr('$'))
            if getbufvar(winbufnr(winnr), '&filetype') == 'nerdtree'
                let nerdtree_winnr = winnr
                break
            endif
        endfor

        " Если нашли NERDTree - переходим в него
        if nerdtree_winnr != -1
            execute nerdtree_winnr . 'wincmd w'
        " Если NERDTree не найден - открываем его
        else
            NERDTreeToggle
        endif
    endif
endfunction

" Создать новый файл в текущей директории с обновлением NERDTree (только в рабочей области)
function! CreateNewFile()
    if &filetype != 'nerdtree'
        let current_dir = expand("%:p:h")
        let new_file = input('New file name: ', current_dir . '/')
        if new_file != ''
            execute 'edit ' . new_file
            execute 'write'
            " Обновляем NERDTree если он открыт
            if exists(':NERDTreeRefreshRoot')
                NERDTreeRefreshRoot
            endif
        endif
    endif
endfunction
