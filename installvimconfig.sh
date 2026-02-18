#!/usr/bin/env bash

set -euo pipefail

# ==========================================
# ==== Установка конфигурации VimConfig ====
# ==========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_VIMRC="$SCRIPT_DIR/.vimrc"
SRC_VIMCONFIGS_DIR="$SCRIPT_DIR/vimconfigs"

DEST_VIM_DIR="$HOME/.vim"
DEST_VIMCONFIGS_DIR="$DEST_VIM_DIR/vimconfigs"
DEST_VIMRC="$HOME/.vimrc"

echo "Установка VimConfig из: $SCRIPT_DIR"

if [[ ! -f "$SRC_VIMRC" ]]; then
    echo "Ошибка: не найден файл $SRC_VIMRC"
    exit 1
fi

if [[ ! -d "$SRC_VIMCONFIGS_DIR" ]]; then
    echo "Ошибка: не найдена директория $SRC_VIMCONFIGS_DIR"
    exit 1
fi

# Создаем целевую директорию Vim.
mkdir -p "$DEST_VIMCONFIGS_DIR"

# Сохраняем резервную копию старого .vimrc (если был).
if [[ -f "$DEST_VIMRC" ]]; then
    BACKUP_PATH="$HOME/.vimrc.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$DEST_VIMRC" "$BACKUP_PATH"
    echo "Сделан backup: $BACKUP_PATH"
fi

# Синхронизируем весь vimconfigs, чтобы новые файлы добавлялись,
# а удаленные из репозитория удалялись в ~/.vim/vimconfigs.
if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete \
        --exclude '.DS_Store' \
        --exclude '*.swp' \
        --exclude '*.swo' \
        "$SRC_VIMCONFIGS_DIR"/ "$DEST_VIMCONFIGS_DIR"/
else
    echo "rsync не найден, используем cp (без удаления старых файлов)"
    cp -a "$SRC_VIMCONFIGS_DIR"/. "$DEST_VIMCONFIGS_DIR"/
    find "$DEST_VIMCONFIGS_DIR" -name '.DS_Store' -delete || true
    find "$DEST_VIMCONFIGS_DIR" -name '*.swp' -delete || true
    find "$DEST_VIMCONFIGS_DIR" -name '*.swo' -delete || true
fi

# Копируем основной .vimrc.
cp "$SRC_VIMRC" "$DEST_VIMRC"
echo "Скопирован: $DEST_VIMRC"

# Устанавливаем vim-plug (если доступен curl).
echo "Проверка vim-plug..."
if command -v curl >/dev/null 2>&1; then
    curl -fsLo "$DEST_VIM_DIR/autoload/plug.vim" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    echo "vim-plug установлен/обновлен."
else
    echo "curl не найден, пропускаем установку vim-plug."
fi

# Устанавливаем шрифт Fixedsys Excelsior 3.01 (best effort).
FONT_URL="https://g.webfontfree.com/Download/20260212/en/9f/Fonts_Package_9fd2d11bcef8b0e1cdaf65627c325ac1.zip"
if command -v curl >/dev/null 2>&1 && command -v unzip >/dev/null 2>&1; then
    TEMP_DIR="$(mktemp -d)"
    trap 'rm -rf "$TEMP_DIR"' EXIT

    echo "Скачиваем пакет шрифтов..."
    if curl -fL "$FONT_URL" -o "$TEMP_DIR/fonts.zip"; then
        unzip -oq "$TEMP_DIR/fonts.zip" -d "$TEMP_DIR/fonts"

        OS="$(uname)"
        FONT_DIR=""
        if [[ "$OS" == "Darwin" ]]; then
            FONT_DIR="$HOME/Library/Fonts"
        elif [[ "$OS" == "Linux" ]]; then
            FONT_DIR="$HOME/.local/share/fonts"
        elif [[ "$OS" == MINGW* || "$OS" == CYGWIN* || "$OS" == MSYS* ]]; then
            FONT_DIR="${LOCALAPPDATA:-}/Microsoft/Windows/Fonts"
        fi

        if [[ -n "$FONT_DIR" ]]; then
            mkdir -p "$FONT_DIR"
            find "$TEMP_DIR/fonts" -type f \( -name '*.ttf' -o -name '*.otf' \) -exec cp {} "$FONT_DIR"/ \;
            echo "Шрифты скопированы в: $FONT_DIR"
        else
            echo "Не удалось определить директорию шрифтов для ОС: $OS"
        fi
    else
        echo "Не удалось скачать шрифты, шаг пропущен."
    fi
else
    echo "curl/unzip недоступны, установка шрифта пропущена."
fi

# Устанавливаем плагины через vim-plug.
if command -v vim >/dev/null 2>&1; then
    echo "Устанавливаем плагины Vim..."
    vim -E -s +PlugInstall +qall || echo "Предупреждение: PlugInstall завершился с ошибкой."
else
    echo "vim не найден в PATH, пропускаем PlugInstall."
fi

echo "Готово. Конфигурация установлена."
