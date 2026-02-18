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

" === Имя текущей ветки ===
function! s:GetCurrentBranch() abort
    let l:branch = trim(system('git branch --show-current 2>/dev/null'))
    return empty(l:branch) ? '(detached HEAD)' : l:branch
endfunction

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
    if empty(s:GetGitRoot())
        echohl WarningMsg | echom "⚠️  Не в Git-репозитории" | echohl None
        return
    endif

    let l:raw_branches = systemlist('git for-each-ref --format="%(refname:short)" refs/heads refs/remotes/origin 2>/dev/null')
    call filter(l:raw_branches, 'v:val !~# "^origin/HEAD"')
    let l:branches = uniq(sort(l:raw_branches))
    if empty(l:branches)
        echohl WarningMsg | echom "⚠️  Ветки не найдены" | echohl None
        return
    endif

    let l:current_branch = s:GetCurrentBranch()
    let l:display = []
    for l:branch in l:branches
        if l:branch ==# l:current_branch || l:branch ==# ('origin/' . l:current_branch)
            call add(l:display, l:branch . '  [current]')
        else
            call add(l:display, l:branch)
        endif
    endfor

    let l:selected = s:SelectFromList('Выберите ветку:', l:display)
    if empty(l:selected)
        echohl WarningMsg | echom "🚫 Выбор ветки отменен" | echohl None
        return
    endif

    let l:selected = substitute(l:selected, '\s\+\[current\]$', '', '')
    if l:selected ==# l:current_branch || l:selected ==# ('origin/' . l:current_branch)
        echohl Directory | echom "ℹ️  Уже на ветке: " . l:current_branch | echohl None
        return
    endif

    if l:selected =~# '^origin/'
        let l:local_branch = substitute(l:selected, '^origin/', '', '')
        let l:result = system('git switch --track ' . shellescape(l:selected) . ' 2>&1')
        if v:shell_error != 0
            let l:result = system('git switch ' . shellescape(l:local_branch) . ' 2>&1')
        endif
    else
        let l:result = system('git switch ' . shellescape(l:selected) . ' 2>&1')
    endif

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
    if empty(s:GetGitRoot())
        echohl WarningMsg | echom "⚠️  Не в Git-репозитории" | echohl None
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
