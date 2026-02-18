# VimConfig

Персональная модульная конфигурация Vim для C/C++ и CMake-проектов с:

- удобной навигацией по буферам и окнам,
- постоянным quickfix-мониторингом ошибок,
- CoC/LSP (clangd, python, ts/js, html/css/json/yaml, c#, rust, cmake и т.д.),
- интерактивным выбором тем и GUI-шрифтов,
- горячими клавишами для ежедневной работы.

Конфиг ориентирован на macOS/Linux и устанавливается через `installvimconfig.sh`.

---

## 1. Структура репозитория

```text
vimconfig/
├── .vimrc
├── installvimconfig.sh
├── README.md
└── vimconfigs/
    ├── autocmd.vim
    ├── mappings.vim
    ├── options.vim
    ├── plugins.vim
    ├── theme_state.vim                 # автогенерируется после выбора темы
    ├── colors/
    │   ├── fallout.vim
    │   ├── github_dark.vim
    │   ├── github_light.vim
    │   ├── gruvbox_dark_soft.vim
    │   ├── gruvbox_dark_hard.vim
    │   ├── gruvbox_light_soft.vim
    │   └── ...другие пресеты
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

## 2. Быстрая установка

### 2.1 Автоматическая

```bash
git clone https://github.com/dmitriiVin/vimconfig.git
cd vimconfig
chmod +x installvimconfig.sh
./installvimconfig.sh
```

Скрипт:

1. копирует `vimconfigs/*` в `~/.vim/vimconfigs`,
2. копирует `.vimrc` в `~/.vimrc`,
3. ставит `vim-plug`,
4. запускает `:PlugInstall`.

### 2.2 Ручная

```bash
mkdir -p ~/.vim/vimconfigs
cp -R vimconfigs/* ~/.vim/vimconfigs/
cp .vimrc ~/.vimrc
```

Потом в Vim:

```vim
:PlugInstall
:CocRestart
```

---

## 3. Главная справка внутри Vim

Добавлена горячая клавиша:

- `\h` — открыть встроенную подробную справку по конфигурации.

Справка открывается в отдельном scratch-буфере и содержит список всех основных хоткеев и их назначение.

---

## 4. Основные горячие клавиши

Лидер-клавиша: `\`

## 4.1 Базовые операции

- `Ctrl+S` — сохранить файл.
- `Ctrl+B` — закрыть текущий буфер (`:bp | bd #`).
- `Tab` / `Shift+Tab` — переключение рабочих буферов.
- `Tab+стрелки` — переход между окнами (`NERDTree`/код/quickfix).
- `Shift+стрелки` — быстрый переход между окнами.

## 4.2 Работа с файлами/буферами

- `F2` — переименовать файл/папку (контекстно).
- `Ctrl+N` — создать файл (или в NERDTree создать файл/папку).
- `Ctrl+D` — удалить строку (или файл/папку в NERDTree).
- `\x` — закрыть текущий буфер.
- `\bd` — закрыть текущий буфер.
- `\bo` — закрыть все буферы кроме текущего.
- `\bl` — показать список буферов.
- `Ctrl+O`, `Ctrl+E`, `Ctrl+P`, `Alt+O` — варианты открытия файлов.

## 4.3 Поиск/редактирование

- `Ctrl+F` — поиск.
- `Ctrl+H` — убрать подсветку поиска.
- `Ctrl+A` — выделить все.
- `Ctrl+K` — удалить строку.
- `\c` — комментировать/раскомментировать.

## 4.4 Quickfix / диагностика

- `Ctrl+W` — открыть quickfix-монитор.
- `Ctrl+Q` — закрыть quickfix.
- `\qn` / `\qp` — next/prev ошибка.
- `\qf` / `\ql` — first/last ошибка.

## 4.5 CMake

- `F6` — генерация CMake.
- `F7` — сборка проекта.
- `F8` — выбор таргета.
- `F9` — запуск выбранного таргета.
- `F10` — Debug/Release.
- `F12` — создать/открыть `CMakeLists.txt` в NERDTree.
- `\ru` — generate + build + run.
- `\bt` — показать текущий build type.

## 4.6 Git/GitHub

- `\gs` — `Git status`.
- `\gc` — `Git commit`.
- `\gp` — `Git push`.
- `\gl` — `Git pull`.
- `\go` — открыть на GitHub.

## 4.7 Темы и шрифты

- `\th` — интерактивный выбор темы.
- `\ff` — интерактивный выбор GUI-шрифта.

---

## 5. Темы

### 5.1 Выбор темы

Команда `\th` открывает список:

1. `[preset]` — локальные пресеты из `vimconfigs/colors/*.vim`,
2. `[scheme]` — все доступные темы из runtimepath.

Сортировка:

- сначала `[preset]`, потом `[scheme]`,
- внутри каждой группы — по алфавиту.

### 5.2 Запоминание выбранной темы

После выбора тема сохраняется в `vimconfigs/theme_state.vim` и автоматически восстанавливается при следующем запуске Vim.

---

## 6. Шрифты

`\ff` работает в GUI Vim (MacVim/gVim), где поддерживается `guifont`.

Важно:

- В терминальном Vim шрифт задаётся терминалом (iTerm2/kitty/Terminal.app), а не Vim.

---

## 7. CMake и стабильность F6/F7

В `functions/cmake.vim` реализован устойчивый поток:

1. `F6` генерирует проект и запоминает последний CMake-контекст.
2. `F7` использует текущий/последний контекст.
3. Если папка сборки отсутствует, `F7` автоматически запускает генерацию и продолжает сборку.

Это уменьшает ситуацию “Сначала запусти F6” при запуске сборки из разных окон/контекстов.

---

## 8. LSP/диагностика

Используется `coc.nvim` + набор расширений:

- `coc-clangd`
- `coc-cmake`
- `coc-json`
- `coc-tsserver`
- `coc-html`
- `coc-css`
- `coc-yaml`
- `coc-pyright`
- `coc-omnisharp`
- `coc-rust-analyzer`
- `coc-sh`

Дополнительно:

- quickfix работает как постоянный монитор ошибок,
- обновление `compile_commands.json` отслеживается автоматически.

---

## 9. NERDTree и окна

- NERDTree стартует автоматически (при открытии без аргументов),
- поддерживаются операции создания/удаления/переименования,
- quickfix открывается в рабочей области, не ломая навигацию по дереву.

---

## 10. Обновление конфигурации из репозитория

После `git pull` в репозитории:

```bash
cd vimconfig
./installvimconfig.sh
```

Или ручной вариант:

```bash
cp -R vimconfigs/* ~/.vim/vimconfigs/
cp .vimrc ~/.vimrc
```

---

## 11. Диагностика проблем

Если что-то не работает:

1. `:messages` — последние ошибки Vim.
2. `:scriptnames` — проверить загрузку нужных файлов.
3. `:CocInfo` — состояние CoC/LSP.
4. `:PlugStatus` — статус плагинов.
5. `\h` — встроенная справка по хоткеям этого конфига.

---

## 12. Примечания

- Конфигурация рассчитана на ежедневную работу с C/C++/CMake.
- Поддержка части функций зависит от внешних инструментов (`cmake`, `ninja`, `clangd`, `node`, `python`, и т.д.).

