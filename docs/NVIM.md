# Neovim

Канонический source of truth для конфигурации Neovim находится в отдельном
репозитории:

```text
https://github.com/Avdushin/nvchad-rc
```

Несмотря на историческое имя, это standalone-конфигурация Neovim, а не
NvChad.

В `Avdushin/hyprland` она подключена как Git submodule:

```text
dotfiles/.config/nvim
```

Superproject хранит конкретный commit `nvchad-rc`. Поэтому каждый commit
Fog & Ember воспроизводимо связан с конкретной версией Neovim-конфига, но
сам конфиг поддерживается только в одном месте.

## Установка вместе с Fog & Ember

Рекомендуемое клонирование:

```bash
git clone --recurse-submodules https://github.com/Avdushin/hyprland.git
cd hyprland
./install.sh
```

Если репозиторий был клонирован без `--recurse-submodules`, это не проблема:
`install.sh` сам выполняет инициализацию pinned submodule.

Перед установкой `~/.config/nvim` входит в общий backup. После успешного
backup существующий каталог удаляется целиком и заменяется содержимым
зафиксированного submodule. Это предотвращает смешивание старых NvChad-файлов
с текущей standalone-конфигурацией.

Git metadata submodule в HOME не копируется: общий rsync исключает `.git`.

Ожидаемый результат:

```text
~/.config/nvim/
├── init.lua
├── lazy-lock.json
├── colors/
└── lua/
```

Запуск:

```bash
nvim
```

Legacy launcher `~/.local/bin/nvchad` не используется и не устанавливается.

## Обновление pinned-версии

Обычный installer использует commit, зафиксированный superproject, и **не**
делает `git submodule update --remote`. Это намеренно: старый commit
`hyprland` не должен неожиданно начать устанавливать другой Neovim-конфиг.

Чтобы передвинуть pointer на текущий `nvchad-rc/main`:

```bash
./scripts/update-nvim.sh
```

После этого проверь изменение:

```bash
git diff --submodule=log -- dotfiles/.config/nvim
```

и зафиксируй новый pointer обычным commit в `hyprland`:

```bash
git add dotfiles/.config/nvim
git commit -m "chore: update Neovim submodule"
```

Изменения самого Neovim-конфига делаются и коммитятся только в
`Avdushin/nvchad-rc`, а не внутри истории `hyprland`.

## Самостоятельная установка Neovim

Для сервера, macOS или машины без Fog & Ember используется самостоятельный
installer канонического репозитория:

```bash
curl -fsSL https://raw.githubusercontent.com/Avdushin/nvchad-rc/main/install.sh | bash
```

Он отвечает за standalone bootstrap Neovim и его runtime-зависимостей.
Fog & Ember хранит и разворачивает pinned конфигурацию, но не дублирует
эту bootstrap-логику.
