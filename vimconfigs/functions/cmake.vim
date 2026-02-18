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
function! s:IsIgnoredCMakePath(path) abort
    let l:path = fnamemodify(a:path, ':p')
    return l:path =~# '/\.vim-code-profiles/'
endfunction

function! s:SelectCMakeFileInWorkspace(workspace_root, prompt_title, ...) abort
    let l:force_prompt = get(a:000, 0, 0)
    let l:cmake_files = systemlist('find ' . fnameescape(a:workspace_root) . ' -type f -name "CMakeLists.txt" 2>/dev/null')
    call filter(l:cmake_files, '!s:IsIgnoredCMakePath(v:val)')
    if empty(l:cmake_files)
        return ''
    endif

    call sort(l:cmake_files)

    " Если известен последний проект, выбираем его автоматически.
    if !l:force_prompt && !empty(g:cmake_last_cmake_dir)
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

" === Варианты папки сборки для текущего build type ===
function! s:GetBuildDirCandidates(cmake_dir) abort
    let l:raw_type = g:cmake_build_type
    let l:lower_type = tolower(g:cmake_build_type)
    let l:candidates = []

    if g:cmake_last_cmake_dir ==# a:cmake_dir && !empty(g:cmake_last_build_dir)
        let l:last_type = fnamemodify(g:cmake_last_build_dir, ':t')
        if l:last_type ==# l:lower_type || l:last_type ==# l:raw_type
            call add(l:candidates, g:cmake_last_build_dir)
        endif
    endif

    call add(l:candidates, a:cmake_dir . '/build/' . l:lower_type)
    call add(l:candidates, a:cmake_dir . '/build/' . l:raw_type)

    return uniq(l:candidates)
endfunction

" === Найти существующую папку сборки, иначе вернуть дефолт ===
function! s:ResolveBuildDir(cmake_dir) abort
    let l:candidates = s:GetBuildDirCandidates(a:cmake_dir)

    for l:dir in l:candidates
        if isdirectory(l:dir)
            return l:dir
        endif
    endfor

    return l:candidates[0]
endfunction

" === Локальные профили кода (без Git/GitHub): Debug/Release ===
function! s:GetCodeProfileName(build_type) abort
    return tolower(a:build_type) ==# 'release' ? 'release' : 'debug'
endfunction

function! s:GetCodeProfilesRoot(cmake_dir) abort
    return a:cmake_dir . '/.vim-code-profiles'
endfunction

function! s:GetCodeProfileDir(cmake_dir, profile_name) abort
    return s:GetCodeProfilesRoot(a:cmake_dir) . '/' . a:profile_name
endfunction

function! s:GetCodeProfileStateFile(cmake_dir) abort
    return s:GetCodeProfilesRoot(a:cmake_dir) . '/active_profile'
endfunction

function! s:GetCodeProfileExcludes() abort
    return [
                \ '--exclude=.vim-code-profiles/',
                \ '--exclude=build/',
                \ '--exclude=Build/',
                \ '--exclude=Debug/',
                \ '--exclude=Release/',
                \ '--exclude=debug/',
                \ '--exclude=release/',
                \ '--exclude=CMakeFiles/',
                \ '--exclude=CMakeCache.txt',
                \ '--exclude=compile_commands.json',
                \ '--exclude=cmake_install.cmake',
                \ '--exclude=Makefile',
                \ '--exclude=.git/',
                \ '--exclude=.DS_Store',
                \ '--exclude=\*.swp',
                \ '--exclude=\*.swo'
                \ ]
endfunction

function! s:IsDirEmpty(path) abort
    return !isdirectory(a:path) || empty(readdir(a:path))
endfunction

