" ================================
" ===      ОСНОВНОЙ ФАЙЛ       ===
" ================================

" подключаем авто функции
source ~/.vim/vimconfigs/autocmd.vim

" === Подключаем функции ===
source ~/.vim/vimconfigs/functions/cmake.vim
source ~/.vim/vimconfigs/functions/nerdtree.vim
source ~/.vim/vimconfigs/functions/runcode.vim
source ~/.vim/vimconfigs/functions/terminal.vim
source ~/.vim/vimconfigs/functions/github.vim
source ~/.vim/vimconfigs/functions/coc_russian.vim
source ~/.vim/vimconfigs/functions/help.vim

" === Подключаем бинды ===
source ~/.vim/vimconfigs/mappings.vim

" === подключаем опции ===
source ~/.vim/vimconfigs/options.vim

" === CoC: популярные языки ===
let g:coc_global_extensions = [
            \ 'coc-clangd',
            \ 'coc-json',
            \ 'coc-tsserver',
            \ 'coc-html',
            \ 'coc-css',
            \ 'coc-yaml',
            \ 'coc-pyright',
            \ 'coc-omnisharp',
            \ 'coc-rust-analyzer',
            \ 'coc-cmake',
            \ 'coc-sh'
            \ ]

" === Подключаем плагины ===
source ~/.vim/vimconfigs/plugins.vim

call ApplyStartupTheme()
