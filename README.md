# VimConfig

Подробная модульная конфигурация Vim для ежедневной разработки с упором на:

- C/C++ и CMake,
- быстрый цикл `generate -> build -> run`,
- постоянный мониторинг ошибок через quickfix,
- удобную навигацию по буферам/окнам,
- гибкую настройку тем и GUI-шрифтов,
- стабильную установку на macOS и Linux.

Конфиг разворачивается из этого репозитория в `~/.vim` и `~/.vimrc`.

---

## 1. Что именно дает этот конфиг

1. Единый `F`-workflow для CMake:
   - `F6` генерация,
   - `F7` сборка,
   - `F8` выбор исполняемого файла,
   - `F9` запуск,
   - `F10` переключение `Debug/Release`.
2. Локальные версии кода для `Debug/Release`:
   - при `F10` код может автоматически подменяться между профилями,
   - профили хранятся в `.vim-code-profiles/debug` и `.vim-code-profiles/release`.
3. Автоматический quickfix-монитор:
   - открывается автоматически,
   - не перехватывает фокус,
   - используется как панель мониторинга ошибок.
4. CoC/LSP для популярных языков (через `coc.nvim` и расширения).
5. Модульность:
   - `mappings.vim` — только клавиши,
   - `options.vim` — только опции,
   - `autocmd.vim` — автокоманды,
   - `functions/*.vim` — функции по подсистемам.

---

## 2. Полная структура репозитория

```text
vimconfig/
├── .vimrc
├── README.md
├── coc-settings.json
├── installvimconfig.sh
└── vimconfigs/
    ├── autocmd.vim
    ├── mappings.vim
    ├── options.vim
    ├── plugins.vim
    ├── theme_state.vim
    ├── colors/
    │   ├── blue_dark.vim
    │   ├── desert_dark.vim
    │   ├── elflord_dark.vim
    │   ├── evening_dark.vim
    │   ├── fallout.vim
    │   ├── github_dark.vim
    │   ├── github_light.vim
    │   ├── gruvbox_dark_hard.vim
    │   ├── gruvbox_dark_soft.vim
    │   ├── gruvbox_light_soft.vim
    │   ├── industry_dark.vim
    │   ├── murphy_dark.vim
    │   ├── ron_dark.vim
    │   ├── slate_dark.vim
    │   └── zellner_light.vim
    └── functions/
        ├── cmake.vim
        ├── coc_russian.vim
        ├── github.vim
        ├── help.vim
        ├── nerdtree.vim
        ├── runcode.vim
        └── terminal.vim
```

---

## 3. Назначение каждого ключевого файла

### 3.1 Верхний уровень

- `.vimrc`
  - точка входа,
  - задает `g:coc_node_path`,
  - подключает все модули,
  - задает `g:coc_global_extensions`.
- `coc-settings.json`
  - CoC diagnostics,
  - pyright,
  - neocmakelsp,
  - root patterns.
- `installvimconfig.sh`
  - установка зависимостей,
  - копирование конфигов,
  - установка/обновление `vim-plug`, CoC extensions и плагинов.
- `README.md`
  - эта подробная документация.

### 3.2 Каталог `vimconfigs/`

- `options.vim`
  - `number`, `indent`, `search`, `wildmenu`, `airline`,
  - CMake глобальные переменные,
  - theme/font subsystem.
- `mappings.vim`
  - все горячие клавиши.
- `autocmd.vim`
  - quickfix monitor,
  - compile_commands watcher,
  - live diagnostic refresh,
  - NERDTree window-local rules.
- `plugins.vim`
  - список плагинов (`vim-plug`).
- `theme_state.vim`
  - автогенерируемое сохранение последней темы.

### 3.3 Каталог `vimconfigs/functions/`

- `cmake.vim`
  - логика F6/F7/F8/F9/F10/F12,
  - автогенерация build,
  - выбор/запуск target,
  - локальные профили кода `Debug/Release`.
- `help.vim`
  - встроенная справка `\h` в текущем окне,
  - выход из help по `Esc`.
- `nerdtree.vim`
  - операции создания/переименования/удаления в дереве.
- `runcode.vim`
  - запуск файлов по filetype (F5).
- `terminal.vim`
  - утилиты терминального режима и path completion.
- `github.vim`
  - fugitive/rhubarb функции.
