#!/bin/bash

SRC_DIR="./vimconfigs"

DEST_DIR="$HOME/.vim/vimconfigs"

mkdir -p "$DEST_DIR"

cp "$SRC_DIR"/autocmds.vim "$DEST_DIR"/
cp "$SRC_DIR"/functions.vim "$DEST_DIR"/
cp "$SRC_DIR"/mappings.vim "$DEST_DIR"/
cp "$SRC_DIR"/options.vim "$DEST_DIR"/
cp "$SRC_DIR"/plugins.vim "$DEST_DIR"/

cp "./.vimrc" "$HOME"/.vimrc

echo "Vim конфигурация установлена!"
