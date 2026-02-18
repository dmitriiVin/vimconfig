#!/usr/bin/env bash

set -euo pipefail

# ==========================================
# ==== Установка конфигурации VimConfig ====
# ==========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_VIMRC="$SCRIPT_DIR/.vimrc"
SRC_VIMCONFIGS_DIR="$SCRIPT_DIR/vimconfigs"
SRC_COC_SETTINGS="$SCRIPT_DIR/coc-settings.json"

DEST_VIM_DIR="$HOME/.vim"
DEST_VIMCONFIGS_DIR="$DEST_VIM_DIR/vimconfigs"
DEST_VIMRC="$HOME/.vimrc"
DEST_VIM_COC_SETTINGS="$DEST_VIM_DIR/coc-settings.json"
DEST_COC_DIR="$HOME/.config/coc"
DEST_COC_SETTINGS="$DEST_COC_DIR/coc-settings.json"
DEST_COC_EXT_DIR="$DEST_COC_DIR/extensions"

OS="$(uname -s)"

log() { echo "[vimconfig] $*"; }
warn() { echo "[vimconfig][warn] $*"; }
err() { echo "[vimconfig][error] $*" >&2; }

have_cmd() {
    command -v "$1" >/dev/null 2>&1
}

append_line_if_missing() {
    local file="$1"
    local line="$2"
    touch "$file"
    grep -Fqx "$line" "$file" || echo "$line" >> "$file"
}

ensure_brew() {
    if have_cmd brew; then
        return 0
    fi

    if [[ "$OS" != "Darwin" ]]; then
        return 1
    fi

    if ! have_cmd curl; then
        warn "curl не найден, не могу установить Homebrew автоматически."
        return 1
    fi

    log "Homebrew не найден, устанавливаю..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
        warn "Не удалось установить Homebrew."
        return 1
    }

    if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    have_cmd brew
}

brew_install_if_missing() {
    local formula="$1"
    if ! have_cmd brew; then
        return 1
    fi

    if brew list --formula "$formula" >/dev/null 2>&1; then
        log "skip: $formula уже установлен."
        return 0
    fi

    log "Устанавливаю $formula ..."
    brew install "$formula"
}

apt_install_if_missing() {
    local pkg="$1"
    if ! have_cmd apt-get; then
        return 1
    fi

    if dpkg -s "$pkg" >/dev/null 2>&1; then
        log "skip: $pkg уже установлен."
        return 0
    fi

    if have_cmd sudo; then
        log "Устанавливаю $pkg (apt) ..."
        sudo apt-get install -y "$pkg"
    else
        warn "sudo недоступен, пропускаю установку $pkg."
    fi
}

install_base_dependencies() {
    log "Проверка базовых зависимостей..."

    if [[ "$OS" == "Darwin" ]]; then
        ensure_brew || warn "Homebrew не удалось подготовить, часть зависимостей может не установиться."

        brew_install_if_missing git || true
        brew_install_if_missing curl || true
        brew_install_if_missing rsync || true
        brew_install_if_missing unzip || true
        brew_install_if_missing cmake || true
        brew_install_if_missing ninja || true
        brew_install_if_missing ripgrep || true
        brew_install_if_missing shellcheck || true
        brew_install_if_missing node@20 || true
        brew_install_if_missing neocmakelsp || true
    elif [[ "$OS" == "Linux" ]]; then
        if have_cmd apt-get && have_cmd sudo; then
            log "Обновляю индекс apt..."
            sudo apt-get update -y
        fi

        apt_install_if_missing git || true
        apt_install_if_missing curl || true
        apt_install_if_missing rsync || true
        apt_install_if_missing unzip || true
        apt_install_if_missing cmake || true
        apt_install_if_missing ninja-build || true
        apt_install_if_missing ripgrep || true
        apt_install_if_missing shellcheck || true
        apt_install_if_missing nodejs || true
        apt_install_if_missing npm || true
        apt_install_if_missing python3 || true
        apt_install_if_missing python3-pip || true
    else
        warn "Неизвестная ОС ($OS), автоматическая установка зависимостей ограничена."
    fi
}