- `coc_russian.vim`
  - русифицированные helper-команды для CoC.

---

## 4. Установка

## 4.1 Быстрая установка (рекомендуется)

```bash
git clone https://github.com/dmitriiVin/vimconfig.git
cd vimconfig
chmod +x installvimconfig.sh
./installvimconfig.sh
```

Скрипт выполняет:

1. Проверку и установку базовых зависимостей.
2. Backup текущего `~/.vimrc`.
3. Копирование `.vimrc` и `vimconfigs/` в `~/.vim`.
4. Копирование `coc-settings.json` в:
   - `~/.vim/coc-settings.json`,
   - `~/.config/coc/coc-settings.json`.
5. Установку `vim-plug`.
6. Установку CoC extensions через npm.
7. Best-effort установку шрифтов.
8. `PlugInstall`.

## 4.2 Установка вручную

```bash
mkdir -p ~/.vim/vimconfigs
cp -R vimconfigs/* ~/.vim/vimconfigs/
cp .vimrc ~/.vimrc
cp coc-settings.json ~/.vim/coc-settings.json
mkdir -p ~/.config/coc
cp coc-settings.json ~/.config/coc/coc-settings.json
```

Затем в Vim:

```vim
:PlugInstall
:CocRestart
```

---

## 5. Зависимости

### 5.1 macOS (через brew)

- `git`, `curl`, `rsync`, `unzip`
- `cmake`, `ninja`
- `ripgrep`, `shellcheck`
- `node@20`
- `neocmakelsp`

### 5.2 Linux (apt)

- `git`, `curl`, `rsync`, `unzip`
- `cmake`, `ninja-build`
- `ripgrep`, `shellcheck`
- `nodejs`, `npm`
- `python3`, `python3-pip`

### 5.3 CoC extensions

Устанавливаются скриптом:

- `coc-clangd`
- `coc-cmake`
- `coc-css`
- `coc-json`
- `coc-pyright`
- `coc-rust-analyzer`
- `coc-sh`
- `coc-tsserver`
- `coc-yaml`
- `pyright`
- `vscode-langservers-extracted`

---

## 6. Все основные горячие клавиши

Лидер-клавиша: `\`

## 6.1 Базовые

- `Ctrl+S` — сохранить.
- `Ctrl+B` — закрыть текущий буфер (`:bp|bd #`).
- `Ctrl+X` / `\x` — альтернативное закрытие буфера.
- `Ctrl+Z` — undo.

## 6.2 Навигация по буферам/окнам

- `Tab` / `Shift+Tab` — циклический переход по рабочим буферам.
- `Tab+←/→/↑/↓` — переход между окнами.
- `Shift+←/→/↑/↓` — быстрый переход между окнами.
- `Ctrl+Tab` — `:b#`.

## 6.3 Поиск/редактирование

- `Ctrl+F` — поиск.
- `Ctrl+H` — `:nohlsearch`.
- `Ctrl+A` — выделить весь файл.
- `Ctrl+D` / `Ctrl+K` — удалить строку или выделение.
- `\c` — `vim-commentary`.

## 6.4 Файлы и буферы

- `Ctrl+N` — создать файл.
- `Ctrl+O` — открыть файл от текущей директории.
- `Ctrl+E` — открыть из директории текущего файла.
- `Ctrl+P` — `:find *`.
- `Alt+O` — `SafeEdit()`.
- `\bl` — список буферов.
- `\bd` — закрыть буфер.
- `\bo` — закрыть все, кроме текущего.
- `\cd` — перейти в директорию текущего файла.
- `\pwd` — показать cwd.
- `\md` — mkdir.
- `\ex` — открыть текущую папку в Finder.

## 6.5 NERDTree

- `F1` — toggle NERDTree.
- `F4` — refresh tree.
- `Ctrl+N` — создать файл/папку (в NERDTree).
- `Ctrl+D` — удалить файл/папку (в NERDTree).
- `i` — смена cwd на выбранную директорию.

## 6.6 CMake и запуск

- `F3` — удалить папку `build` текущего проекта.
- `F6` — CMake generate.
- `F7` — CMake build (с автогенерацией при отсутствии build).
- `F8` — интерактивный выбор target.
- `F9` — запуск выбранного target.
- `F10` — переключить `Debug/Release`.
- `F12` — создать/открыть `CMakeLists.txt` из NERDTree.
- `\ru` — generate + build + auto-select target + run.
- `\bt` — показать текущий build type.
- `\ct` — показать путь текущего выбранного target.

