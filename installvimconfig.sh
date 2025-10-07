#!/bin/bash

SRC_DIR="./vimconfigs"
DEST_DIR="$HOME/.vim/vimconfigs"

SRC_FUNC_DIR="./vimconfigs/functions"
DEST_FUNC_DIR="$HOME/.vim/vimconfigs/functions"

echo "Установка Vim конфигурации..."

# Создаем основные директории
mkdir -p "$DEST_DIR"
mkdir -p "$DEST_FUNC_DIR"

# Копируем конфигурационные файлы
cp "$SRC_DIR"/autocmd.vim "$DEST_DIR"/
cp "$SRC_DIR"/mappings.vim "$DEST_DIR"/
cp "$SRC_DIR"/options.vim "$DEST_DIR"/
cp "$SRC_DIR"/plugins.vim "$DEST_DIR"/

cp "$SRC_FUNC_DIR"/cmake.vim "$DEST_FUNC_DIR"/
cp "$SRC_FUNC_DIR"/github.vim "$DEST_FUNC_DIR"/
cp "$SRC_FUNC_DIR"/nerdtree.vim "$DEST_FUNC_DIR"/
cp "$SRC_FUNC_DIR"/runcode.vim "$DEST_FUNC_DIR"/
cp "$SRC_FUNC_DIR"/terminal.vim "$DEST_FUNC_DIR"/

cp "./.vimrc" "$HOME"/.vimrc

# Устанавливаем vim-plug
echo "Устанавливаем vim-plug..."
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# Ждем немного чтобы убедиться что curl завершился
sleep 2

# Устанавливаем плагины через Vim
echo "Устанавливаем плагины (это может занять некоторое время)..."
vim +PlugInstall +qall

echo "✅ Vim конфигурация успешно установлена!"
echo "Плагины установлены. Запустите 'vim' для начала работы."