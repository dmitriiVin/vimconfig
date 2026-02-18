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

" === Найти корень текущего Git-репозитория ===
function! s:GetGitRoot() abort
    let l:git_root = trim(system('git rev-parse --show-toplevel 2>/dev/null'))
    if v:shell_error != 0 || empty(l:git_root)
        return ''
    endif
    return fnamemodify(l:git_root, ':p:h')
endfunction

" === Убедиться, что локальный Git-репозиторий существует ===
function! s:EnsureLocalGitRepo(...) abort
    let l:silent_mode = get(a:000, 0, 0)
    if !empty(s:GetGitRoot())
        return 1
    endif

    if l:silent_mode
        return 0
    endif

    let l:init_now = confirm(
                \ "Локальный Git-репозиторий не найден.\nИнициализировать его в текущей папке?",
                \ "&Yes\n&No",
                \ 1
                \ )
    if l:init_now != 1
        echohl WarningMsg | echom "🚫 Локальный Git не инициализирован" | echohl None
        return 0
    endif

    let l:init_result = system('git init 2>&1')
    if v:shell_error != 0
        echohl ErrorMsg | echom "❌ Не удалось выполнить git init" | echohl None
        echom l:init_result
        return 0
    endif

    if empty(trim(system('git config --local user.name 2>/dev/null')))
        call system('git config --local user.name ' . shellescape('Local Vim User') . ' 2>&1')
    endif
    if empty(trim(system('git config --local user.email 2>/dev/null')))
        call system('git config --local user.email ' . shellescape('local@vim.local') . ' 2>&1')
    endif

    call system('git rev-parse --verify HEAD >/dev/null 2>&1')
    if v:shell_error != 0
        let l:commit_result = system('git add -A && git commit --allow-empty -m ' . shellescape('Initial local snapshot') . ' 2>&1')
        if v:shell_error != 0
            echohl ErrorMsg | echom "❌ Не удалось создать первый локальный commit" | echohl None
            echom l:commit_result
            return 0
        endif
    endif

    echohl Question | echom "✅ Локальный Git инициализирован в " . getcwd() | echohl None
    call s:AutoSetupOriginAfterInit()
    return !empty(s:GetGitRoot())
endfunction

" === Построить URL origin из шаблона ===
function! s:BuildOriginUrlFromTemplate(template) abort
    let l:repo_name = fnamemodify(getcwd(), ':t')
    return substitute(a:template, '{repo}', l:repo_name, 'g')
endfunction

" === Получить owner/repo из GitHub URL ===
function! s:GetGithubRepoSlug(remote_url) abort
    let l:url = substitute(a:remote_url, '/\+$', '', '')
    let l:url = substitute(l:url, '\.git$', '', '')

    if l:url =~# '^git@github\.com:'
        return substitute(l:url, '^git@github\.com:', '', '')
    endif
    if l:url =~# '^https\?://github\.com/'
        return substitute(l:url, '^https\?://github\.com/', '', '')
    endif
    if l:url =~# '^ssh://git@github\.com/'
        return substitute(l:url, '^ssh://git@github\.com/', '', '')
    endif

    return ''
endfunction

" === Убедиться, что origin существует на GitHub ===
function! s:EnsureOriginRemoteExists() abort
    let l:origin_url = trim(system('git remote get-url origin 2>/dev/null'))
    if v:shell_error != 0 || empty(l:origin_url)
        return 0
    endif

    call system('git ls-remote origin 2>/dev/null')
    if v:shell_error == 0
        return 1
    endif

    if !get(g:, 'git_auto_create_github_repo', 1)
        echohl WarningMsg | echom "⚠️  origin недоступен: " . l:origin_url | echohl None
        return 0
    endif

    let l:repo_slug = s:GetGithubRepoSlug(l:origin_url)
    if empty(l:repo_slug)
        echohl WarningMsg | echom "⚠️  origin не найден и авто-создание поддерживается только для github.com" | echohl None
        return 0
    endif

    if !executable('gh')
        echohl ErrorMsg | echom "❌ origin не существует, установите GitHub CLI: brew install gh" | echohl None
        return 0
    endif

    call system('gh auth status >/dev/null 2>&1')
    if v:shell_error != 0
        echohl ErrorMsg | echom "❌ GitHub CLI не авторизован. Выполните: gh auth login" | echohl None
        return 0
    endif

    let l:visibility = tolower(get(g:, 'git_auto_create_repo_visibility', 'public'))
    let l:visibility_flag = l:visibility ==# 'private' ? '--private' : '--public'
    let l:create_result = system('gh repo create ' . shellescape(l:repo_slug) . ' ' . l:visibility_flag . ' 2>&1')
    if v:shell_error != 0
        echohl ErrorMsg | echom "❌ Не удалось создать GitHub-репозиторий: " . l:repo_slug | echohl None
        echom l:create_result
        return 0
    endif

    call system('git ls-remote origin 2>/dev/null')
    if v:shell_error != 0
        echohl WarningMsg | echom "⚠️  Репозиторий создан, но origin пока недоступен: " . l:origin_url | echohl None
        return 0
    endif

    echohl Question | echom "✅ GitHub-репозиторий создан: " . l:repo_slug | echohl None
    return 1
