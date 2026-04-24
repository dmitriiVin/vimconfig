" === ПЛАГИНЫ ===
call plug#begin('~/.vim/plugged')

let s:vimconfig_coc_vim_ok = 0
if has('nvim')
  let s:vimconfig_coc_vim_ok = has('nvim-0.8')
else
  " coc.nvim requires at least Vim 9.0.0438 because it uses Vim9 features (:export, etc).
  let s:vimconfig_coc_vim_ok = has('patch-9.0.0438')
endif

let s:vimconfig_coc_node_ok = 0
let s:vimconfig_node_bin = get(g:, 'coc_node_path', '')
if empty(s:vimconfig_node_bin) && executable('node')
  let s:vimconfig_node_bin = exepath('node')
endif
if !empty(s:vimconfig_node_bin)
  let s:vimconfig_node_ver = system(s:vimconfig_node_bin . ' --version')
  let s:vimconfig_node_ver = substitute(s:vimconfig_node_ver, '\n\+$', '', '')
  let s:vimconfig_m = matchlist(s:vimconfig_node_ver, '^v\(\d\+\)\.\(\d\+\)\.\(\d\+\)$')
  if len(s:vimconfig_m) >= 4
    let s:vimconfig_node_major = str2nr(s:vimconfig_m[1])
    let s:vimconfig_node_minor = str2nr(s:vimconfig_m[2])
    " coc.nvim requires Node.js >= 16.18.0
    let s:vimconfig_coc_node_ok = (s:vimconfig_node_major > 16) || (s:vimconfig_node_major == 16 && s:vimconfig_node_minor >= 18)
  endif
endif

if s:vimconfig_coc_vim_ok && s:vimconfig_coc_node_ok
  let g:vimconfig_coc_enabled = 1
  Plug 'neoclide/coc.nvim', {'branch': 'release'}
else
  let g:vimconfig_coc_enabled = 0
endif

Plug 'jiangmiao/auto-pairs'

" === THEMES ===
Plug 'morhetz/gruvbox'
Plug 'cormacrelf/vim-colors-github'

" Дополнительные полезные плагины
Plug 'scrooloose/nerdtree'              " Файловый менеджер
Plug 'tpope/vim-commentary'             " Комментирование кода
Plug 'airblade/vim-gitgutter'           " Git статус на полях
Plug 'vim-airline/vim-airline'          " Статус бар
Plug 'vim-airline/vim-airline-themes'   " Темы для статус бара
Plug 'bfrg/vim-cpp-modern'
Plug 'cdelledonne/vim-cmake'           " Основной функционал
Plug 'pboettch/vim-cmake-syntax'       " Подсветка синтаксиса
Plug 'ilyachur/cmake4vim'              " Дополнение и утилиты

" === GIT И GITHUB ИНТЕГРАЦИЯ ===
Plug 'tpope/vim-fugitive'      " Git интеграция
Plug 'tpope/vim-rhubarb'       " GitHub интеграция

call plug#end()

" Цветовая схема ставим после установки всех плагинов
" colorscheme github
set background=dark