function! s:SyncTree(src_dir, dst_dir) abort
    call mkdir(a:dst_dir, 'p')
    " --no-owner/--no-group нужны для Linux без прав на chown/chgrp.
    let l:cmd = 'rsync -a --delete --no-owner --no-group --no-perms ' . join(s:GetCodeProfileExcludes(), ' ')
                \ . ' ' . shellescape(a:src_dir . '/')
                \ . ' ' . shellescape(a:dst_dir . '/')
                \ . ' </dev/null 2>&1'
    let l:result = system(l:cmd)
    return [v:shell_error, l:result]
endfunction

function! s:ReadActiveCodeProfile(cmake_dir) abort
    let l:state_file = s:GetCodeProfileStateFile(a:cmake_dir)
    if filereadable(l:state_file)
        let l:lines = readfile(l:state_file)
        if !empty(l:lines)
            let l:name = trim(l:lines[0])
            if l:name ==# 'debug' || l:name ==# 'release'
                return l:name
            endif
        endif
    endif
    return ''
endfunction

function! s:WriteActiveCodeProfile(cmake_dir, profile_name) abort
    call mkdir(s:GetCodeProfilesRoot(a:cmake_dir), 'p')
    call writefile([a:profile_name], s:GetCodeProfileStateFile(a:cmake_dir))
endfunction

function! s:EnsureCodeProfiles(cmake_dir) abort
    let l:profiles_root = s:GetCodeProfilesRoot(a:cmake_dir)
    let l:debug_dir = s:GetCodeProfileDir(a:cmake_dir, 'debug')
    let l:release_dir = s:GetCodeProfileDir(a:cmake_dir, 'release')
    call mkdir(l:debug_dir, 'p')
    call mkdir(l:release_dir, 'p')

    if s:IsDirEmpty(l:debug_dir)
        let [l:code, l:msg] = s:SyncTree(a:cmake_dir, l:debug_dir)
        if l:code != 0
            call s:echo_error("❌ Не удалось инициализировать debug-профиль")
            echom l:msg
            return 0
        endif
    endif

    if s:IsDirEmpty(l:release_dir)
        let [l:code, l:msg] = s:SyncTree(a:cmake_dir, l:release_dir)
        if l:code != 0
            call s:echo_error("❌ Не удалось инициализировать release-профиль")
            echom l:msg
            return 0
        endif
    endif

    if empty(s:ReadActiveCodeProfile(a:cmake_dir))
        call s:WriteActiveCodeProfile(a:cmake_dir, s:GetCodeProfileName(g:cmake_build_type))
    endif

    return 1
endfunction

function! s:HasModifiedWorkBuffers() abort
    for l:buf in getbufinfo({'bufloaded': 1})
        if getbufvar(l:buf.bufnr, '&buftype') ==# '' && getbufvar(l:buf.bufnr, '&modified')
            return 1
        endif
    endfor
    return 0
endfunction

function! s:SaveAllWorkBuffers() abort
    " Для F10 сохраняем без автокоманд, иначе BufWritePost/NERDTree/Coc могут подвешивать Vim.
    silent! noautocmd wall
    return !s:HasModifiedWorkBuffers()
endfunction

