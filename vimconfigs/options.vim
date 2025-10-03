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

" === ПОДСВЕТКА СИНТАКСИСА C++ ===

"let g:cpp_attributes_highlight = 1
"let g:cpp_member_highlight = 1


" Глобальная переменная для хранения выбранного таргета
let g:cmake_selected_target = ''

" Открывать файлы в фоновом режиме без переключения на них
let g:NERDTreeQuitOnOpen = 0

" Не закрывать NERDTree при открытии файла
let g:NERDTreeAutoDeleteBuffer = 0

" Показывать скрытые файлы
let g:NERDTreeShowHidden = 1

" Размер окна NERDTree
let g:NERDTreeWinSize = 35

" Автоматически обновлять корень при смене директории
let g:NERDTreeChDirMode = 2

set wildmenu
set wildmode=longest:list,full
set wildignorecase
set wildignore=*.o,*.obj,*.bak,*.exe,*.pyc,*.jpg,*.gif,*.png
set path=.,**  " искать в текущей директории и поддиректориях

" Игнорировать некоторые файлы
let g:NERDTreeIgnore = ['\.pyc$', '__pycache__', '\.git$', '\.DS_Store']

" Показывать строку статуса
let g:NERDTreeStatusline = '%#NonText#'

" Airline
let g:airline_theme = 'gruvbox'
let g:airline#extensions#tabline#enabled = 1
