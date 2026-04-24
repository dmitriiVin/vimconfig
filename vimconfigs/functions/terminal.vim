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

" === Toggle терминала внутри Vim (открыть/закрыть одной клавишей) ===
let g:vimconfig_terminal_bufnr = get(g:, 'vimconfig_terminal_bufnr', -1)
let g:vimconfig_terminal_prev_winid = get(g:, 'vimconfig_terminal_prev_winid', -1)
let g:vimconfig_terminal_restore_quickfix = get(g:, 'vimconfig_terminal_restore_quickfix', 1)

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

function! s:FindCodeWindowInCurrentTab() abort
    for l:wininfo in getwininfo()
        if l:wininfo.tabnr == tabpagenr() && s:IsCodeWindow(l:wininfo.winid)
            return l:wininfo.winid
        endif
    endfor
    return -1
endfunction

function! s:FindTerminalWinId() abort
    for l:wininfo in getwininfo()
        if l:wininfo.tabnr != tabpagenr()
            continue
        endif
        let l:bufnr = winbufnr(l:wininfo.winnr)
        if l:bufnr > 0 && getbufvar(l:bufnr, '&buftype') ==# 'terminal'
            if g:vimconfig_terminal_bufnr <= 0 || l:bufnr ==# g:vimconfig_terminal_bufnr
                return l:wininfo.winid
            endif
        endif
    endfor
    return -1
endfunction

function! VimConfigToggleTerminal() abort
    " If terminal window is open -> close it and return to previous code window.
    let l:term_winid = s:FindTerminalWinId()
    if l:term_winid > 0
        let l:target_winid = get(g:, 'vimconfig_terminal_prev_winid', -1)
        silent! call win_gotoid(l:term_winid)
        silent! close
        if l:target_winid > 0 && s:IsCodeWindow(l:target_winid)
            silent! call win_gotoid(l:target_winid)
        else
            let l:fallback = s:FindCodeWindowInCurrentTab()
            if l:fallback > 0
                silent! call win_gotoid(l:fallback)
            endif
        endif

        " Restore quickfix monitor after terminal closes (if it was visible).
        if get(g:, 'vimconfig_terminal_restore_quickfix', 0)
            if exists('*OpenQuickfixMonitor')
                silent! call OpenQuickfixMonitor()
            endif
        endif
        return
    endif

    " Open terminal in a code window (not in NERDTree/quickfix).
    let l:origin = win_getid()
    let g:vimconfig_terminal_prev_winid = s:IsCodeWindow(l:origin) ? l:origin : s:FindCodeWindowInCurrentTab()
    if g:vimconfig_terminal_prev_winid > 0
        silent! call win_gotoid(g:vimconfig_terminal_prev_winid)
    endif

    " Hide quickfix while terminal is open (they replace each other).
    let g:vimconfig_terminal_restore_quickfix = !empty(filter(getwininfo(), 'v:val.quickfix'))
    silent! cclose

    let l:height = get(g:, 'vimconfig_terminal_height', 12)
    execute 'silent! botright ' . l:height . 'split'

    " Reuse existing terminal buffer if possible.
    if get(g:, 'vimconfig_terminal_bufnr', -1) > 0 && bufexists(g:vimconfig_terminal_bufnr) && getbufvar(g:vimconfig_terminal_bufnr, '&buftype') ==# 'terminal'
        execute 'buffer ' . g:vimconfig_terminal_bufnr
    else
        silent! terminal
        let g:vimconfig_terminal_bufnr = bufnr('%')
    endif

    setlocal nonumber norelativenumber signcolumn=no
    startinsert
endfunction

" === Безопасное переключение на предыдущий буфер (не из NERDTree) ===
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

" === ПОЛНАЯ ПЕРЕЗАГРУЗКА VIM ===
function! RestartVimFull() abort
    " Сохраняем все файлы
    silent! wall

    " Сохраняем текущую позицию
    let l:session = tempname() . '.vim'

    " Создаём временную сессию
    execute 'mksession! ' . fnameescape(l:session)

    " Перезапускаем Vim и загружаем сессию
    execute 'silent !' . v:progpath . ' -S ' . fnameescape(l:session)

    " Закрываем текущий Vim
    qa!
endfunction