function! s:SwitchCodeProfile(cmake_dir, old_build_type, new_build_type) abort
    if !s:EnsureCodeProfiles(a:cmake_dir)
        return 0
    endif

    let l:from_profile = s:GetCodeProfileName(a:old_build_type)
    let l:to_profile = s:GetCodeProfileName(a:new_build_type)
    if l:from_profile ==# l:to_profile
        return 1
    endif

    let l:active_profile = s:ReadActiveCodeProfile(a:cmake_dir)
    if empty(l:active_profile)
        let l:active_profile = l:from_profile
    endif

    let l:from_dir = s:GetCodeProfileDir(a:cmake_dir, l:active_profile)
    let l:to_dir = s:GetCodeProfileDir(a:cmake_dir, l:to_profile)

    if s:HasModifiedWorkBuffers() && !s:SaveAllWorkBuffers()
        call s:echo_warn("⚠️  Не все буферы удалось сохранить перед переключением профиля")
        return 0
    endif

    let [l:save_code, l:save_msg] = s:SyncTree(a:cmake_dir, l:from_dir)
    if l:save_code != 0
        call s:echo_error("❌ Не удалось сохранить текущую версию кода (" . l:active_profile . ")")
        echom l:save_msg
        return 0
    endif

    let [l:load_code, l:load_msg] = s:SyncTree(l:to_dir, a:cmake_dir)
    if l:load_code != 0
        call s:echo_error("❌ Не удалось загрузить версию кода (" . l:to_profile . ")")
        echom l:load_msg
        return 0
    endif

    call s:WriteActiveCodeProfile(a:cmake_dir, l:to_profile)
    call s:ReloadProjectBuffers(a:cmake_dir)

    if exists(':NERDTreeRefreshRoot')
        silent! noautocmd NERDTreeRefreshRoot
    endif
    if exists('*CocActionAsync')
        silent! call CocActionAsync('diagnosticRefresh')
    elseif exists('*CocAction')
        silent! call CocAction('diagnosticRefresh')
    endif

    call s:echo_success("✅ Активирована версия кода: " . l:to_profile)
    return 1
endfunction

" === Принудительно перечитать буферы проекта после подмены версии кода ===
function! s:ReloadProjectBuffers(project_root) abort
    let l:root = fnamemodify(a:project_root, ':p')
    let l:origin_win = win_getid()
    let l:origin_buf = bufnr('%')

    for l:buf in getbufinfo({'bufloaded': 1})
        if l:buf.bufnr <= 0
            continue
        endif

        if getbufvar(l:buf.bufnr, '&buftype') !=# ''
            continue
        endif
        if getbufvar(l:buf.bufnr, '&modified')
            continue
        endif

        let l:path = fnamemodify(bufname(l:buf.bufnr), ':p')
        if empty(l:path) || stridx(l:path, l:root) != 0
            continue
        endif

        execute 'silent! noautocmd keepalt buffer ' . l:buf.bufnr
        silent! noautocmd edit!
    endfor

    if bufexists(l:origin_buf)
        execute 'silent! noautocmd keepalt buffer ' . l:origin_buf
    endif
    if l:origin_win > 0
        silent! call win_gotoid(l:origin_win)
    endif
endfunction

" === Привязать выбранный исполняемый файл к новому build type ===
function! s:RetargetSelectedExecutable(cmake_dir) abort
    let l:build_dir = s:ResolveBuildDir(a:cmake_dir)
    let l:executables = s:GetExecutableCandidates(l:build_dir)

    if empty(l:executables)
        let g:cmake_selected_target = ''
        return
    endif

    if empty(g:cmake_selected_target)
        let g:cmake_selected_target = l:executables[0]
        return
    endif

    let l:old_name = fnamemodify(g:cmake_selected_target, ':t')
    for l:exe in l:executables
        if fnamemodify(l:exe, ':t') ==# l:old_name
            let g:cmake_selected_target = l:exe
            return
        endif
    endfor

    let g:cmake_selected_target = l:executables[0]
endfunction

