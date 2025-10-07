" === Создание/открытие CMakeLists.txt в выбранной папке NERDTree ===
function! CreateCMakeListsInNERDTree()
    if &filetype !=# 'nerdtree'
        echo "⚠️ Эта команда работает только в NERDTree"
        return
    endif

    " Получаем путь к текущему узлу NERDTree
    let current_path = g:NERDTreeFileNode.GetSelected().path.str()
    if empty(current_path)
        echo "⚠️ Не удалось получить путь"
        return
    endif

    " Определяем директорию
    if isdirectory(current_path)
        let target_dir = current_path
    else
        let target_dir = fnamemodify(current_path, ':h')
    endif

    " Путь к файлу CMakeLists.txt
    let cmake_file = target_dir . '/CMakeLists.txt'

    " Если файла нет — создаём
    if !filereadable(cmake_file)
        call system('touch ' . fnameescape(cmake_file))
        if v:shell_error
            echo "❌ Ошибка при создании файла: " . cmake_file
            return
        else
            echo "💾 Создан файл: " . cmake_file
            " Обновляем NERDTree
            NERDTreeRefreshRoot
        endif
    endif

    " Открываем файл в рабочем окне (NERDTree остаётся открытым)
    if winnr('$') > 1
        wincmd p
        execute 'edit' fnameescape(cmake_file)
    else
        execute 'vsplit' fnameescape(cmake_file)
    endif
endfunction

" === Генерация CMake для текущего CMakeLists.txt ===
function! CMakeGenerateLocal()
    let cmake_file = expand('%:p')
    if fnamemodify(cmake_file, ':t') !=# 'CMakeLists.txt'
        echo "⚠️ Выберите CMakeLists.txt для генерации"
        return
    endif

    let cmake_dir = fnamemodify(cmake_file, ':h')
    let debug_dir = cmake_dir . '/Debug'

    if !isdirectory(debug_dir)
        call system('mkdir -p ' . fnameescape(debug_dir))
    endif

    let cmd = 'cd ' . fnameescape(debug_dir) . ' && cmake ..'
    echo "Running: " . cmd
    let result = system(cmd)
    echo result

    if v:shell_error == 0
        echo "✓ CMake generated successfully in " . debug_dir
    else
        echo "✗ CMake generation failed in " . debug_dir
    endif
endfunction

" === Сборка для текущего CMakeLists.txt ===
function! CMakeBuildLocal()
    let cmake_file = expand('%:p')
    if fnamemodify(cmake_file, ':t') !=# 'CMakeLists.txt'
        echo "⚠️ Выберите CMakeLists.txt для сборки"
        return
    endif

    let cmake_dir = fnamemodify(cmake_file, ':h')
    let debug_dir = cmake_dir . '/Debug'

    if !isdirectory(debug_dir)
        echo "⚠️ Сначала сгенерируйте проект через CMakeGenerateLocal()"
        return
    endif

    let cmd = 'cd ' . fnameescape(debug_dir) . ' && make -j4'
    echo "Running: " . cmd
    let result = system(cmd)
    echo result

    if v:shell_error == 0
        echo "✓ Build successful in " . debug_dir
    else
        echo "✗ Build failed in " . debug_dir
    endif
endfunction

" --- Выбор исполняемого файла (F8) ---
function! CMakeSelectTargetInteractive()
    if !isdirectory('Debug')
        echo "⚠️ Нет папки Debug. Сначала вызови CMakeGenerate (F6)."
        return
    endif

    " Ищем все исполняемые файлы
    let all_executables = systemlist('find Debug -type f -perm +111 2>/dev/null')
    call filter(all_executables, 'v:val !~# "CMakeFiles"')

    if empty(all_executables)
        echo "❌ Исполняемые файлы не найдены."
        return
    endif

    echo "Выбери исполняемый файл:"
    let i = 1
    for exe in all_executables
        echo i . '. ' . exe
        let i += 1
    endfor

    let choice = input('Номер: ')
    if choice =~ '^\d\+$' && choice >= 1 && choice <= len(all_executables)
        let g:cmake_selected_target = all_executables[choice - 1]
        echo "✅ Выбран: " . g:cmake_selected_target
    else
        echo "🚫 Неверный выбор."
    endif
endfunction

" --- Запуск выбранного таргета (F9) ---
function! CMakeRunFixed()
    if empty(g:cmake_selected_target)
        echo "⚠️ Сначала выбери исполняемый файл (F8)."
        return
    endif

    if !filereadable(g:cmake_selected_target)
        echo "❌ Файл не найден: " . g:cmake_selected_target
        return
    endif

    let exe = g:cmake_selected_target
    echo "🚀 Запуск: " . exe
    execute '!./' . exe
endfunction

" --- Быстрый запуск (Shift+F8): генерировать + билд + автозапуск ---
function! CMakeQuickRun()
    if !isdirectory('Debug')
        call CMakeGenerateFixed()
    endif

    call CMakeBuildFixed()

    let auto_exe = systemlist('find Debug -type f -perm +111 2>/dev/null | grep -v CMakeFiles | head -1')
    if !empty(auto_exe)
        let g:cmake_selected_target = auto_exe[0]
        echo "✅ Автоматически выбран: " . g:cmake_selected_target
        call CMakeRunFixed()
    else
        echo "⚠️ Не найден исполняемый файл."
    endif
endfunction
