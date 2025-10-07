" === Подсветка сообщений ===
function! s:echo_info(msg)
    echohl Directory | echom a:msg | echohl None
endfunction

function! s:echo_success(msg)
    echohl Question | echom a:msg | echohl None
endfunction

function! s:echo_warn(msg)
    echohl WarningMsg | echom a:msg | echohl None
endfunction

function! s:echo_error(msg)
    echohl ErrorMsg | echom a:msg | echohl None
endfunction

" === Генерация CMake (F6) ===
function! CMakeGenerateFixed()
    let cmake_file = expand('%:p')
    if fnamemodify(cmake_file, ':t') !=# 'CMakeLists.txt'
        call s:echo_warn("⚠️  Выбери CMakeLists.txt")
        return
    endif

    let cmake_dir = fnamemodify(cmake_file, ':h')
    let build_dir = cmake_dir . '/' . g:cmake_build_type

    if !isdirectory(build_dir)
        call system('mkdir -p ' . fnameescape(build_dir))
    endif

    let cmd = 'cd ' . fnameescape(build_dir) . ' && cmake -DCMAKE_BUILD_TYPE=' . g:cmake_build_type . ' ..'
    call s:echo_info("🔧 Генерация (" . g:cmake_build_type . ")...")
    let result = system(cmd)
    echom result

    if v:shell_error == 0
        call s:echo_success("✅ Успешно сгенерировано → " . build_dir)
    else
        call s:echo_error("❌ Ошибка при генерации в " . build_dir)
    endif
endfunction

" === Сборка (F7) ===
function! CMakeBuildFixed()
    let cmake_file = expand('%:p')
    if fnamemodify(cmake_file, ':t') !=# 'CMakeLists.txt'
        call s:echo_warn("⚠️  Выбери CMakeLists.txt")
        return
    endif

    let cmake_dir = fnamemodify(cmake_file, ':h')
    let build_dir = cmake_dir . '/' . g:cmake_build_type

    if !isdirectory(build_dir)
        call s:echo_warn("⚠️  Сначала запусти генерацию (F6)")
        return
    endif

    let cmd = 'cd ' . fnameescape(build_dir) . ' && make -j4'
    call s:echo_info("⚙️  Сборка (" . g:cmake_build_type . ")...")
    let result = system(cmd)
    echom result

    if v:shell_error == 0
        call s:echo_success("✅ Сборка успешна в " . build_dir)
    else
        call s:echo_error("❌ Сборка не удалась")
    endif
endfunction

" === Выбор исполняемого файла (F8) ===
function! CMakeSelectTargetInteractive()
    let cmake_file = expand('%:p')
    if fnamemodify(cmake_file, ':t') !=# 'CMakeLists.txt'
        call s:echo_warn("⚠️  Выбери CMakeLists.txt")
        return
    endif

    let cmake_dir = fnamemodify(cmake_file, ':h')
    let build_dir = cmake_dir . '/' . g:cmake_build_type

    if !isdirectory(build_dir)
        call s:echo_warn("⚠️  Нет папки " . build_dir . ". Сначала сгенерируй проект (F6).")
        return
    endif

    " Исправленный поиск исполняемых файлов
    let all_executables = systemlist('find ' . fnameescape(build_dir) . ' -type f -executable ! -type d 2>/dev/null')
    call filter(all_executables, 'v:val !~# "CMakeFiles"')

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
function! CMakeRunFixed()
    if empty(g:cmake_selected_target)
        let cmake_file = expand('%:p')
        if fnamemodify(cmake_file, ':t') !=# 'CMakeLists.txt'
            call s:echo_warn("⚠️  Выбери CMakeLists.txt")
            return
        endif

        let cmake_dir = fnamemodify(cmake_file, ':h')
        let build_dir = cmake_dir . '/' . g:cmake_build_type

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
function! CMakeToggleBuildType()
    if g:cmake_build_type ==# 'Debug'
        let g:cmake_build_type = 'Release'
    else
        let g:cmake_build_type = 'Debug'
    endif
    call s:echo_info("🔁 Режим сборки: " . g:cmake_build_type)
endfunction

" === Быстрый запуск (\ + R + U) ===
function! CMakeQuickRun()
    let cmake_file = expand('%:p')
    if fnamemodify(cmake_file, ':t') !=# 'CMakeLists.txt'
        call s:echo_warn("⚠️  Выбери CMakeLists.txt")
        return
    endif

    let cmake_dir = fnamemodify(cmake_file, ':h')
    let build_dir = cmake_dir . '/' . g:cmake_build_type

    if !isdirectory(build_dir)
        call CMakeGenerateFixed()
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