" === Найти toolchain-файл vcpkg автоматически ===
function! s:DetectVcpkgToolchain(workspace_root, cmake_dir) abort
    if exists('g:cmake_vcpkg_toolchain_file') && !empty(g:cmake_vcpkg_toolchain_file) && filereadable(g:cmake_vcpkg_toolchain_file)
        return g:cmake_vcpkg_toolchain_file
    endif

    let l:candidate_roots = []

    if exists('$VCPKG_ROOT') && !empty($VCPKG_ROOT)
        call add(l:candidate_roots, $VCPKG_ROOT)
    endif

    if exists('g:cmake_vcpkg_root') && !empty(g:cmake_vcpkg_root)
        call add(l:candidate_roots, g:cmake_vcpkg_root)
    endif

    call add(l:candidate_roots, a:workspace_root . '/vcpkg')
    call add(l:candidate_roots, a:cmake_dir . '/vcpkg')
    call add(l:candidate_roots, expand('~/vcpkg'))
    call add(l:candidate_roots, expand('~/.vcpkg'))

    let l:vcpkg_exe = exepath('vcpkg')
    if !empty(l:vcpkg_exe)
        call add(l:candidate_roots, fnamemodify(resolve(l:vcpkg_exe), ':h'))
    endif

    let l:normalized_roots = uniq(map(l:candidate_roots, 'fnamemodify(v:val, ":p")'))
    for l:root in l:normalized_roots
        if empty(l:root)
            continue
        endif

        let l:toolchain_path = l:root . '/scripts/buildsystems/vcpkg.cmake'
        if filereadable(l:toolchain_path)
            let g:cmake_vcpkg_root = l:root
            let g:cmake_vcpkg_toolchain_file = l:toolchain_path
            return l:toolchain_path
        endif
    endfor

    return ''
endfunction

" === Генерация CMake для выбранной директории ===
function! s:GenerateForDirectory(workspace_root, cmake_dir) abort
    let l:build_dir = s:ResolveBuildDir(a:cmake_dir)
    if !isdirectory(l:build_dir)
        call mkdir(l:build_dir, 'p')
    endif

    " --- Генерация CMake с Ninja и (опционально) vcpkg ---
    let l:toolchain_file = s:DetectVcpkgToolchain(a:workspace_root, a:cmake_dir)
    let l:toolchain_arg = empty(l:toolchain_file) ? '' : ' -DCMAKE_TOOLCHAIN_FILE=' . fnameescape(l:toolchain_file)

    let cmd = 'cmake -B ' . fnameescape(l:build_dir) . ' -S ' . fnameescape(a:cmake_dir) .
                \ ' -G Ninja -DCMAKE_BUILD_TYPE=' . g:cmake_build_type . l:toolchain_arg .
                \ ' -DCMAKE_EXPORT_COMPILE_COMMANDS=ON'

    call s:echo_info("🔧 Генерация CMake (" . g:cmake_build_type . ") в " . l:build_dir . " ...")
    if !empty(l:toolchain_file)
        call s:echo_info("📦 Используется vcpkg toolchain: " . l:toolchain_file)
    endif
    let result = system(cmd)
    echom result

    if v:shell_error != 0
        call s:echo_error("❌ Ошибка при генерации в " . l:build_dir)
        return ''
    endif

    call s:echo_success("✅ CMake сгенерирован → " . l:build_dir)
    let g:cmake_last_workspace_root = a:workspace_root
    let g:cmake_last_cmake_dir = a:cmake_dir
    let g:cmake_last_build_dir = l:build_dir

    " --- Симлинк compile_commands.json в корень проекта ---
    let cc_path = l:build_dir . '/compile_commands.json'
    if filereadable(cc_path)
        let link_path = a:workspace_root . '/compile_commands.json'
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

    call setqflist([], 'r')
    redraw!
    call s:echo_info("♻️ Diagnostics обновлены")

    return l:build_dir
endfunction

" === Найти ближайший CMakeLists.txt вверх по дереву ===
function! s:FindCMakeLists(start_dir) abort
    let l:dir = fnamemodify(empty(a:start_dir) ? getcwd() : a:start_dir, ':p')
    while 1
        let l:file = l:dir . '/CMakeLists.txt'
        if filereadable(l:file) && !s:IsIgnoredCMakePath(l:file)
            return l:file
        endif

        let l:parent = fnamemodify(l:dir, ':h')
        if l:parent ==# l:dir
            break
        endif
        let l:dir = l:parent
    endwhile
    return ''
endfunction

" === Предпочтительный CMakeLists для F7: корень cwd, иначе текущий буфер и выше ===
function! s:FindPreferredCMakeForBuild() abort
    let l:cmake_file = s:FindCMakeLists(getcwd())
    if !empty(l:cmake_file)
        return l:cmake_file
    endif

    let l:buffer_dir = expand('%:p:h')
    if !empty(l:buffer_dir)
        return s:FindCMakeLists(l:buffer_dir)
    endif

    return ''
