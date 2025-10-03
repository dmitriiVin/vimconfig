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
highlight Comment cterm=italic ctermfg=cyan

" Подсветка функций и методов
highlight Function cterm=bold ctermfg=yellow

" Подсветка строк
highlight String ctermfg=green cterm=none

" Подсветка чисел
highlight Number ctermfg=magenta

" Подсветка ключевых слов
highlight Keyword cterm=bold ctermfg=red

" Подсветка типов данных (C/C++)
highlight Type ctermfg=blue

" Подсветка Preprocessor (C/C++)
highlight PreProc ctermfg=lightblue

" Более контрастная подсветка поиска
highlight Search ctermbg=yellow ctermfg=black

" Подсветка текущей строки (более мягкая)
highlight CursorLine ctermbg=235 cterm=none

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
nnoremap <C-n> :call CreateNewFile()<CR>

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

" === GIT КОМАНДЫ НА ФУНКЦИОНАЛЬНЫЕ КЛАВИШИ ===

" F6 - Git status (посмотреть что изменилось)
nnoremap <F6> :Git<CR>

" F7 - Git commit (закоммитить)
nnoremap <F7> :Git commit<CR>

" F8 - Git push (отправить на GitHub)
nnoremap <F8> :Git push<CR>

" F9 - Открыть текущий файл в GitHub
nnoremap <F9> :GBrowse<CR>

" F10 - Git pull (обновить с GitHub)
nnoremap <F10> :Git pull<CR>

" === УПРАВЛЕНИЕ NERDTREE И БУФЕРАМИ ===

" F1 - открыть/закрыть NERDTree
nnoremap <F1> :NERDTreeToggle<CR>

" F3 - показать текущий файл в NERDTree
nnoremap <F3> :NERDTreeFind<CR>

" F4 - обновить NERDTree (чтобы видеть новые файлы)
nnoremap <F4> :NERDTreeRefreshRoot<CR>

" Ctrl + n - создать файл или папку в текущей папке NERDTree
nnoremap <C-n> :call CreateFileOrDirectoryInNERDTree()<CR>

function! CreateFileOrDirectoryInNERDTree()
    if &filetype == 'nerdtree'
        " Получаем путь к текущему узлу NERDTree
        let current_path = g:NERDTreeFileNode.GetSelected().path.str()
        if empty(current_path)
            echo "Не удалось получить путь"
            return
        endif
        
        " Определяем директорию
        if isdirectory(current_path)
            let target_dir = current_path
        else
            let target_dir = fnamemodify(current_path, ':h')
        endif
        
        " Выбор типа: файл или папка
        let choice = confirm("Создать:", "&Файл\n&Папку", 1)
        
        if choice == 1
            " Создание файла
            let new_filename = input('Имя файла (с расширением): ', target_dir . '/')
            if new_filename != ''
                " Создаем файл
                let cmd = 'touch "' . new_filename . '"'
                let output = system(cmd)
                
                if v:shell_error
                    echo "Ошибка при создании файла: " . output
                else
                    echo "Создан файл: " . fnamemodify(new_filename, ':t')
                    " Обновляем NERDTree
                    NERDTreeRefreshRoot
                endif
            endif
            
        elseif choice == 2
            " Создание папки
            let new_dirname = input('Имя папки: ', target_dir . '/')
            if new_dirname != ''
                " Создаем папку
                let cmd = 'mkdir -p "' . new_dirname . '"'
                let output = system(cmd)
                
                if v:shell_error
                    echo "Ошибка при создании папки: " . output
                else
                    echo "Создана папка: " . fnamemodify(new_dirname, ':t')
                    " Обновляем NERDTree
                    NERDTreeRefreshRoot
                endif
            endif
        endif
    else
        echo "Эта команда работает только в NERDTree"
    endif
endfunction


" Ctrl + d - удалить файл/папку в NERDTree
nnoremap <C-d> :call DeleteFileOrDirectory()<CR>

function! DeleteFileOrDirectory()
    if &filetype == 'nerdtree'
        " Получаем путь к выбранному файлу/папке
        let current_node = g:NERDTreeFileNode.GetSelected()
        if !empty(current_node)
            let path = current_node.path.str()
            let name = current_node.path.getLastPathComponent(1)

            " Подтверждение удаления
            let choice = confirm("Удалить '" . name . "'?", "&Да\n&Нет", 2)
            if choice == 1
                " Удаляем файл или папку
                if isdirectory(path)
                    " Удаляем папку рекурсивно
                    let cmd = 'rm -rf "' . path . '"'
                else
                    " Удаляем файл
                    let cmd = 'rm "' . path . '"'
                endif

                " Выполняем удаление
                let output = system(cmd)
                if v:shell_error
                    echo "Ошибка при удалении: " . output
                else
                    echo "Удалено: " . name
                    " Обновляем NERDTree
                    NERDTreeRefreshRoot
                endif
            endif
        else
            echo "Не выбран файл или папка"
        endif
    else
        echo "Эта команда работает только в NERDTree"
    endif
