# VimConfig

Персональный конфиг для Vim с современными настройками, автодополнением, удобной работой с Git/GitHub, CMake, NERDTree и автозавершением скобок. Подходит для macOS и Linux.

---

📂 Структура проекта

vimconfig/
├── .vimrc                  # Главный конфиг Vim
├── installvimconfig.sh     # Скрипт установки конфигурации
├── vimconfigs/             # Все вспомогательные конфиги
│   ├── autocmd.vim         # Автоматические команды
│   ├── functions.vim       # Пользовательские функции
│   ├── mappings.vim        # Настройки сочетаний клавиш
│   ├── options.vim         # Опции Vim
│   └── plugins.vim         # Плагины и их настройки


⸻

⚡ Установка
	1.	Клонируйте репозиторий на ваш компьютер:
<pre>
'''cd ~/Desktop
git clone https://github.com/dmitriiVin/vimconfig.git
'''
</pre>
	2.	Перейдите в папку vimconfig:
<pre>
'''cd vimconfig
</pre>
	3.	Запустите скрипт установки:
<pre>
'''./installvimconfig.sh
'''
</pre>
		4.	После этого .vimrc будет создан/обновлён. Для установки плагинов внутри Vim пропишите команду:
<pre>
'''
:PluginInstall
'''
</pre>
⸻

🛠 Основные возможности

1. Общие опции
	•	Автодополнение скобок: ", ', (, [, {
	•	Поддержка цветовых схем: gruvbox, github
	•	Автосохранение файла — Ctrl + S
	•	“Сохранить как” — Ctrl + Shift + S

2. Буферы и файлы

Сочетание	Действие
Tab / Shift + Tab	Переключение между буферами
Ctrl + Q	Закрыть текущий файл в буфере
Ctrl + N	Создать новый файл
F2	Переименовать текущий файл
Ctrl + O / Ctrl + E	Быстро открыть файл в текущей директории
Ctrl + P	Поиск файла по имени
Leader + bd	Закрыть текущий буфер
Leader + bo	Закрыть все буферы кроме текущего

3. Git / GitHub

Сочетание	Действие
Leader + gs	Git status
Leader + gc	Git commit
Leader + gp	Git push
Leader + gl	Git pull
Leader + go	Открыть текущий файл на GitHub (через vim-rhubarb)

4. CMake

Сочетание	Действие
F6	CMake generate
F7	CMake build
F8	Выбор таргета
F9	Запуск выбранного таргета
Shift + F8	Быстрый запуск
F12	Открыть CMakeLists.txt

5. NERDTree

Сочетание	Действие
F1	Открыть/закрыть NERDTree
F3	Показать текущий файл в NERDTree
F4	Обновить NERDTree
Ctrl + n	Создать файл или папку
Ctrl + d	Удалить файл или папку
Ctrl + B	Переключение между NERDTree и рабочим окном

6. Работа с текстом

Сочетание	Действие
Ctrl + C	Копировать в системный буфер
Ctrl + A	Выделить весь текст
Ctrl + D / Ctrl + K	Удалить строку
Ctrl + Z	Отмена действия
Ctrl + F	Поиск по файлу
Ctrl + H	Убрать подсветку поиска
Ctrl + /	Комментировать/раскомментировать (vim-commentary)

7. Run Code Function
<pre>
'''function! RunCode()
    let filename = expand('%')  " получаем имя файла
    let basename = expand('%:r') " имя без расширения
    
    if empty(filename)
        echo "No file to run"
        return
    endif
    
    if &filetype == 'cpp'
        execute '!clang++ -std=c++17 -O2 -Wall' filename '-o' basename '&& ./' . basename
    elseif &filetype == 'c'
        execute '!clang -std=c99 -O2 -Wall' filename '-o' basename '&& ./' . basename
    elseif &filetype == 'python'
        execute '!python' filename
    elseif &filetype == 'javascript'
        execute '!node' filename
    elseif &filetype == 'pascal'
        execute '!fpc' filename '&& ./' . basename
    else
        echo "Unsupported file type:" &filetype
    endif
endfunction
'''
</pre>

Функция для быстрого запуска кода в зависимости от типа файла:

⸻

🧩 Дополнительно
	•	Автодополнение и удобное завершение команд в командном режиме
	•	Сочетания с <leader> для быстрого доступа к Git/GitHub и другим функциям
	•	Функции CreateNewFile(), RenameFile(), RunCode(), SafeEdit() для удобного управления файлами

⸻

🎨 Цветовые схемы
	•	gruvbox
	•	github (через vim-colors-github)

Если Vim не видит цветовую схему, убедитесь, что плагин установлен и загружен через plugins.vim.

⸻

🚀 Скрипт установки

installvimconfig.sh создаёт папку .vim (если её нет), копирует конфиги и создаёт .vimrc с подключением всех файлов.

⸻

💡 Советы
	•	Используйте <leader> для команд, где функциональные клавиши уже заняты.
	•	Все функции вынесены в functions.vim, легко редактируются.
	•	Настройки клавиш в mappings.vim, их удобно менять под свои привычки.
	•	Опции Vim в options.vim — например, включение number, relativenumber, tabstop, expandtab и т.д.

⸻

Конфигурация рассчитана на работу с macOS и Linux.