detect_node_bin() {
    if [[ -x /opt/homebrew/opt/node@20/bin/node ]]; then
        echo "/opt/homebrew/opt/node@20/bin/node"
        return 0
    fi
    if have_cmd node; then
        command -v node
        return 0
    fi
    return 1
}

detect_npm_bin() {
    if [[ -x /opt/homebrew/opt/node@20/bin/npm ]]; then
        echo "/opt/homebrew/opt/node@20/bin/npm"
        return 0
    fi
    if have_cmd npm; then
        command -v npm
        return 0
    fi
    return 1
}

install_coc_extensions() {
    local npm_bin
    if ! npm_bin="$(detect_npm_bin)"; then
        warn "npm не найден, установка CoC extensions пропущена."
        return 0
    fi

    mkdir -p "$DEST_COC_EXT_DIR"
    cd "$DEST_COC_EXT_DIR"

    if [[ ! -f package.json ]]; then
        cat > package.json <<'JSON'
{
  "dependencies": {}
}
JSON
    fi

    log "Устанавливаю CoC extensions..."
    "$npm_bin" install \
        coc-clangd coc-cmake coc-css coc-json coc-pyright coc-rust-analyzer coc-sh coc-tsserver coc-yaml \
        pyright \
        vscode-langservers-extracted \
        --save --no-audit --no-fund

    # Чистим известные конфликтные/лишние расширения.
    "$npm_bin" remove coc-python coc-omnisharp coc-html --no-audit --no-fund >/dev/null 2>&1 || true
}

find_existing_vcpkg_root() {
    local roots=()

    if [[ -n "${VCPKG_ROOT:-}" ]]; then
        roots+=("$VCPKG_ROOT")
    fi

    roots+=("$HOME/vcpkg" "$HOME/.vcpkg" "$SCRIPT_DIR/vcpkg")

    local vcpkg_exe
    if vcpkg_exe="$(command -v vcpkg 2>/dev/null)"; then
        roots+=("$(cd "$(dirname "$vcpkg_exe")" && pwd)")
    fi

    local root
    for root in "${roots[@]}"; do
        [[ -z "$root" ]] && continue
        if [[ -f "$root/scripts/buildsystems/vcpkg.cmake" ]]; then
            echo "$root"
            return 0
        fi
    done

    return 1
}

bootstrap_vcpkg() {
    local root="$1"
    if [[ ! -d "$root" ]]; then
        return 1
    fi

    if [[ -x "$root/vcpkg" ]]; then
        return 0
    fi

    if [[ -x "$root/bootstrap-vcpkg.sh" ]]; then
        log "Bootstrap vcpkg..."
        (cd "$root" && ./bootstrap-vcpkg.sh -disableMetrics)
    else
        warn "Не найден bootstrap-vcpkg.sh в $root"
        return 1
    fi
}

ensure_vcpkg() {
    local root=""

    if root="$(find_existing_vcpkg_root)"; then
        log "vcpkg найден: $root"
    else
        if ! have_cmd git; then
            warn "git не найден, не могу скачать vcpkg автоматически."
            return 0
        fi

        root="$HOME/vcpkg"
        if [[ ! -d "$root" ]]; then
            log "Скачиваю vcpkg в $root ..."
            git clone https://github.com/microsoft/vcpkg.git "$root" || {
                warn "Не удалось клонировать vcpkg."
                return 0
            }
        fi
    fi

    bootstrap_vcpkg "$root" || true

    export VCPKG_ROOT="$root"
    log "VCPKG_ROOT=$VCPKG_ROOT"

    append_line_if_missing "$HOME/.zprofile" ""
    append_line_if_missing "$HOME/.zprofile" "# VimConfig vcpkg"
    append_line_if_missing "$HOME/.zprofile" "export VCPKG_ROOT=\"$VCPKG_ROOT\""
    append_line_if_missing "$HOME/.zprofile" "export PATH=\"\$PATH:\$VCPKG_ROOT\""
}

