" Автоматически обновлять NERDTree при сохранении файлов
autocmd BufWritePost * if exists(':NERDTreeRefreshRoot') | NERDTreeRefreshRoot | endif

" Использовать системный clang-format
autocmd FileType c,cpp,h,hpp setlocal formatprg=clang-format

" Автоформат перед сохранением
autocmd BufWritePre *.c,*.cpp,*.h,*.hpp silent! undojoin | silent! execute '%!clang-format'

" Отключить все клавиши создания/открытия файлов в NERDTree
autocmd FileType nerdtree nnoremap <buffer> <C-o> <nop>
autocmd FileType nerdtree nnoremap <buffer> <C-e> <nop>
autocmd FileType nerdtree nnoremap <buffer> <C-p> <nop>
autocmd FileType nerdtree nnoremap <buffer> <C-Tab> <nop>
autocmd FileType nerdtree nnoremap <buffer> <M-o> <nop>

autocmd FileType nerdtree nnoremap <buffer> <C-n> :call CreateFileOrDirectoryInNERDTree()<CR>
autocmd FileType nerdtree nnoremap <buffer> <C-d> :call DeleteFileOrDirectory()<CR>

" Автозапуск NERDTree при открытии Vim без файлов
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

" === Авто-закрытие quickfix при :q или :q! ===
augroup AutoCloseQuickfix
    autocmd!
    " Перед выходом из любого окна закрываем quickfix, если оно открыто
    autocmd QuitPre * if &buftype !=# 'quickfix' | silent! cclose | endif
augroup END

" Закрыть Vim если остался только NERDTree
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif

" Отключить Tab/S-Tab в NERDTree чтобы не переключались буферы
autocmd FileType nerdtree nnoremap <buffer> <Tab> <nop>
autocmd FileType nerdtree nnoremap <buffer> <S-Tab> <nop>

autocmd FileType nerdtree setlocal nobuflisted

augroup GitCloseMapping
    autocmd!
    autocmd FileType git,gitcommit,gitrebase,gitconfig nnoremap <buffer> <C-q> :call GitSaveAndClose()<CR>
augroup END

" === Привязка функции NERDTreeCD к клавише i внутри NERDTree ===
autocmd FileType nerdtree nnoremap <buffer> i :call NERDTreeCD()<CR>
