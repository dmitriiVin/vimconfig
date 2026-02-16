" ~/.vim/vimconfigs/functions/coc_russian.vim

let g:coc_russian_dict = {
\ 'Undefined variable': 'Неопределённая переменная',
\ 'Function not found': 'Функция не найдена',
\ "'\\([^']\\+\\)' file not found": 'Файл "\1" не найден',
\ 'Included header \(\S\+\)': 'Включаемый заголовок \1',
\ 'is not used directly': 'не используется напрямую',
\ }

function! TranslateCocMessage(msg)
    let result = a:msg
    for pattern in keys(g:coc_russian_dict)
        let result = substitute(result, pattern, g:coc_russian_dict[pattern], 'g')
    endfor
    return result
endfunction

function! ShowDiagnosticsRussian() abort
    " Получаем diagnostics
    let diagnostics = CocAction('diagnosticList')
    let qf_list = []

    for diag in diagnostics
        call add(qf_list, {
        \ 'filename': diag['file'],
        \ 'lnum': diag['lnum'],
        \ 'col': diag['col'],
        \ 'text': TranslateCocMessage(diag['message']),
        \ 'type': diag['severity'] == 1 ? 'E' : 'W',
        \ })
    endfor

    " Отправляем в quickfix
    call setqflist(qf_list, 'r')
    copen
endfunction

" В этом же файле coc_russian.vim
autocmd User CocDiagnosticChange call ShowDiagnosticsRussian()
