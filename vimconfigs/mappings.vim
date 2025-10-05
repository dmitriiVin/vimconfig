" === СОЧЕТАНИЯ КЛАВИШ ===

" Ctrl + S - сохранить файл
inoremap <C-s> <Esc>:w<CR>a
nnoremap <C-s> <Esc>:w<CR>a

" Ctrl + Q - закрыть текущий файл в буфере
nnoremap <C-q> :bp\|bd #<CR>

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

" F5 - запуск кода (зависит от типа файла)
nnoremap <F5> :call RunCode()<CR>

" === КОМАНДЫ ДЛЯ CMAKE (НЕЗАВИСИМЫЕ ОТ ПЛАГИНОВ) ===

" F6 - CMake generate
nnoremap <F6> :call CMakeGenerateFixed()<CR>

" F7 - CMake build  
nnoremap <F7> :call CMakeBuildFixed()<CR>

" F8 - Выбор таргета из списка
nnoremap <F8> :call CMakeSelectTargetInteractive()<CR>

" F9 - Запуск выбранного таргета
nnoremap <F9> :call CMakeRunFixed()<CR>

" F12 - Открыть CMakeLists.txt (только не в NERDTree)
nnoremap <F12> :call OpenCMakeLists()<CR>

" Shift+F8 - Быстрый запуск
nnoremap <S-F8> :call CMakeQuickRun()<CR>

" === УПРАВЛЕНИЕ NERDTREE И БУФЕРАМИ ===

" F1 - открыть/закрыть NERDTree
nnoremap <F1> :NERDTreeToggle<CR>

" F3 - показать текущий файл в NERDTree
nnoremap <F3> :NERDTreeFind<CR>

" F4 - обновить NERDTree (чтобы видеть новые файлы)
nnoremap <F4> :NERDTreeRefreshRoot<CR>

" Ctrl + n - создать файл или папку в текущей папке NERDTree
nnoremap <C-n> :call CreateFileOrDirectoryInNERDTree()<CR>

" Ctrl + d - удалить файл/папку в NERDTree
nnoremap <C-d> :call DeleteFileOrDirectory()<CR>

" Ctrl + B - переключение между NERDTree и рабочим окном
nnoremap <C-b> :call SwitchBetweenNERDTreeAndCode()<CR>

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

" Alt+O для безопасного открытия (только в рабочей области)
nnoremap <M-o> :call SafeEdit()<CR>
inoremap <M-o> <Esc>:call SafeEdit()<CR>

" Tab для автодополнения путей
cnoremap <expr> <Tab> TerminalTabComplete()

" Shift+Tab для обратного перебора
cnoremap <expr> <S-Tab> wildmenumode() ? "\<Up>" : "\<S-Tab>"

" Ctrl+Space для показа всех вариантов
cnoremap <C-Space> <C-d>

" Alt+O для безопасного открытия (только в рабочей области)
nnoremap <M-o> :call SafeEdit()<CR>
inoremap <M-o> <Esc>:call SafeEdit()<CR>

" === ВАЖНЫЕ МАПИНГИ КОТОРЫЕ НЕ ЗАБИНЖЕНЫ ===

" Быстрое переключение между последними файлами (только в рабочей области)
nnoremap <C-Tab> :call SafeBufferSwitch()<CR>
inoremap <C-Tab> <Esc>:call SafeBufferSwitch()<CR>

" vim-commentary - Ctrl+/ для комментирования/раскомментирования кода
noremap <C-/> :Commentary<CR>
inoremap <C-/> <Esc>:Commentary<CR>a

" Показать текущий выбранный таргет
nnoremap <leader>ct :echo "Current target: " . (empty(g:cmake_selected_target) ? "none" : g:cmake_selected_target)<CR>

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

" Быстрая навигация по директориям
nnoremap <leader>cd :cd %:p:h<CR>:pwd<CR>  " Перейти в директорию текущего файла

" Показать текущий путь
nnoremap <leader>pwd :pwd<CR>

" Создать новую директорию
nnoremap <leader>md :!mkdir -p

" Открыть проводник в текущей директории
nnoremap <leader>ex :!open .<CR>

" === АВТОЗАВЕРШЕНИЕ СКОБОК ===
inoremap " ""<Left>
inoremap ' ''<Left>
inoremap ( ()<Left>
inoremap [ []<Left>
inoremap { {}<Left>

" Умное автозакрытие (только если следующая скобка не открыта)
inoremap <expr> " strpart(getline('.'), col('.')-1, 1) == '"' ? "\<Right>" : '""<Left>'
inoremap <expr> ' strpart(getline('.'), col('.')-1, 1) == "'" ? "\<Right>" : "''<Left>"

" vim-commentary - Ctrl+/ для комментирования/раскомментирования кода
noremap <C-/> :Commentary<CR>
inoremap <C-/> <Esc>:Commentary<CR>a

" Tab для автодополнения
inoremap <expr> <Tab> pumvisible() ? "\<C-y>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

" Enter для подтверждения автодополнения
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<cr>"

" === GIT & GITHUB ===

" \ + G + S - Git status
nnoremap <leader>gs :Git<CR>

" \ + G + C - Git commit
nnoremap <leader>gc :Git commit<CR>

" \ + G + P - Git push
nnoremap <leader>gp :Git push<CR>

" \ + G + L Git pull
nnoremap <leader>gl :Git pull<CR>

" \ + G + O Открыть текущий файл на GitHub через vim-rhubarb
nnoremap <leader>go :GBrowse<CR>
