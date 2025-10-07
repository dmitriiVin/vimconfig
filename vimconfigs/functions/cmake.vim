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