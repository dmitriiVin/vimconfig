" === Минимальный workflow: буферы + pin ===

let g:vimconfig_pinned_buffers = get(g:, 'vimconfig_pinned_buffers', {})

" === Буфер закреплен? ===
function! s:IsPinnedBuffer(bufnr) abort
    return get(g:vimconfig_pinned_buffers, a:bufnr, 0)
endfunction

" === Перейти к N-му рабочему буферу (1..10) ===
function! VimConfigJumpToBufferIndex(index) abort
    let l:buffers = []
    for l:info in getbufinfo({'buflisted': 1})
        let l:buf = l:info.bufnr
        if l:buf <= 0
            continue
        endif
        if getbufvar(l:buf, '&buftype') !=# ''
            continue
        endif
        if getbufvar(l:buf, '&filetype') ==# 'nerdtree'
            continue
        endif
        if getbufvar(l:buf, '&filetype') ==# 'qf'
            continue
        endif
        call add(l:buffers, l:buf)
    endfor

    if a:index < 1 || a:index > len(l:buffers)
        echohl WarningMsg | echom 'Буфер с таким номером не найден' | echohl None
        return
    endif

    execute 'buffer ' . l:buffers[a:index - 1]
endfunction

" === Поставить/снять pin на текущем буфере ===
function! VimConfigTogglePinBuffer() abort
    let l:buf = bufnr('%')
    if l:buf <= 0 || &buftype !=# ''
        echohl WarningMsg | echom 'Pin доступен только для обычных файловых буферов' | echohl None
        return
    endif

    if s:IsPinnedBuffer(l:buf)
        call remove(g:vimconfig_pinned_buffers, l:buf)
        echom 'Pin снят: ' . fnamemodify(bufname(l:buf), ':t')
    else
        let g:vimconfig_pinned_buffers[l:buf] = 1
        echom 'Pin установлен: ' . fnamemodify(bufname(l:buf), ':t')
    endif
endfunction

" === Закрыть текущий буфер (Ctrl+B), но не закрывать pinned ===
function! VimConfigCloseCurrentBuffer() abort
    let l:buf = bufnr('%')
    if l:buf <= 0
        return
    endif

    if s:IsPinnedBuffer(l:buf)
        echohl WarningMsg | echom 'Буфер закреплен (pin): снимите pin через \bp' | echohl None
        return
    endif

    let l:alt = bufnr('#')
    if l:alt > 0 && buflisted(l:alt) && l:alt != l:buf
        execute 'buffer ' . l:alt
    else
        silent! bprevious
        if bufnr('%') == l:buf
            silent! enew
        endif
    endif

    execute 'silent! bdelete ' . l:buf
endfunction

" === Закрыть все буферы, кроме текущего и pinned ===
function! VimConfigCloseOtherBuffersPreservingPinned() abort
    let l:origin_win = win_getid()
    let l:current = bufnr('%')
    let l:guard = 0

    while l:guard < 50
        let l:guard += 1
        let l:closable = []

        for l:info in getbufinfo({'buflisted': 1})
            let l:buf = l:info.bufnr
            if l:buf == l:current
                continue
            endif
            if getbufvar(l:buf, '&buftype') !=# ''
                continue
            endif
            if s:IsPinnedBuffer(l:buf)
                continue
            endif
            call add(l:closable, l:buf)
        endfor

        if empty(l:closable)
            break
        endif

        for l:buf in l:closable
            if !bufexists(l:buf)
                continue
            endif
            execute 'silent! bdelete ' . l:buf
            if !bufexists(l:buf) && has_key(g:vimconfig_pinned_buffers, l:buf)
                call remove(g:vimconfig_pinned_buffers, l:buf)
            endif
        endfor
        redraw!
    endwhile

    if l:origin_win > 0
        silent! call win_gotoid(l:origin_win)
    endif
    if bufexists(l:current)
        execute 'silent! buffer ' . l:current
    endif

    let l:remaining = 0
    for l:info in getbufinfo({'buflisted': 1})
        let l:buf = l:info.bufnr
        if l:buf == l:current
            continue
        endif
        if getbufvar(l:buf, '&buftype') !=# ''
            continue
        endif
        if s:IsPinnedBuffer(l:buf)
            continue
        endif
        let l:remaining += 1
    endfor

    if l:remaining > 0
        echohl WarningMsg | echom 'Часть буферов не закрыта (возможно, есть несохраненные)' | echohl None
    endif
endfunction
