" === Подсветка сообщений ===
function! s:echo_info(msg)
    echohl Directory | echom a:msg | echohl None
endfunction

" === Подсветка сообщений: успех ===
function! s:echo_success(msg)
    echohl Question | echom a:msg | echohl None
endfunction

" === Подсветка сообщений: предупреждение ===
function! s:echo_warn(msg)
    echohl WarningMsg | echom a:msg | echohl None
endfunction

" === Подсветка сообщений: ошибка ===
function! s:echo_error(msg)
    echohl ErrorMsg | echom a:msg | echohl None
endfunction

" === Стабильное состояние последнего CMake-контекста ===
let g:cmake_last_workspace_root = get(g:, 'cmake_last_workspace_root', '')
let g:cmake_last_cmake_dir = get(g:, 'cmake_last_cmake_dir', '')
let g:cmake_last_build_dir = get(g:, 'cmake_last_build_dir', '')

" === Безопасный запуск CoC-команды, если она доступна ===
function! s:CocRunCommandIfExists(command_name) abort
    if !exists('*CocAction')
        return 0
    endif

    let l:commands = []
    try
        let l:commands = CocAction('commands')
    catch
        return 0
    endtry

    if index(l:commands, a:command_name) < 0
        return 0
    endif

    try
        call CocAction('runCommand', a:command_name)
        return 1
    catch
        return 0
    endtry
endfunction

" === Выбор CMakeLists.txt в текущем workspace ===
function! s:SelectCMakeFileInWorkspace(workspace_root, prompt_title) abort
    let l:cmake_files = systemlist('find ' . fnameescape(a:workspace_root) . ' -type f -name "CMakeLists.txt" 2>/dev/null')
    if empty(l:cmake_files)
        return ''
    endif

    " Если известен последний проект, выбираем его автоматически.
    if !empty(g:cmake_last_cmake_dir)
        for l:file in l:cmake_files
            if fnamemodify(l:file, ':h') ==# g:cmake_last_cmake_dir
                return l:file
            endif
        endfor
    endif

    if len(l:cmake_files) == 1
        return l:cmake_files[0]
    endif

    echo a:prompt_title
    for l:i in range(len(l:cmake_files))
        echo l:i + 1 . '. ' . l:cmake_files[l:i]
    endfor

    let l:choice = input('Номер: ')
    if l:choice !~ '^\d\+$' || l:choice < 1 || l:choice > len(l:cmake_files)
        call s:echo_warn("🚫 Неверный выбор")
        return ''
    endif

    return l:cmake_files[l:choice - 1]
endfunction

" === Найти ближайший CMakeLists.txt вверх по дереву ===
function! s:FindCMakeLists(start_dir) abort
    let l:dir = a:start_dir
    while l:dir !=# "/"
        let l:file = l:dir . "/CMakeLists.txt"
        if filereadable(l:file)
            return l:file
        endif
        let l:dir = fnamemodify(l:dir, ':h')
    endwhile
    return ""
endfunction

" === Генерация CMake (F6) ===
function! CMakeGenerateFixed() abort
    let l:origin_win = win_getid()
    let l:origin_is_nerdtree = &filetype ==# 'nerdtree'

    try
        " --- Поиск CMakeLists.txt в workspace ---
        let workspace_root = getcwd()
        let cmake_file = s:SelectCMakeFileInWorkspace(workspace_root, 'Выберите CMakeLists.txt для генерации:')
        if empty(cmake_file)
            call s:echo_error("❌ CMakeLists.txt не найден")
            return
        endif

        let cmake_dir = fnamemodify(cmake_file, ':h')
        let build_dir = cmake_dir . '/build/' . g:cmake_build_type

        if !isdirectory(build_dir)
            call system('mkdir -p ' . fnameescape(build_dir))
        endif

        " --- Генерация CMake с Ninja и Vcpkg ---
        let toolchain_arg = "-DCMAKE_TOOLCHAIN_FILE=/Users/dmitriivinogradov/vcpkg/scripts/buildsystems/vcpkg.cmake"
        let cmd = 'cmake -B ' . fnameescape(build_dir) . ' -S ' . fnameescape(cmake_dir) .
                    \ ' -G Ninja -DCMAKE_BUILD_TYPE=' . g:cmake_build_type . ' ' . toolchain_arg .
                    \ ' -DCMAKE_EXPORT_COMPILE_COMMANDS=ON'

        call s:echo_info("🔧 Генерация CMake (" . g:cmake_build_type . ") в " . build_dir . " ...")
        let result = system(cmd)
        echom result

        if v:shell_error == 0
            call s:echo_success("✅ CMake сгенерирован → " . build_dir)
            let g:cmake_last_workspace_root = workspace_root
            let g:cmake_last_cmake_dir = cmake_dir
            let g:cmake_last_build_dir = build_dir

            " --- Симлинк compile_commands.json в корень проекта ---
            let cc_path = build_dir . '/compile_commands.json'
            if filereadable(cc_path)
                let link_path = workspace_root . '/compile_commands.json'
                call system('ln -sf ' . fnameescape(cc_path) . ' ' . fnameescape(link_path))
                call s:echo_info("🔗 compile_commands.json → корень проекта")
            endif

            " --- Перезапуск CoC/LSP после обновления compile_commands.json ---
            if exists(':CocRestart')
                silent! CocRestart
            elseif exists('*CocAction')
                call s:CocRunCommandIfExists('workspace.reloadProjects')
                call s:CocRunCommandIfExists('clangd.restart')
            endif

            " Очистка quickfix безопасно
            call setqflist([], 'r')

            " Перерисовать экран
            redraw!

            call s:echo_info("♻️ Diagnostics обновлены")
        else
            call s:echo_error("❌ Ошибка при генерации в " . build_dir)
        endif
    finally
        if l:origin_win > 0
            silent! call win_gotoid(l:origin_win)
        endif
        if l:origin_is_nerdtree && exists(':NERDTreeRefreshRoot')
            silent! NERDTreeRefreshRoot
        endif
    endtry
