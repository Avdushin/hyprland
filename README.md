#  Hyprland - Fog & Ember

Переносимая и цельная сборка рабочего окружения Hyprland для **Arch Linux, EndeavourOS, Manjaro и Fedora**.

![fetch](./assets/demo/fetch.png)

![Рабочий стол Fog & Ember](assets/demo/fog-and-ember-three-monitors.webp)

![Рабочий стол Fog & Ember](assets/demo/rainy-house-three-monitors.webp)

Репозиторий устанавливает как саму конфигурацию, так и необходимые для неё компоненты рабочего окружения. На чистой системе не требуется заранее устанавливать Hyprland, Waybar, Ghostty, Rofi, Wofi или Thunar.

## Что входит в сборку

* конфигурация Hyprland на Lua;
* универсальное автоматическое определение мониторов с возможностью локального переопределения;
* Waybar;
* Ghostty;
* Rofi и Wofi;
* интеграция с Thunar;
* уведомления Mako;
* Hyprlock и Hypridle;
* создание скриншотов с помощью Grim, Slurp и wl-clipboard;
* история буфера обмена через Cliphist;
* Git/GitHub tooling: обезличенный `.gitconfig`, `delta`, `diffnav`, `tuicr`, `gh` и OpenSSH;
* конфигурация Neovim из `Avdushin/nvchad-rc`, зафиксированная как Git submodule;
* управление PipeWire, виджеты NetworkManager и Bluetooth;
* единая палитра **Fog & Ember**, из которой генерируются цвета GTK, иконок, терминала, лаунчеров и других компонентов;
* резервное копирование, восстановление и диагностика.

Драйверы видеокарты, ядра, микрокод, загрузчики, VPN-профили, браузеры и личные приложения намеренно не устанавливаются и не изменяются.

## Установка

```bash
git clone --recurse-submodules https://github.com/Avdushin/hyprland.git
cd hyprland
./install.sh
```

Установщик:

1. определяет поддерживаемое семейство дистрибутива;
2. устанавливает необходимые пакеты;
3. инициализирует зафиксированный Neovim submodule;
4. сохраняет персональные `user.*` / `credential.*` из существующего `~/.gitconfig` в `~/.gitconfig.local`, если это необходимо;
5. создаёт резервную копию существующих управляемых конфигураций, включая `~/.config/nvim`;
6. полностью заменяет старый `~/.config/nvim` содержимым pinned submodule и устанавливает остальные dotfiles;
7. устанавливает обои и генерирует файлы цветовой темы;
8. включает необходимые службы;
9. запускает диагностику.

После установки выйдите из текущей сессии и выберите **Hyprland** в менеджере входа.

## Предварительный просмотр и частичная установка

Показать действия пакетного менеджера без внесения изменений:

```bash
./install.sh --dry-run
```

Установить только конфигурационные файлы, если зависимости уже были установлены вручную:

```bash
./install.sh --dotfiles-only
```

Пропустить диагностику после установки:

```bash
./install.sh --no-doctor
```

## Поддержка дистрибутивов

* Arch Linux, EndeavourOS и Manjaro используют `pacman`.
* Fedora использует COPR-репозиторий Hyprland, указанный в актуальной документации проекта.
* На других дистрибутивах можно использовать параметр `--dotfiles-only`, однако автоматическая установка через их пакетные менеджеры не заявлена как протестированная или поддерживаемая.

Разработчики Hyprland официально гарантируют полноценную поддержку пакетной установки только для ограниченного числа дистрибутивов. Поэтому логика установки для разных систем в этом проекте разделена, а библиотеки экосистемы Hyprland, собранные вручную, не смешиваются с пакетами дистрибутива.

## Настройка мониторов

Профиль по умолчанию использует предпочтительные режимы мониторов и автоматическое расположение.

Для точной настройки разрешения, частоты обновления, масштаба и расположения создайте локальный профиль:

```bash
cp ~/.config/hypr/monitors/local.lua.example \
   ~/.config/hypr/monitors/local.lua
```

Подробнее: [настройка мониторов](docs/MONITORS.md).

## Обновление

```bash
git pull --ff-only
git submodule update --init --recursive
./install.sh
```

При каждом запуске создаётся новая резервная копия с датой и временем.

Обновление pinned-версии Neovim до актуального `nvchad-rc/main` выполняется отдельно:

```bash
./scripts/update-nvim.sh
git diff --submodule=log -- dotfiles/.config/nvim
git add dotfiles/.config/nvim
git commit -m "chore: update Neovim submodule"
```

Обычный `./install.sh` намеренно не двигает submodule на новый commit автоматически: это сохраняет воспроизводимость конкретного состояния Fog & Ember.

## Документация

* [Горячие клавиши](docs/KEYBINDS.md)
* [Git и terminal tooling](docs/GIT.md)
* [Neovim submodule](docs/NVIM.md)
* [Настройка мониторов](docs/MONITORS.md)
* [Поддержка дистрибутивов](docs/DISTRIBUTIONS.md)
* [Настройка и персонализация](docs/CUSTOMIZATION.md)
* [Решение проблем](docs/TROUBLESHOOTING.md)

## Лицензия

MIT
