" === ЗАКРЫТЬ СПРАВКУ И ВЕРНУТЬСЯ В ПРЕДЫДУЩИЙ БУФЕР ===
function! s:CloseVimCommandsHelp() abort
    let l:prev_buf = get(b:, 'vimconfig_help_prev_buf', -1)

    if l:prev_buf > 0 && bufexists(l:prev_buf)
        execute 'buffer ' . l:prev_buf
    else
        bdelete!
    endif
endfunction

" === ПРОВЕРИТЬ, ЧТО ОКНО ПОДХОДИТ ДЛЯ КОДА ===
function! s:IsCodeWindow(winid) abort
    if a:winid <= 0
        return 0
    endif

    let l:bufnr = winbufnr(a:winid)
    if l:bufnr <= 0
        return 0
    endif

    let l:buftype = getbufvar(l:bufnr, '&buftype')
    let l:filetype = getbufvar(l:bufnr, '&filetype')

    return l:buftype ==# '' && l:filetype !=# 'nerdtree'
endfunction

" === НАЙТИ ЛУЧШЕЕ ОКНО С КОДОМ В ТЕКУЩЕЙ ВКЛАДКЕ ===
function! s:FindCodeWindowInCurrentTab() abort
    for l:wininfo in getwininfo()
        if l:wininfo.tabnr == tabpagenr() && s:IsCodeWindow(l:wininfo.winid)
            return l:wininfo.winid
        endif
    endfor

    return -1
endfunction

