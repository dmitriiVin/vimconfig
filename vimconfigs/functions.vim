"=== Open CMakeLists === 
function!OpenCMakeLists()
    if &filetype == 'nerdtree'
        " В NERDTree ничего не делаем
        return
    else
        " В обычном буфере открываем CMakeLists.txt
        :e CMakeLists.txt
    endif
endfunction

" === ФУНКЦИЯ ГЕНЕРАЦИИ ===
function! CMakeGenerateFixed()
    " Создаем папку Debug если нужно
    if !isdirectory('Debug')
        call system('mkdir -p Debug')
    endif
    
    " Запускаем CMake генерацию
    let cmd = 'cd Debug && cmake ..'
    echo "Running: " . cmd
    let result = system(cmd)
    echo result
    
    if v:shell_error == 0
        echo "✓ CMake generated successfully!"
    else
        echo "✗ CMake generation failed"
    endif
endfunction

" === ФУНКЦИЯ БИЛДА ===
function! CMakeBuildFixed()
    if !isdirectory('Debug')
        echo "Run CMakeGenerate first! (F6)"
        return
    endif

    " Запускаем сборку
    let cmd = 'cd Debug && make -j4'
    echo "Running: " . cmd
    let result = system(cmd)
    echo result

    if v:shell_error == 0
        echo "✓ Build successful!"

        " Показываем что собралось
        let executables = system('find Debug -type f -executable 2>/dev/null')
        if !empty(executables)
            echo "Built executables:"
            echo executables
        endif
    else
        echo "✗ Build failed"
    endif
endfunction

" === ФУНКЦИЯ ВЫБОРА ТАРГЕТА ===
function! CMakeSelectTargetInteractive()
    if !isdirectory('Debug')
        echo "CMake not configured. Run CMakeGenerate first. (F6)"
        return
    endif

    " Ищем ВСЕ файлы в Debug (не только исполняемые)
    let all_files = system('find Debug -type f | grep -v CMakeFiles | head -20')
    let files = split(all_files, '\n')
    call filter(files, 'v:val != ""')
    
    if empty(files)
        echo "No files found in Debug directory."
        return
    endif

    " Показываем список файлов
    echo "Files in Debug directory:"
    let i = 1
    let executable_files = []
    
    for file in files
        let filename = fnamemodify(file, ':t')
        echo i . ". " . filename . "  (" . file . ")"
        
        " Проверяем является ли файл исполняемым
        if executable(file)
            call add(executable_files, file)
        endif
        
        let i += 1
    endfor

    " Если нашли исполняемые файлы, показываем их отдельно
    if !empty(executable_files)
        echo ""
        echo "Executable files (recommended):"
        let j = 1
        for exe_file in executable_files
            let exe_name = fnamemodify(exe_file, ':t')
            echo "E" . j . ". " . exe_name . "  [EXECUTABLE]"
            let j += 1
        endfor
    endif

    echo ""
    let choice = input('Select file (number) or "E" for executable: ')
    
    let selected_file = ''
    
    if choice =~ '^[Ee]\?\d\+$'
        if choice =~ '^[Ee]'
            " Выбор исполняемого файла
            let num = substitute(choice, '^[Ee]', '', '')
            if num >= 1 && num <= len(executable_files)
                let selected_file = executable_files[num - 1]
            endif
        else
            " Выбор любого файла по номеру
            if choice >= 1 && choice <= len(files)
                let selected_file = files[choice - 1]
            endif
        endif
    else
        " Поиск файла по имени
        for file in files
            if fnamemodify(file, ':t') == choice
                let selected_file = file
                break
            endif
        endfor
    endif

    if !empty(selected_file)
        let g:cmake_selected_target = selected_file
        let target_name = fnamemodify(selected_file, ':t')
        echo "✓ Target set to: " . target_name
        echo "  Full path: " . selected_file
    else
        echo "Invalid selection"
    endif
endfunction


" === ФУНКЦИЯ ЗАПУСКА ===
function! CMakeRunFixed()
    if empty(g:cmake_selected_target)
        echo "No target selected. Run CMakeSelectTarget first! (F8)"
        return
    endif
    
    if !filereadable(g:cmake_selected_target)
        echo "File not found: " . g:cmake_selected_target
        return
    endif
    
    let target_name = fnamemodify(g:cmake_selected_target, ':t')
    echo "Running: " . target_name
    
    " Проверяем права на выполнение
    if !executable(g:cmake_selected_target)
        echo "File is not executable. Trying to make executable..."
        call system('chmod +x ' . shellescape(g:cmake_selected_target))
    endif
    
    " Запускаем
    execute '!./' . g:cmake_selected_target
endfunction

" === БЫСТРЫЙ ЗАПУСК ===
function! CMakeQuickRun()
    " Сначала генерируем если нужно
    if !isdirectory('Debug')
        echo "Generating CMake..."
        call CMakeGenerateFixed()
        sleep 2
    endif
    
    " Собираем
    echo "Building project..."
    call CMakeBuildFixed()
    sleep 2
    
    " Автоматически выбираем первый исполняемый файл
    let executables = system('find Debug -type f -executable 2>/dev/null | head -1')
    let exe_files = split(executables, '\n')
    
    if !empty(exe_files)
        let g:cmake_selected_target = exe_files[0]
        let target_name = fnamemodify(exe_files[0], ':t')
        echo "✓ Auto-selected: " . target_name
        sleep 1
        
        " Запускаем
        call CMakeRunFixed()
    else
        echo "No executables found. Please select target manually (F8)"
    endif
endfunction

" ==== run code function ===
function! RunCode()
    let filename = expand('%')  " получаем имя файла
    let basename = expand('%:r') " получаем имя без расширения
    
    " Проверяем что файл существует
    if empty(filename)
        echo "No file to run"
        return
    endif
    
    if &filetype == 'cpp'
        execute '!clang++ -std=c++17 -O2 -Wall' filename '-o' basename '&& ./' . basename
    elseif &filetype == 'c'
        execute '!clang -std=c99 -O2 -Wall' filename '-o' basename '&& ./' . basename
    elseif &filetype == 'python'
        execute '!python' filename
    elseif &filetype == 'javascript'
        execute '!node' filename
    elseif &filetype == 'pascal'
        execute '!fpc' filename '&& ./' . basename
    else
        echo "Unsupported file type:" &filetype
    endif
endfunction

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
            let choice = confirm("Удалить '" . name . "'?", "&Да\n&Нет", 2)
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
