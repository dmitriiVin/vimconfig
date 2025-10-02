" === ОСНОВНЫЕ НАСТРОЙКИ ===
syntax on
set number
set autoindent
set smartindent

" Настройка табуляции
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set smarttab

" Поиск
set hlsearch                    " подсвечивать результаты поиска
set incsearch                   " инкрементальный поиск
set ignorecase                  " игнорировать регистр
set smartcase                   " умный регистр

" Интерфейс
set mouse=a
set wildmenu
set wildmode=longest:full,full
set showcmd                     " показывать незавершенные команды
set cursorline                  " подсветка текущей строки
set scrolloff=5                 " отступ от краев при скролле

" Убираем подсветку текущей строки (зеленую) или делаем ее менее навязчивой
" highlight CursorLine ctermbg=235 cterm=none  " темно-серый вместо зеленого
set nocursorline                " или полностью отключаем

" Переносы
set wrap
set linebreak

" === КАСТОМНАЯ ПОДСВЕТКА СИНТАКСИСА ===

" Яркая подсветка комментариев
"highlight Comment cterm=italic ctermfg=cyan

" Подсветка функций и методов
"highlight Function cterm=bold ctermfg=yellow

" Подсветка строк
highlight String ctermfg=235 cterm=none

" Подсветка чисел
"highlight Number ctermfg=magenta

" Подсветка ключевых слов
"highlight Keyword cterm=bold ctermfg=red

" Подсветка типов данных (C/C++)
"highlight Type ctermfg=blue

" Подсветка Preprocessor (C/C++)
"highlight PreProc ctermfg=lightblue

" Более контрастная подсветка поиска
"highlight Search ctermbg=yellow ctermfg=black

" === КОМАНДЫ И СОЧЕТАНИЯ КЛАВИШ ===

" Ctrl + S - сохранить файл
inoremap <C-s> <Esc>:w<CR>a
nnoremap <C-s> <Esc>:w<CR>a

" Ctrl + Q - закрыть текущий файл в буфере
nnoremap <C-q> :bd<CR>

" Ctrl + Shift + S - сохранить как
nnoremap <C-S-s> :saveas 

" Ctrl + C - копировать выделенный текст в системный буфер
vnoremap <C-c> "+y
inoremap <C-c> "+y
nnoremap <C-c> "+y

" Ctrl + A - выделить весь текст в файле
nnoremap <C-a> ggVG
vnoremap <C-a> ggVG
inoremap <C-a> ggVG

" Ctrl + D — удалить текущую строку
nnoremap <C-d> dd
inoremap <C-d> <Esc>ddi
vnoremap <C-d> d

" Ctrl + Z - отменить предыдущее действие
nnoremap <C-z> u
vnoremap <C-z> u
inoremap <C-z> <C-o>u

" Ctrl + F - поиск по файлу
nnoremap <C-f> /
inoremap <C-f> <Esc>/

" Ctrl + H - убрать подсветку результатов поиска
nnoremap <C-h> :nohlsearch<CR>

" Ctrl + N - создать новый файл
nnoremap <C-n> :enew<CR>

" Tab - переключение между открытыми буферами (файлами)
nnoremap <Tab> :bnext<CR>
nnoremap <S-Tab> :bprevious<CR>

" Удалить текущую строку - Ctrl + K
nnoremap <C-k> dd
inoremap <C-k> <Esc>ddi
vnoremap <C-k> d

" F2 - переименовать текущий файл
nnoremap <F2> :call RenameFile()<CR>
function! RenameFile()
    let old_name = expand('%')
    let new_name = input('New file name: ', expand('%'))
    if new_name != '' && new_name != old_name
        exec ':saveas ' . new_name
        exec ':silent !rm ' . old_name
        redraw!
    endif
endfunction