endfunction

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

" === НАСТРОЙКИ NERDTREE ДЛЯ РАБОТЫ С БУФЕРАМИ ===

" Открывать файлы в фоновом режиме без переключения на них
let g:NERDTreeQuitOnOpen = 0

" Не закрывать NERDTree при открытии файла
let g:NERDTreeAutoDeleteBuffer = 0

" Автоматически обновлять NERDTree при сохранении файлов
autocmd BufWritePost * if exists(':NERDTreeRefreshRoot') | NERDTreeRefreshRoot | endif

" Показывать скрытые файлы
let g:NERDTreeShowHidden = 1

" Размер окна NERDTree
let g:NERDTreeWinSize = 35

" Автоматически обновлять корень при смене директории
let g:NERDTreeChDirMode = 2

" === ОТКЛЮЧЕНИЕ КЛАВИШ В NERDTREE ===

" Отключить все клавиши создания/открытия файлов в NERDTree
autocmd FileType nerdtree nnoremap <buffer> <C-o> <nop>
autocmd FileType nerdtree nnoremap <buffer> <C-e> <nop>
autocmd FileType nerdtree nnoremap <buffer> <C-p> <nop>
autocmd FileType nerdtree nnoremap <buffer> <C-Tab> <nop>
autocmd FileType nerdtree nnoremap <buffer> <M-o> <nop>

" Явно разрешить F11 и F12 в NERDTree
autocmd FileType nerdtree nnoremap <buffer> <C-n> :call CreateFileOrDirectoryInNERDTree()<CR>
autocmd FileType nerdtree nnoremap <buffer> <C-d> :call DeleteFileOrDirectory()<CR>

" === КОМАНДЫ ДЛЯ РАБОТЫ С БУФЕРАМИ ===

" Показать список всех открытых буферов
nnoremap <leader>bl :ls<CR>:b<space>

" Закрыть текущий буфер
nnoremap <leader>bd :bd<CR>

" Закрыть все буферы кроме текущего
nnoremap <leader>bo :%bd\|e#<CR>

" Переключение между буферами по Tab (уже есть)
" nnoremap <Tab> :bnext<CR>
" nnoremap <S-Tab> :bprevious<CR>

" Быстрое переключение между последними файлами (уже есть)
" nnoremap <C-Tab> :b#<CR>

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

" === УЛУЧШЕННОЕ СОЗДАНИЕ ФАЙЛОВ ===

" Создать новый файл в текущей директории с обновлением NERDTree (только в рабочей области)
function! CreateNewFile()
    if &filetype != 'nerdtree'
        let current_dir = expand("%:p:h")
        let new_file = input('New file name: ', current_dir . '/')
        if new_file != ''
            execute 'edit ' . new_file
            execute 'write'
            " Обновляем NERDTree если он открыт
            if exists(':NERDTreeRefreshRoot')
                NERDTreeRefreshRoot
            endif
        endif
    endif
endfunction

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

" Быстрое переключение между последними файлами (только в рабочей области)
nnoremap <C-Tab> :call SafeBufferSwitch()<CR>
inoremap <C-Tab> <Esc>:call SafeBufferSwitch()<CR>

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

" Alt+O для безопасного открытия (только в рабочей области)
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

" Игнорировать некоторые файлы
let g:NERDTreeIgnore = ['\.pyc$', '__pycache__', '\.git$', '\.DS_Store']

" Показывать строку статуса
let g:NERDTreeStatusline = '%#NonText#'

" === ОТКЛЮЧЕНИЕ ПЕРЕКЛЮЧЕНИЯ БУФЕРОВ В NERDTREE ===

" Отключить Tab/S-Tab в NERDTree чтобы не переключались буферы
autocmd FileType nerdtree nnoremap <buffer> <Tab> <nop>
autocmd FileType nerdtree nnoremap <buffer> <S-Tab> <nop>

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

" Дополнительные полезные плагины
Plug 'scrooloose/nerdtree'              " Файловый менеджер
Plug 'tpope/vim-commentary'             " Комментирование кода
Plug 'airblade/vim-gitgutter'           " Git статус на полях
Plug 'vim-airline/vim-airline'          " Статус бар
Plug 'vim-airline/vim-airline-themes'   " Темы для статус бара
Plug 'cormacrelf/vim-colors-github'

" === GIT И GITHUB ИНТЕГРАЦИЯ ===
Plug 'tpope/vim-fugitive'      " Git интеграция
Plug 'tpope/vim-rhubarb'       " GitHub интеграция

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