endfunction

" === Автонастройка origin после git init ===
function! s:AutoSetupOriginAfterInit() abort
    " Если origin уже есть, ничего не меняем.
    call system('git remote get-url origin >/dev/null 2>&1')
    if v:shell_error == 0
        call s:EnsureOriginRemoteExists()
        return
    endif

    " Приоритет:
    " 1) g:git_default_remote_url_template
    " 2) git config --global vimconfig.defaultRemoteUrlTemplate
    let l:template = get(g:, 'git_default_remote_url_template', '')
    if empty(l:template)
        let l:template = trim(system('git config --global vimconfig.defaultRemoteUrlTemplate 2>/dev/null'))
    endif

    if empty(l:template)
        echohl WarningMsg | echom "⚠️  origin не настроен: задайте g:git_default_remote_url_template или git config --global vimconfig.defaultRemoteUrlTemplate" | echohl None
        return
    endif

    let l:origin_url = s:BuildOriginUrlFromTemplate(l:template)
    if empty(l:origin_url)
        return
    endif

    let l:add_result = system('git remote add origin ' . shellescape(l:origin_url) . ' 2>&1')
    if v:shell_error != 0
        echohl ErrorMsg | echom "❌ Не удалось добавить origin" | echohl None
        echom l:add_result
        return
    endif

    " Чтобы обычный git push сразу выставлял upstream для текущей ветки.
    call system('git config --local push.autoSetupRemote true 2>/dev/null')
    call system('git config --local push.default current 2>/dev/null')
    echohl Question | echom "✅ origin добавлен: " . l:origin_url | echohl None
    call s:EnsureOriginRemoteExists()
endfunction

" === Имя текущей ветки ===
function! s:GetCurrentBranch() abort
    let l:branch = trim(system('git branch --show-current 2>/dev/null'))
    return empty(l:branch) ? '(detached HEAD)' : l:branch
endfunction

" === Привязка локальных веток к Debug/Release ===
let g:git_branch_for_debug = get(g:, 'git_branch_for_debug', '')
let g:git_branch_for_release = get(g:, 'git_branch_for_release', '')

" === Интерактивный выбор строки из списка ===
function! s:SelectFromList(title, items) abort
    if empty(a:items)
        return ''
    endif

    echo a:title
    for l:i in range(len(a:items))
        echo printf('%d. %s', l:i + 1, a:items[l:i])
    endfor

    let l:choice = input('Номер: ')
    if l:choice !~# '^\d\+$'
        return ''
    endif

    let l:index = str2nr(l:choice) - 1
    if l:index < 0 || l:index >= len(a:items)
        return ''
    endif

    return a:items[l:index]
endfunction