" F5 - запуск кода (зависит от типа файла)
nnoremap <F5> :call RunCode()<CR>
function! RunCode()
    let filename = expand('%')  " получаем имя файла
    let basename = expand('%:r') " получаем имя без расширения
    
    " Проверяем что файл существует
    if empty(filename)
        echo "No file to run"
        return
    endif
    
    if &filetype == 'cpp'
        execute '!clang++ -std=c++17 -O2 -Wall' filename '-o' basename '&& ./' . basename
    elseif &filetype == 'c'
        execute '!clang -std=c99 -O2 -Wall' filename '-o' basename '&& ./' . basename
    elseif &filetype == 'python'
        execute '!python' filename
    elseif &filetype == 'javascript'
        execute '!node' filename
    elseif &filetype == 'pascal'
        execute '!fpc' filename '&& ./' . basename
    else
        echo "Unsupported file type:" &filetype
    endif
endfunction

" === УПРАВЛЕНИЕ NERDTREE ===

" F1 - открыть/закрыть NERDTree
nnoremap <F1> :NERDTreeToggle<CR>

" F3 - показать текущий файл в NERDTree
nnoremap <F3> :NERDTreeFind<CR>

" Ctrl + B - переключение между NERDTree и рабочим окном
nnoremap <C-b> :call SwitchBetweenNERDTreeAndCode()<CR>

function! SwitchBetweenNERDTreeAndCode()
    " Если сейчас в NERDTree - переходим в рабочее окно
    if &filetype == 'nerdtree'
        wincmd l
        " Если не получилось перейти (нет других окон), создаем новое
        if &filetype == 'nerdtree'
            wincmd l
        endif
    " Если в рабочем окне - ищем NERDTree и переходим в него
    else
        " Ищем окно с NERDTree
        let nerdtree_winnr = -1
        for winnr in range(1, winnr('$'))
            if getbufvar(winbufnr(winnr), '&filetype') == 'nerdtree'
                let nerdtree_winnr = winnr
                break
            endif
        endfor
        
        " Если нашли NERDTree - переходим в него
        if nerdtree_winnr != -1
            execute nerdtree_winnr . 'wincmd w'
        " Если NERDTree не найден - открываем его
        else
            NERDTreeToggle
        endif
    endif
endfunction

" === РАБОТА С ФАЙЛАМИ И ПУТЯМИ ===

" Ctrl + O - открыть файл с началом в текущей директории
nnoremap <C-o> :e ./<C-d>
inoremap <C-o> <Esc>:e ./<C-d>

" Ctrl + E - быстрое открытие файла в текущей директории
nnoremap <C-e> :e <C-R>=expand("%:p:h") . "/" <CR>
inoremap <C-e> <Esc>:e <C-R>=expand("%:p:h") . "/" <CR>

" Ctrl + P - поиск файла по имени из текущей директории
nnoremap <C-p> :find *
inoremap <C-p> <Esc>:find *

" === НАСТРОЙКИ TAB-ДОПОЛНЕНИЯ КАК В ТЕРМИНАЛЕ ===
set wildmenu
set wildmode=longest:list,full
set wildignorecase
set wildignore=*.o,*.obj,*.bak,*.exe,*.pyc,*.jpg,*.gif,*.png
set path=.,**  " искать в текущей директории и поддиректориях

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

" Tab для автодополнения путей
cnoremap <expr> <Tab> TerminalTabComplete()

" Shift+Tab для обратного перебора
cnoremap <expr> <S-Tab> wildmenumode() ? "\<Up>" : "\<S-Tab>"

" Ctrl+Space для показа всех вариантов
cnoremap <C-Space> <C-d>

" === КОМАНДЫ ДЛЯ РАБОТЫ С ФАЙЛАМИ ===

" Создать новый файл в текущей директории
nnoremap <C-n> :e <C-R>=expand("%:p:h") . "/" <CR>

" Быстрое переключение между последними файлами
nnoremap <C-Tab> :b#<CR>
inoremap <C-Tab> <Esc>:b#<CR>a