endfunction

" === Генерация CMake (F6) ===
function! CMakeGenerateFixed() abort
    let l:origin_win = win_getid()
    let l:origin_is_nerdtree = &filetype ==# 'nerdtree'

    try
        " --- Поиск CMakeLists.txt в workspace ---
        let workspace_root = getcwd()
        let cmake_file = s:SelectCMakeFileInWorkspace(workspace_root, 'Выберите CMakeLists.txt для генерации:', 1)
        if empty(cmake_file)
            call s:echo_error("❌ CMakeLists.txt не найден")
            return
        endif

        let cmake_dir = fnamemodify(cmake_file, ':h')
        let build_dir = s:GenerateForDirectory(workspace_root, cmake_dir)
        if empty(build_dir)
            return
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
    let cmake_file = s:FindPreferredCMakeForBuild()
    if empty(cmake_file)
        call s:echo_warn("⚠️  CMakeLists.txt не найден (поиск: cwd и родительские директории)")
        return
    endif

    let workspace_root = fnamemodify(cmake_file, ':h')
    let cmake_dir = fnamemodify(cmake_file, ':h')
    let build_dir = s:ResolveBuildDir(cmake_dir)

    if !isdirectory(build_dir)
        call s:echo_warn("⚠️  Папка сборки не найдена, запускаю автогенерацию...")
        let build_dir = s:GenerateForDirectory(workspace_root, cmake_dir)

        if !isdirectory(build_dir)
            call s:echo_error("❌ Не удалось подготовить папку сборки")
            return
        endif
    endif

    let g:cmake_last_workspace_root = workspace_root
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

" === Удаление папки сборки (F3) ===
function! CMakeDeleteBuildDir() abort
    let l:cmake_file = s:FindPreferredCMakeForBuild()
    if empty(l:cmake_file)
        call s:echo_warn("⚠️  CMakeLists.txt не найден (поиск: cwd и родительские директории)")
        return
    endif

    let l:cmake_dir = fnamemodify(l:cmake_file, ':h')
    let l:build_root = l:cmake_dir . '/build'

    if !isdirectory(l:build_root)
        call s:echo_warn("⚠️  Папка build не найдена: " . l:build_root)
        return
    endif

    if confirm("Удалить папку сборки?\n" . l:build_root, "&Yes\n&No", 2) != 1
        call s:echo_info("ℹ️  Удаление build отменено")
        return
    endif

    if delete(l:build_root, 'rf') != 0
        call s:echo_error("❌ Не удалось удалить папку build: " . l:build_root)
        return
    endif

    let l:cc_candidates = [
                \ fnamemodify(getcwd(), ':p') . 'compile_commands.json',
                \ l:cmake_dir . '/compile_commands.json'
                \ ]
    let l:build_root_abs = fnamemodify(l:build_root, ':p')

    for l:cc_path in uniq(l:cc_candidates)
        if getftype(l:cc_path) !=# 'link'
            continue
        endif

        let l:cc_target = fnamemodify(resolve(l:cc_path), ':p')
        if stridx(l:cc_target, l:build_root_abs . '/') == 0
            call delete(l:cc_path)
        endif
    endfor

    if get(g:, 'cmake_last_cmake_dir', '') ==# l:cmake_dir
        let g:cmake_last_build_dir = ''
    endif
    let g:cmake_selected_target = ''

    if exists(':CocRestart')
        silent! CocRestart
    elseif exists('*CocAction')
        call s:CocRunCommandIfExists('workspace.reloadProjects')
        call s:CocRunCommandIfExists('clangd.restart')
    endif
    call setqflist([], 'r')

    call s:echo_success("🧹 Папка build удалена: " . l:build_root)
endfunction