## 6.7 Quickfix и диагностика

- `Ctrl+W` — открыть quickfix монитор.
- `Ctrl+Q` — закрыть quickfix.
- `\qn` / `\qp` — next/prev ошибка.
- `\qf` / `\ql` — first/last ошибка.

## 6.8 Git/Fugitive

- `\gs` — `:Git`.
- `\gc` — `:Git commit`.
- `\gp` — `:Git push`.
- `\gl` — `:Git pull`.
- `\go` — `:GBrowse`.

## 6.9 Темы, шрифты, помощь

- `\th` — выбор темы.
- `\ff` — выбор GUI-шрифта.
- `\h` — встроенная help-страница.
- `Ctrl+Shift+R` — полный рестарт Vim.

---

## 7. Как работает F10 и локальные версии кода

Это отдельный механизм, который не требует удаленного репозитория.

1. При первом переключении создается служебный каталог:
   - `.vim-code-profiles/debug`
   - `.vim-code-profiles/release`
2. При `F10`:
   - текущие файлы проекта синхронизируются в активный профиль,
   - целевой профиль копируется обратно в рабочую директорию,
   - буферы перечитываются,
   - при необходимости обновляются target/diagnostics.
3. Служебный каталог `.vim-code-profiles` исключен из:
   - поиска `CMakeLists.txt`,
   - поиска исполняемых файлов,
   - синхронизации build/temporary файлов.

Флаг включения механизма:

```vim
let g:cmake_sync_code_profile_with_build_type = 1
```

Если нужно отключить подмену кода и оставить только переключение build type:

```vim
let g:cmake_sync_code_profile_with_build_type = 0
```

---

## 8. Подсветка, темы и шрифты

## 8.1 Темы

`\th` показывает объединенный список:

- `[preset]` — темы из `vimconfigs/colors/*.vim`,
- `[scheme]` — темы из runtimepath.

Выбранная тема сохраняется в `vimconfigs/theme_state.vim` и восстанавливается при старте.

## 8.2 Шрифт

`\ff` работает в GUI Vim (`guifont`).

В терминальном Vim шрифт задается настройками самого терминала.

---

## 9. Quickfix/LSP/диагностика

- Quickfix открыт автоматически и работает как монитор.
- Есть watcher для `compile_commands.json`.
- При изменениях compile commands выполняется refresh/restart диагностики.
- Диагностика CoC обновляется на `BufEnter`, `BufWritePost`, `InsertLeave`, `FocusGained`.

---

## 10. Типовой рабочий сценарий (CMake)

1. Открыть проект (`cwd` на корень проекта).
2. Нажать `F6` для генерации.
3. Нажать `F7` для сборки.
4. Нажать `F8` выбрать target.
5. Нажать `F9` запустить.
6. Нажать `F10` переключить `Debug/Release` и при включенном режиме профилей получить другую локальную версию кода.

Быстрый режим: `\ru`.

---

## 11. Troubleshooting

## 11.1 После изменения конфига не применилось

Выполнить:

```vim
:source ~/.vim/vimconfigs/options.vim
:source ~/.vim/vimconfigs/mappings.vim
:source ~/.vim/vimconfigs/functions/cmake.vim
:source ~/.vim/vimconfigs/functions/help.vim
```

## 11.2 CoC/LSP работает нестабильно

Проверки:

1. `:CocInfo`
2. `:messages`
3. версия Node (`node -v`)
4. наличие `~/.config/coc/coc-settings.json`

## 11.3 F9 запускает не тот target

1. `F8` выбрать target явно.
2. Проверить текущий target через `\ct`.
3. После `F10` target ретаргетится автоматически, но если бинарника нет, сделайте `F7`.

## 11.4 Подсветка странная после переключений

Выполнить:

```vim
:e!
:syntax on
:filetype detect
```

---

## 12. Обновление и деплой

Обновить локальный репозиторий:

```bash
cd ~/Desktop/vimconfig
git pull
```

Переустановить конфиг:

```bash
./installvimconfig.sh
```

---

## 13. Встроенная справка

Главная команда:

- `\h`

Особенности:

- открывается в текущем рабочем окне,
- выход по `Esc`,
- содержит список ключей и список основных файлов конфигурации.