endfunction

" === Сборка (F7) ===
function! CMakeBuildFixed() abort
    " Для nerdtree/quickfix собираем от cwd, иначе от текущего файла.
    let cur_dir = (&filetype ==# 'nerdtree' || &buftype ==# 'quickfix') ? getcwd() : expand('%:p:h')
    let cmake_file = s:FindCMakeLists(cur_dir)
    if empty(cmake_file)
        let cmake_file = s:SelectCMakeFileInWorkspace(getcwd(), 'Выберите CMakeLists.txt для сборки:')
    endif
    if empty(cmake_file)
        call s:echo_warn("⚠️  CMakeLists.txt не найден")
        return
    endif

    let cmake_dir = fnamemodify(cmake_file, ':h')
    let build_dir = cmake_dir . '/build/' . g:cmake_build_type

    if !isdirectory(build_dir)
        call s:echo_warn("⚠️  Папка сборки не найдена, запускаю генерацию (F6)...")
        let g:cmake_last_workspace_root = getcwd()
        let g:cmake_last_cmake_dir = cmake_dir
        call CMakeGenerateFixed()

        if !empty(g:cmake_last_build_dir) && isdirectory(g:cmake_last_build_dir)
            let build_dir = g:cmake_last_build_dir
        endif

        if !isdirectory(build_dir)
            call s:echo_error("❌ Не удалось подготовить папку сборки")
            return
        endif
    endif

    let g:cmake_last_workspace_root = getcwd()
    let g:cmake_last_cmake_dir = cmake_dir
    let g:cmake_last_build_dir = build_dir

    let cmd = 'cmake --build ' . fnameescape(build_dir)
    call s:echo_info("⚙️  Сборка (" . g:cmake_build_type . ") в " . build_dir . " ...")
    let result = system(cmd)
    echom result

    if v:shell_error == 0
        call s:echo_success("✅ Сборка успешна → " . build_dir)
    else
        call s:echo_error("❌ Сборка не удалась")
    endif
endfunction

" === Выбор исполняемого файла (F8) ===
function! CMakeSelectTargetInteractive() abort
    let cur_dir = expand('%:p:h')
    let cmake_file = s:FindCMakeLists(cur_dir)
    if empty(cmake_file)
        call s:echo_warn("⚠️  CMakeLists.txt не найден")
        return
    endif

    let cmake_dir = fnamemodify(cmake_file, ':h')
    let build_dir = cmake_dir . '/build/' . g:cmake_build_type

    if !isdirectory(build_dir)
        call s:echo_warn("⚠️  Нет папки " . build_dir . ". Сначала F6")
        return
    endif

    let all_executables = systemlist(
                \ 'find ' . fnameescape(build_dir) . ' -type f -perm +111 ' .
                \ '-not -name "*.a" -not -name "*.so" -not -name "*.dylib" -not -path "*/CMakeFiles/*" 2>/dev/null'
                \ )

    if empty(all_executables)
        call s:echo_error("❌ Исполняемые файлы не найдены в " . build_dir)
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
        call s:echo_success("✅ Выбран: " . g:cmake_selected_target)
    else
        call s:echo_warn("🚫 Неверный выбор.")
    endif
endfunction

" === Запуск выбранного таргета (F9) ===
function! CMakeRunFixed() abort
    if empty(g:cmake_selected_target)
        let cur_dir = expand('%:p:h')
        let cmake_file = s:FindCMakeLists(cur_dir)
        if empty(cmake_file)
            call s:echo_warn("⚠️  CMakeLists.txt не найден")
            return
        endif

        let cmake_dir = fnamemodify(cmake_file, ':h')
        let build_dir = cmake_dir . '/build/' . g:cmake_build_type

        let auto_exe = systemlist('find ' . fnameescape(build_dir) . ' -type f -executable ! -type d 2>/dev/null | grep -v CMakeFiles | head -1')
        if !empty(auto_exe)
            let g:cmake_selected_target = auto_exe[0]
            call s:echo_info("✅ Автоматически выбран: " . g:cmake_selected_target)
        else
            call s:echo_warn("⚠️  Исполняемый файл не найден (сначала F8 или сборка)")
            return
        endif
    endif

    if !filereadable(g:cmake_selected_target)
        call s:echo_error("❌ Файл не найден: " . g:cmake_selected_target)
        return
    endif

    let exe_dir = fnamemodify(g:cmake_selected_target, ':h')
    let exe_name = fnamemodify(g:cmake_selected_target, ':t')

    call s:echo_info("🚀 Запуск: " . exe_name . " (" . g:cmake_build_type . ")")
    execute '!cd ' . fnameescape(exe_dir) . ' && ./' . fnameescape(exe_name)
endfunction

" === Переключатель режима сборки (F10) ===
function! CMakeToggleBuildType() abort
    if g:cmake_build_type ==# 'Debug'
        let g:cmake_build_type = 'Release'
    else
        let g:cmake_build_type = 'Debug'
    endif
    call s:echo_info("🔁 Режим сборки: " . g:cmake_build_type)
endfunction

" === Создание/открытие CMakeLists.txt в NERDTree (F12) ===
function! CreateCMakeListsInNERDTree() abort
    if &filetype == 'nerdtree'
        let current_path = g:NERDTreeFileNode.GetSelected().path.str()
        if empty(current_path)
            echo "Не удалось получить путь"
            return
        endif

        if isdirectory(current_path)
            let target_dir = current_path
        else
            let target_dir = fnamemodify(current_path, ':h')
        endif

        let cmake_file = target_dir . '/CMakeLists.txt'
        if !filereadable(cmake_file)
            let basic_content = [
                        \ 'cmake_minimum_required(VERSION 3.10)',
                        \ '',
                        \ 'project(MyProject)',
                        \ '',
                        \ 'set(CMAKE_CXX_STANDARD 17)',
                        \ 'set(CMAKE_CXX_STANDARD_REQUIRED ON)',
                        \ '',
                        \ '# add_executable(${PROJECT_NAME} main.cpp)'
                        \ ]
            call writefile(basic_content, cmake_file)
            echo "Создан CMakeLists.txt с базовым конфигом"
        else
            echo "CMakeLists.txt уже существует"
        endif

        NERDTreeRefreshRoot
        wincmd p
        if &filetype == 'nerdtree'
            wincmd l
        endif
        execute 'edit ' . fnameescape(cmake_file)
    else
        echo "Эта команда работает только в NERDTree"
    endif
endfunction

" === Быстрый запуск (\ + R + U) ===
function! CMakeQuickRun() abort
    let cur_dir = expand('%:p:h')
    let cmake_file = s:FindCMakeLists(cur_dir)
    if empty(cmake_file)
        call s:echo_warn("⚠️  CMakeLists.txt не найден")
        return
    endif

    let build_dir = fnamemodify(cmake_file, ':h') . '/build/' . g:cmake_build_type
    if !isdirectory(build_dir)
        call CMakeGenerateFixed()
        if !empty(g:cmake_last_build_dir) && isdirectory(g:cmake_last_build_dir)
            let build_dir = g:cmake_last_build_dir
        endif
    endif

    call CMakeBuildFixed()

    let auto_exe = systemlist('find ' . fnameescape(build_dir) . ' -type f -executable ! -type d 2>/dev/null | grep -v CMakeFiles | head -1')
    if !empty(auto_exe)
        let g:cmake_selected_target = auto_exe[0]
        call s:echo_info("✅ Автоматически выбран: " . g:cmake_selected_target)
        call CMakeRunFixed()
    else
        call s:echo_warn("⚠️  Не найден исполняемый файл.")
    endif
endfunction

" ==== ПОКАЗАТЬ ТЕКУЩИЙ ТИП СБОРКИ ===
function! ShowCMakeBuildType() abort
    if exists("g:cmake_build_type")
        call s:echo_success("✅ Текущий тип сборки: " . g:cmake_build_type)
    else
        call s:echo_warn("⚠️  Тип сборки не установлен (по умолчанию: Debug)")
    endif
endfunction