" === ФУНКЦИЯ ДЛЯ БЕЗОПАСНОГО ОТКРЫТИЯ ФАЙЛОВ ===
function! SafeEdit()
    let file_path = input('Open file: ', '', 'file')
    if file_path != ''
        try
            execute 'edit ' . fnameescape(file_path)
        catch
            echo "Error opening file: " . v:exception
        endtry
    endif
endfunction

" Alt+O для безопасного открытия
nnoremap <M-o> :call SafeEdit()<CR>
inoremap <M-o> <Esc>:call SafeEdit()<CR>

" === ДОПОЛНИТЕЛЬНЫЕ КОМАНДЫ ДЛЯ РАБОТЫ С ПУТЯМИ ===

" Быстрая навигация по директориям
nnoremap <leader>cd :cd %:p:h<CR>:pwd<CR>  " Перейти в директорию текущего файла

" Показать текущий путь
nnoremap <leader>pwd :pwd<CR>

" Создать новую директорию
nnoremap <leader>md :!mkdir -p

" Открыть проводник в текущей директории
nnoremap <leader>ex :!open .<CR>

" === НАСТРОЙКИ NERDTREE ===

" Автозапуск NERDTree при открытии Vim без файлов
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

" Закрыть Vim если остался только NERDTree
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif

" Показывать скрытые файлы
let g:NERDTreeShowHidden = 1

" Игнорировать некоторые файлы
let g:NERDTreeIgnore = ['\.pyc$', '__pycache__', '\.git$', '\.DS_Store']

" Размер окна
let g:NERDTreeWinSize = 35

" Показывать строку статуса
let g:NERDTreeStatusline = '%#NonText#'

" === ОТКЛЮЧЕНИЕ ПЕРЕКЛЮЧЕНИЯ БУФЕРОВ В NERDTREE ===

" Отключить Tab/S-Tab в NERDTree чтобы не переключались буферы
autocmd FileType nerdtree nnoremap <buffer> <Tab> <nop>
autocmd FileType nerdtree nnoremap <buffer> <S-Tab> <nop>
autocmd FileType nerdtree nnoremap <buffer> <C-Tab> <nop>

" === АВТОЗАВЕРШЕНИЕ СКОБОК ===
inoremap " ""<Left>
inoremap ' ''<Left>
inoremap ( ()<Left>
inoremap [ []<Left>
inoremap { {}<Left>

" Умное автозакрытие (только если следующая скобка не открыта)
inoremap <expr> " strpart(getline('.'), col('.')-1, 1) == '"' ? "\<Right>" : '""<Left>'
inoremap <expr> ' strpart(getline('.'), col('.')-1, 1) == "'" ? "\<Right>" : "''<Left>"

" === ПЛАГИНЫ ===
call plug#begin('~/.vim/plugged')

Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'jiangmiao/auto-pairs'
Plug 'morhetz/gruvbox'
Plug 'othree/html5-vim' 

" Дополнительные полезные плагины
Plug 'scrooloose/nerdtree'              " Файловый менеджер
Plug 'tpope/vim-commentary'             " Комментирование кода
Plug 'airblade/vim-gitgutter'           " Git статус на полях
Plug 'vim-airline/vim-airline'          " Статус бар
Plug 'vim-airline/vim-airline-themes'   " Темы для статус бара
Plug 'cormacrelf/vim-colors-github'
call plug#end()

" === НАСТРОЙКИ ПЛАГИНОВ ===

" vim-commentary - Ctrl+/ для комментирования/раскомментирования кода
noremap <C-/> :Commentary<CR>
inoremap <C-/> <Esc>:Commentary<CR>a

" Airline
let g:airline_theme = 'gruvbox'
let g:airline#extensions#tabline#enabled = 1

" === COC.NVIM НАСТРОЙКИ ===

" Tab для автодополнения
inoremap <expr> <Tab> pumvisible() ? "\<C-y>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

" Enter для подтверждения автодополнения
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<cr>"

" === ЦВЕТОВАЯ СХЕМА ===
colorscheme github
set background=dark

" === КОНЕЦ НАСТРОЕК ===
