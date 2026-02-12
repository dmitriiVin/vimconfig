#!/bin/bash

# ================================
# ====     Настройка Vim       ===
# ================================

SRC_DIR="./vimconfigs"
DEST_DIR="$HOME/.vim/vimconfigs"

SRC_FUNC_DIR="$SRC_DIR/functions"
DEST_FUNC_DIR="$DEST_DIR/functions"

SRC_COLORS_DIR="$SRC_DIR/colors"
DEST_COLORS_DIR="$DEST_DIR/colors"

echo "Установка Vim конфигурации..."

# Создаем директории
mkdir -p "$DEST_DIR"
mkdir -p "$DEST_FUNC_DIR"
mkdir -p "$DEST_COLORS_DIR"

# Копируем конфигурационные файлы
cp "$SRC_DIR"/autocmd.vim "$DEST_DIR"/
cp "$SRC_DIR"/mappings.vim "$DEST_DIR"/
cp "$SRC_DIR"/options.vim "$DEST_DIR"/
cp "$SRC_DIR"/plugins.vim "$DEST_DIR"/

cp "$SRC_FUNC_DIR"/*.vim "$DEST_FUNC_DIR"/
cp "$SRC_COLORS_DIR"/*.vim "$DEST_COLORS_DIR"/

cp "./.vimrc" "$HOME"/.vimrc

# Устанавливаем vim-plug
echo "Устанавливаем vim-plug..."
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

sleep 2

# ================================
# ===== Установка шрифта =========
# ================================

FONT_URL="https://g.webfontfree.com/Download/20260212/en/9f/Fonts_Package_9fd2d11bcef8b0e1cdaf65627c325ac1.zip"
TEMP_DIR=$(mktemp -d)

echo "Скачиваем шрифт..."
curl -L "$FONT_URL" -o "$TEMP_DIR/fonts.zip"
unzip "$TEMP_DIR/fonts.zip" -d "$TEMP_DIR/fonts"

# Определяем платформу
OS=$(uname)
echo "Определяем платформу: $OS"

if [[ "$OS" == "Darwin" ]]; then
    # macOS
    FONT_DIR="$HOME/Library/Fonts"
elif [[ "$OS" == "Linux" ]]; then
    # Linux
    FONT_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONT_DIR"
elif [[ "$OS" == "MINGW"* || "$OS" == "CYGWIN"* || "$OS" == "MSYS"* ]]; then
    # Windows / WSL
    FONT_DIR="$LOCALAPPDATA/Microsoft/Windows/Fonts"
    mkdir -p "$FONT_DIR"
else
    echo "Неизвестная ОС, шрифт не установлен."
    FONT_DIR=""
fi

# Копируем шрифты
if [[ -n "$FONT_DIR" ]]; then
    cp "$TEMP_DIR/fonts"/*.{ttf,otf} "$FONT_DIR"/ 2>/dev/null
    echo "Шрифты установлены в $FONT_DIR"
fi

rm -rf "$TEMP_DIR"

# ================================
# ===== Установка плагинов =======
# ================================

echo "Устанавливаем плагины Vim..."
vim +PlugInstall +qall

echo "✅ Установка завершена! Запустите 'vim' для проверки."