" === ОТКРЫТЬ ПОДРОБНУЮ СПРАВКУ ПО КОНФИГУРАЦИИ ===
function! ShowVimCommandsHelp() abort
    let l:target_win = win_getid()
    if !s:IsCodeWindow(l:target_win)
        let l:target_win = s:FindCodeWindowInCurrentTab()
        if l:target_win > 0
            call win_gotoid(l:target_win)
        endif
    endif

    let l:prev_buf = bufnr('%')
    let l:help_lines = [
                \ 'VimConfig Help',
                \ '============',
                \ '',
                \ 'Выход из справки: Esc',
                \ '',
                \ 'Лидер-клавиша: \',
                \ '',
                \ 'Базовые клавиши:',
                \ '  Ctrl+S          - сохранить',
                \ '  Ctrl+B          - закрыть текущий буфер (bp|bd #)',
                \ '  Ctrl+X / \x     - закрыть текущий буфер (альтернатива)',
                \ '  Ctrl+Z          - undo',
                \ '  Ctrl+A          - выделить весь файл',
                \ '  Ctrl+F          - поиск',
                \ '  Ctrl+H          - убрать hlsearch',
                \ '  Ctrl+D / Ctrl+K - удалить строку/выделение',
                \ '  Ctrl+C          - копировать в системный буфер',
                \ '',
                \ 'Буферы и окна:',
                \ '  Tab / Shift+Tab - переключение рабочих буферов',
                \ '  Tab+стрелки     - переход между окнами',
                \ '  Shift+стрелки   - быстрый переход между окнами',
                \ '  \bl             - список буферов',
                \ '  \bd             - закрыть буфер',
                \ '  \bo             - закрыть все кроме текущего',
                \ '  Ctrl+Tab        - b# (переключение к предыдущему)',
                \ '',
                \ 'Файлы и пути:',
                \ '  Ctrl+N          - создать файл (в коде) / создать файл или папку (в NERDTree)',
                \ '  Ctrl+O          - открыть файл от текущей директории',
                \ '  Ctrl+E          - открыть файл из директории текущего файла',
                \ '  Ctrl+P          - find *',
                \ '  Alt+O           - SafeEdit',
                \ '  \cd             - cd в директорию текущего файла',
                \ '  \pwd            - показать текущий путь',
                \ '  \md             - mkdir -p ...',
                \ '  \ex             - открыть директорию в Finder (macOS)',
                \ '',
                \ 'NERDTree:',
                \ '  F1              - открыть/закрыть NERDTree',
                \ '  F4              - обновить NERDTree',
                \ '  Ctrl+N          - создать файл/папку в NERDTree',
                \ '  Ctrl+D          - удалить файл/папку в NERDTree',
                \ '  i               - сделать cd в выбранную директорию',
                \ '',
                \ 'CMake:',
                \ '  F3              - удалить build для выбранного CMake-проекта',
                \ '  F6              - генерация CMake',
                \ '  F7              - сборка (автогенерация при необходимости)',
                \ '  F8              - выбор исполняемого файла',
                \ '  F9              - запуск выбранного исполняемого файла',
                \ '  F10             - переключить Debug/Release',
                \ '  F12             - создать/открыть CMakeLists.txt из NERDTree',
                \ '  \ru             - generate + build + auto-select target + run',
                \ '  \bt             - показать текущий build type',
                \ '  \ct             - показать текущий выбранный target',
                \ '',
                \ 'Локальные версии кода по F10:',
                \ '  Хранилище       - .vim-code-profiles/debug и .vim-code-profiles/release',
                \ '  Поведение       - при F10 текущая версия сохраняется, целевая подменяется в проекте',
                \ '  Важно           - сначала сохраните изменения (Ctrl+S), чтобы избежать конфликтов',
                \ '',
                \ 'Запуск кода:',
                \ '  F5              - запуск по filetype через RunCode()',
                \ '',
                \ 'Quickfix и диагностика:',
                \ '  Ctrl+W          - открыть quickfix-монитор',
                \ '  Ctrl+Q          - закрыть quickfix',
                \ '  \qn / \qp       - следующая / предыдущая ошибка',
                \ '  \qf / \ql       - первая / последняя ошибка',
                \ '',
                \ 'Git/Fugitive:',
                \ '  \gs             - Git status',
                \ '  \gc             - Git commit',
                \ '  \gp             - Git push',
                \ '  \gl             - Git pull',
                \ '  \go             - открыть текущий файл/репозиторий в браузере',
                \ '',
                \ 'Темы и шрифты:',
                \ '  \th             - выбрать тему (preset + scheme), тема запоминается',
                \ '  \ff             - выбрать GUI-шрифт (в терминале шрифт задаётся терминалом)',
                \ '',
                \ 'Служебные:',
                \ '  Ctrl+Shift+R    - полный рестарт Vim',
                \ '  \h              - открыть эту справку',
                \ '',
                \ 'Ключевые файлы конфигурации:',
                \ '  ~/.vimrc',
                \ '  ~/.vim/coc-settings.json',
                \ '  ~/Desktop/vimconfig/README.md',
                \ '  ~/Desktop/vimconfig/installvimconfig.sh',
                \ '  ~/Desktop/vimconfig/coc-settings.json',
                \ '  ~/.vim/vimconfigs/options.vim',
                \ '  ~/.vim/vimconfigs/mappings.vim',
                \ '  ~/.vim/vimconfigs/autocmd.vim',
                \ '  ~/.vim/vimconfigs/plugins.vim',
                \ '  ~/.vim/vimconfigs/functions/cmake.vim',
                \ '  ~/.vim/vimconfigs/functions/help.vim',
                \ '  ~/.vim/vimconfigs/functions/nerdtree.vim',
                \ '  ~/.vim/vimconfigs/functions/runcode.vim',
                \ '  ~/.vim/vimconfigs/functions/terminal.vim',
                \ '  ~/.vim/vimconfigs/functions/github.vim',
                \ '  ~/.vim/vimconfigs/functions/coc_russian.vim',
                \ '  ~/.vim/vimconfigs/colors/*.vim',
                \ '',
                \ 'Справка отражает текущие mappings/options/functions этого репозитория.',
                \ ]

    " Открываем справку в текущем окне (без split).
    silent! hide enew
    setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted
    setlocal filetype=help
    let b:vimconfig_help_prev_buf = l:prev_buf

    nnoremap <silent><buffer> <Esc> :call <SID>CloseVimCommandsHelp()<CR>

    call setline(1, l:help_lines)
    setlocal nomodifiable readonly
    normal! gg
endfunction