" === Найти исполняемые файлы для запуска ===
function! s:GetExecutableCandidates(build_dir) abort
    let l:executables = systemlist(
                \ 'find ' . fnameescape(a:build_dir) . ' -type f -perm -111 ' .
                \ '-not -name "*.a" -not -name "*.so" -not -name "*.dylib" ' .
                \ '-not -path "*/CMakeFiles/*" -not -path "*/.vim-code-profiles/*" 2>/dev/null'
                \ )
    call sort(l:executables)
    return l:executables
endfunction

" === Выбор исполняемого файла (F8) ===
function! CMakeSelectTargetInteractive() abort
    let cmake_file = s:FindPreferredCMakeForBuild()
    if empty(cmake_file)
        call s:echo_warn("⚠️  CMakeLists.txt не найден (поиск: cwd и родительские директории)")
        return
    endif

    let cmake_dir = fnamemodify(cmake_file, ':h')
    let build_dir = s:ResolveBuildDir(cmake_dir)

    if !isdirectory(build_dir)
        call s:echo_warn("⚠️  Нет папки сборки (" . cmake_dir . "/build/debug или /build/release). Сначала F6")
        return
    endif

    let all_executables = s:GetExecutableCandidates(build_dir)

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
        let cmake_file = s:FindPreferredCMakeForBuild()
        if empty(cmake_file)
            call s:echo_warn("⚠️  CMakeLists.txt не найден (поиск: cwd и родительские директории)")
            return
        endif

        let cmake_dir = fnamemodify(cmake_file, ':h')
        let build_dir = s:ResolveBuildDir(cmake_dir)
        if !isdirectory(build_dir)
            call s:echo_warn("⚠️  Папка сборки не найдена (сначала F6 или F7)")
            return
        endif

        let l:executables = s:GetExecutableCandidates(build_dir)
        if !empty(l:executables)
            let g:cmake_selected_target = l:executables[0]
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
    let l:old_build_type = g:cmake_build_type
    let l:cmake_file = s:FindPreferredCMakeForBuild()
    let l:cmake_dir = empty(l:cmake_file) ? getcwd() : fnamemodify(l:cmake_file, ':h')
    if g:cmake_build_type ==# 'Debug'
        let g:cmake_build_type = 'Release'
    else
        let g:cmake_build_type = 'Debug'
    endif
    call s:echo_info("🔁 Режим сборки: " . g:cmake_build_type)

    " Переключаем локальную версию кода (debug/release) в пределах проекта.
    if get(g:, 'cmake_sync_code_profile_with_build_type', 1)
        if !s:SwitchCodeProfile(l:cmake_dir, l:old_build_type, g:cmake_build_type)
            " Если переключение кода сорвалось, откатываем build type.
            let g:cmake_build_type = l:old_build_type
            call s:echo_warn("↩️  Режим сборки возвращен: " . g:cmake_build_type)
            return
        endif
    endif

    call s:RetargetSelectedExecutable(l:cmake_dir)
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
    let cmake_file = s:FindPreferredCMakeForBuild()
    if empty(cmake_file)
        call s:echo_warn("⚠️  CMakeLists.txt не найден (поиск: cwd и родительские директории)")
        return
    endif

    let workspace_root = fnamemodify(cmake_file, ':h')
    let cmake_dir = fnamemodify(cmake_file, ':h')
    let build_dir = s:ResolveBuildDir(cmake_dir)
    if !isdirectory(build_dir)
        let build_dir = s:GenerateForDirectory(workspace_root, cmake_dir)
        if !isdirectory(build_dir)
            call s:echo_error("❌ Не удалось определить build-папку после генерации")
            return
        endif
    endif

    call CMakeBuildFixed()
    let build_dir = s:ResolveBuildDir(cmake_dir)

    let l:executables = s:GetExecutableCandidates(build_dir)
    if !empty(l:executables)
        let g:cmake_selected_target = l:executables[0]
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