" === Переключение ветки (интерактивно) ===
function! GitSwitchBranchInteractive() abort
    if !s:EnsureLocalGitRepo()
        return
    endif

    let l:branches = uniq(sort(systemlist('git for-each-ref --format="%(refname:short)" refs/heads 2>/dev/null')))
    if empty(l:branches)
        echohl WarningMsg | echom "⚠️  Ветки не найдены" | echohl None
        return
    endif

    let l:current_branch = s:GetCurrentBranch()
    let l:display = []
    for l:branch in l:branches
        call add(l:display, l:branch ==# l:current_branch ? (l:branch . '  [current]') : l:branch)
    endfor

    let l:selected = s:SelectFromList('Выберите ветку:', l:display)
    if empty(l:selected)
        echohl WarningMsg | echom "🚫 Выбор ветки отменен" | echohl None
        return
    endif

    let l:selected = substitute(l:selected, '\s\+\[current\]$', '', '')
    if l:selected ==# l:current_branch
        echohl Directory | echom "ℹ️  Уже на ветке: " . l:current_branch | echohl None
        return
    endif

    let l:result = system('git switch ' . shellescape(l:selected) . ' 2>&1')

    if v:shell_error != 0
        echohl ErrorMsg | echom "❌ Не удалось переключить ветку" | echohl None
        echom l:result
        return
    endif

    checktime
    silent! edit
    if exists(':CocRestart')
        silent! CocRestart
    endif
    echohl Question | echom "✅ Ветка переключена: " . s:GetCurrentBranch() | echohl None
endfunction

" === Создать и переключить новую ветку ===
function! GitCreateBranchInteractive() abort
    if !s:EnsureLocalGitRepo()
        return
    endif

    let l:new_branch = input('Новая ветка: ')
    if empty(l:new_branch)
        echohl WarningMsg | echom "🚫 Имя ветки пустое" | echohl None
        return
    endif

    if l:new_branch !~# '^[0-9A-Za-z._/-]\+$'
        echohl ErrorMsg | echom "❌ Недопустимое имя ветки" | echohl None
        return
    endif

    let l:result = system('git switch -c ' . shellescape(l:new_branch) . ' 2>&1')
    if v:shell_error != 0
        echohl ErrorMsg | echom "❌ Не удалось создать ветку" | echohl None
        echom l:result
        return
    endif

    checktime
    silent! edit
    if exists(':CocRestart')
        silent! CocRestart
    endif
    echohl Question | echom "✅ Создана и активирована ветка: " . l:new_branch | echohl None
endfunction

" === Запомнить текущую ветку как Debug/Release ===
function! GitBindCurrentBranchToBuildType(build_type) abort
    if !s:EnsureLocalGitRepo()
        return
    endif

    let l:current_branch = s:GetCurrentBranch()
    if l:current_branch ==# '(detached HEAD)'
        echohl WarningMsg | echom "⚠️  Detached HEAD: сначала переключитесь на локальную ветку" | echohl None
        return
    endif

    if a:build_type ==# 'Debug'
        let g:git_branch_for_debug = l:current_branch
        echohl Question | echom "✅ Debug-ветка: " . g:git_branch_for_debug | echohl None
    else
        let g:git_branch_for_release = l:current_branch
        echohl Question | echom "✅ Release-ветка: " . g:git_branch_for_release | echohl None
    endif
endfunction

" === Настроить локальные ветки для Debug/Release ===
function! GitConfigureBuildBranchesInteractive() abort
    if !s:EnsureLocalGitRepo()
        return
    endif

    let l:default_debug = empty(g:git_branch_for_debug) ? 'debug-local' : g:git_branch_for_debug
    let l:default_release = empty(g:git_branch_for_release) ? 'release-local' : g:git_branch_for_release

    let l:debug_branch = input('Локальная ветка для Debug: ', l:default_debug)
    let l:release_branch = input('Локальная ветка для Release: ', l:default_release)

    if empty(l:debug_branch) || empty(l:release_branch)
        echohl WarningMsg | echom "🚫 Настройка отменена: ветка не может быть пустой" | echohl None
        return
    endif
    if l:debug_branch ==# l:release_branch
        echohl WarningMsg | echom "🚫 Debug и Release ветки должны отличаться" | echohl None
        return
    endif

    let l:all_local = systemlist('git for-each-ref --format="%(refname:short)" refs/heads 2>/dev/null')
    if index(l:all_local, l:debug_branch) < 0
        let l:create_debug = confirm("Ветки " . l:debug_branch . " нет. Создать её?", "&Yes\n&No", 1)
        if l:create_debug != 1
            echohl WarningMsg | echom "🚫 Настройка отменена" | echohl None
            return
        endif
        let l:debug_result = system('git branch ' . shellescape(l:debug_branch) . ' 2>&1')
        if v:shell_error != 0
            echohl ErrorMsg | echom "❌ Не удалось создать ветку " . l:debug_branch | echohl None
            echom l:debug_result
            return
        endif
    endif

    if index(l:all_local, l:release_branch) < 0
        let l:create_release = confirm("Ветки " . l:release_branch . " нет. Создать её?", "&Yes\n&No", 1)
        if l:create_release != 1
            echohl WarningMsg | echom "🚫 Настройка отменена" | echohl None
            return
        endif
        let l:release_result = system('git branch ' . shellescape(l:release_branch) . ' 2>&1')
        if v:shell_error != 0
            echohl ErrorMsg | echom "❌ Не удалось создать ветку " . l:release_branch | echohl None
            echom l:release_result
            return
        endif
    endif

    let g:git_branch_for_debug = l:debug_branch
    let g:git_branch_for_release = l:release_branch
    echohl Question | echom "✅ Debug/Release ветки настроены: " . g:git_branch_for_debug . " / " . g:git_branch_for_release | echohl None
endfunction

" === Переключить ветку по типу сборки ===
function! GitSwitchBranchForBuildType(build_type, ...) abort
    let l:silent_mode = get(a:000, 0, 0)
    if !s:EnsureLocalGitRepo(l:silent_mode)
        if !l:silent_mode
            echohl WarningMsg | echom "⚠️  Локальный Git не готов" | echohl None
        endif
        return 0
    endif

    let l:target_branch = a:build_type ==# 'Debug' ? g:git_branch_for_debug : g:git_branch_for_release
    if empty(l:target_branch)
        if !l:silent_mode
            echohl WarningMsg | echom "⚠️  Ветка для " . a:build_type . " не настроена (используйте \\gm)" | echohl None
        endif
        return 0
    endif

    let l:current_branch = s:GetCurrentBranch()
    if l:current_branch ==# l:target_branch
        return 1
    endif

    let l:result = system('git switch ' . shellescape(l:target_branch) . ' 2>&1')
    if v:shell_error != 0
        if !l:silent_mode
            echohl ErrorMsg | echom "❌ Не удалось переключиться на ветку " . l:target_branch | echohl None
            echom l:result
        endif
        return 0
    endif

    checktime
    silent! edit
    if exists(':CocRestart')
        silent! CocRestart
    endif
    if !l:silent_mode
        echohl Question | echom "✅ Активирована ветка для " . a:build_type . ": " . l:target_branch | echohl None
    endif
    return 1
endfunction

" === Переключение между worktree (другая версия кода) ===
function! GitSwitchWorktreeInteractive() abort
    let l:git_root = s:GetGitRoot()
    if empty(l:git_root)
        echohl WarningMsg | echom "⚠️  Не в Git-репозитории" | echohl None
        return
    endif

    let l:lines = systemlist('git worktree list --porcelain 2>/dev/null')
    if v:shell_error != 0 || empty(l:lines)
        echohl WarningMsg | echom "⚠️  Worktree не найдены" | echohl None
        return
    endif

    let l:worktrees = []
    for l:line in l:lines
        if l:line =~# '^worktree '
            call add(l:worktrees, substitute(l:line, '^worktree ', '', ''))
        endif
    endfor
    if len(l:worktrees) < 2
        echohl WarningMsg | echom "⚠️  Нужны минимум 2 worktree (создайте: git worktree add ...)" | echohl None
        return
    endif

    let l:cwd = fnamemodify(getcwd(), ':p:h')
    let l:display = []
    for l:path in l:worktrees
        let l:normalized = fnamemodify(l:path, ':p:h')
        if l:normalized ==# l:cwd
            call add(l:display, l:normalized . '  [current]')
        else
            call add(l:display, l:normalized)
        endif
    endfor

    let l:selected = s:SelectFromList('Выберите worktree:', l:display)
    if empty(l:selected)
        echohl WarningMsg | echom "🚫 Выбор worktree отменен" | echohl None
        return
    endif

    let l:selected = substitute(l:selected, '\s\+\[current\]$', '', '')
    let l:selected = fnamemodify(l:selected, ':p:h')
    if l:selected ==# l:cwd
        echohl Directory | echom "ℹ️  Уже в выбранном worktree" | echohl None
        return
    endif

    let l:current_file = expand('%:p')
    let l:relative_file = ''
    if l:current_file =~# '^' . escape(l:cwd, '\') . '/'
        let l:relative_file = substitute(l:current_file, '^' . escape(l:cwd, '\') . '/', '', '')
    endif

    execute 'cd ' . fnameescape(l:selected)
    if exists(':NERDTreeCWD')
        silent! NERDTreeCWD
    endif

    if !empty(l:relative_file)
        let l:target_file = l:selected . '/' . l:relative_file
        if filereadable(l:target_file)
            execute 'edit ' . fnameescape(l:target_file)
        else
            silent! edit
        endif
    else
        silent! edit
    endif

    if exists(':CocRestart')
        silent! CocRestart
    endif
    echohl Question | echom "✅ Переключено на worktree: " . l:selected | echohl None
endfunction

" === Команды управления локальными Git-ветками ===
command! -nargs=0 GitBranchSwitch call GitSwitchBranchInteractive()
command! -nargs=0 GitBranchCreate call GitCreateBranchInteractive()
