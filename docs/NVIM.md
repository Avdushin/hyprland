# Neovim

Конфигурация Neovim больше не хранится и не устанавливается из этого
репозитория.

Актуальный source of truth:

```text
https://github.com/Avdushin/nvchad-rc
```

Несмотря на историческое имя репозитория, это standalone-конфигурация
Neovim, а не NvChad.

## Установка

```bash
curl -fsSL https://raw.githubusercontent.com/Avdushin/nvchad-rc/main/install.sh | bash
```

Installer устанавливает конфигурацию в стандартный профиль:

```text
~/.config/nvim
```

и перед заменой сохраняет существующий Neovim profile в backup.

Запуск:

```bash
nvim
```

Репозиторий `Avdushin/hyprland` намеренно **не управляет**
`~/.config/nvim` и не устанавливает legacy launcher
`~/.local/bin/nvchad`.
