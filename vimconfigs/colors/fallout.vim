" ================================
" === Fallout Terminal Colors ===
" ================================

if !has("termguicolors")
  set t_Co=256
endif

set termguicolors
set background=dark

" Основной текст
highlight Normal guifg=#19FF19 guibg=#000000

" Комментарии
highlight Comment guifg=#33FF33 guibg=#000000 cterm=italic

" Строки, ключи и команды
highlight Statement guifg=#19FF19 guibg=#000000
highlight Identifier guifg=#19FF19 guibg=#000000
highlight Constant guifg=#19FF19 guibg=#000000
highlight Type guifg=#19FF19 guibg=#000000

" Подсветка поиска
highlight Search guifg=#000000 guibg=#19FF19

" Линия курсора
highlight CursorLine guibg=#001a00
set cursorline