copy_config_files() {
    if [[ ! -f "$SRC_VIMRC" ]]; then
        err "Не найден файл $SRC_VIMRC"
        exit 1
    fi

    if [[ ! -d "$SRC_VIMCONFIGS_DIR" ]]; then
        err "Не найдена директория $SRC_VIMCONFIGS_DIR"
        exit 1
    fi

    mkdir -p "$DEST_VIMCONFIGS_DIR"

    if [[ -f "$DEST_VIMRC" ]]; then
        local backup_path="$HOME/.vimrc.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$DEST_VIMRC" "$backup_path"
        log "Сделан backup: $backup_path"
    fi

    if have_cmd rsync; then
        rsync -a --delete \
            --exclude '.DS_Store' \
            --exclude '*.swp' \
            --exclude '*.swo' \
            "$SRC_VIMCONFIGS_DIR"/ "$DEST_VIMCONFIGS_DIR"/
    else
        warn "rsync не найден, использую cp (без удаления лишних файлов)."
        cp -a "$SRC_VIMCONFIGS_DIR"/. "$DEST_VIMCONFIGS_DIR"/
        find "$DEST_VIMCONFIGS_DIR" -name '.DS_Store' -delete || true
        find "$DEST_VIMCONFIGS_DIR" -name '*.swp' -delete || true
        find "$DEST_VIMCONFIGS_DIR" -name '*.swo' -delete || true
    fi

    cp "$SRC_VIMRC" "$DEST_VIMRC"
    log "Скопирован: $DEST_VIMRC"

    if [[ -f "$SRC_COC_SETTINGS" ]]; then
        mkdir -p "$DEST_VIM_DIR"
        cp "$SRC_COC_SETTINGS" "$DEST_VIM_COC_SETTINGS"
        log "Скопирован: $DEST_VIM_COC_SETTINGS"

        mkdir -p "$DEST_COC_DIR"
        cp "$SRC_COC_SETTINGS" "$DEST_COC_SETTINGS"
        log "Скопирован: $DEST_COC_SETTINGS"
    fi
}

install_vim_plug() {
    if ! have_cmd curl; then
        warn "curl не найден, установка vim-plug пропущена."
        return 0
    fi

    curl -fsLo "$DEST_VIM_DIR/autoload/plug.vim" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    log "vim-plug установлен/обновлен."
}

install_fonts_best_effort() {
    local font_url="https://g.webfontfree.com/Download/20260212/en/9f/Fonts_Package_9fd2d11bcef8b0e1cdaf65627c325ac1.zip"

    if ! have_cmd curl || ! have_cmd unzip; then
        warn "curl/unzip недоступны, установка шрифта пропущена."
        return 0
    fi

    local temp_dir
    temp_dir="$(mktemp -d)"
    trap 'rm -rf "$temp_dir"' EXIT

    log "Скачиваем пакет шрифтов..."
    if ! curl -fsSL "$font_url" -o "$temp_dir/fonts.zip" 2>/dev/null; then
        warn "Не удалось скачать пакет шрифтов, шаг пропущен."
        return 0
    fi

    unzip -oq "$temp_dir/fonts.zip" -d "$temp_dir/fonts"

    local font_dir=""
    if [[ "$OS" == "Darwin" ]]; then
        font_dir="$HOME/Library/Fonts"
    elif [[ "$OS" == "Linux" ]]; then
        font_dir="$HOME/.local/share/fonts"
    fi

    if [[ -n "$font_dir" ]]; then
        mkdir -p "$font_dir"
        find "$temp_dir/fonts" -type f \( -name '*.ttf' -o -name '*.otf' \) -exec cp {} "$font_dir"/ \;
        log "Шрифты скопированы в: $font_dir"
    fi
}

install_vim_plugins() {
    if ! have_cmd vim; then
        warn "vim не найден в PATH, PlugInstall пропущен."
        return 0
    fi

    log "Устанавливаем плагины Vim..."
    vim -Nu "$DEST_VIMRC" -N -n -E +PlugInstall +qall || warn "PlugInstall завершился с ошибкой."
}

main() {
    log "Установка VimConfig из: $SCRIPT_DIR"

    install_base_dependencies
    copy_config_files
    ensure_vcpkg
    install_vim_plug
    install_coc_extensions
    install_fonts_best_effort
    install_vim_plugins

    local node_bin=""
    if node_bin="$(detect_node_bin)"; then
        log "Node для CoC: $node_bin"
    fi

    log "Готово. Конфигурация установлена."
}

main "$@"
