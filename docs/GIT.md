# Git tooling

Этот репозиторий хранит переносимую, обезличенную конфигурацию Git и набор
терминальных инструментов для повседневной работы с репозиториями.

## Файлы

Версионируемый конфиг:

```text
dotfiles/.gitconfig
```

После установки он находится в:

```text
~/.gitconfig
```

Персональные и машинно-зависимые значения хранятся отдельно:

```text
~/.gitconfig.local
```

`~/.gitconfig.local` **не хранится в GitHub** и не входит в dotfiles
репозитория.

В нём должны находиться, например:

- `user.name`;
- `user.email`;
- credential helpers;
- signing key;
- другие локальные переопределения.

Основной `~/.gitconfig` подключает этот файл последним, поэтому явные
локальные переопределения имеют приоритет.

## Миграция существующего ~/.gitconfig

При первом запуске `./install.sh`, если уже существует пользовательский
`~/.gitconfig`, а `~/.gitconfig.local` ещё нет, установщик переносит в
local-файл только персональные настройки:

```text
user.*
credential.*
```

Сам исходный `~/.gitconfig` также попадает в обычный timestamped backup
Fog & Ember перед заменой.

Общие настройки не копируются в local-файл: их source of truth — версия
`dotfiles/.gitconfig` в этом репозитории.

## Настройка новой машины

Задайте identity локально:

```bash
git config --file "$HOME/.gitconfig.local" user.name "Your Name"
git config --file "$HOME/.gitconfig.local" user.email "you@example.com"
```

GitHub CLI:

```bash
gh auth login
GIT_CONFIG_GLOBAL="$HOME/.gitconfig.local" gh auth setup-git
```

Так credential helper остаётся в локальном файле и в публичный репозиторий
не попадает абсолютный путь к `gh`.

## Инструменты

| Инструмент | Назначение |
| --- | --- |
| `delta` | Основной pager Git и подсветка interactive diff |
| `diffnav` | Интерактивная навигация для `git diff` |
| `tuicr` | TUI для code review локальных изменений, ranges и pull requests |
| `gh` | GitHub CLI, auth, PR/issues/repository workflows |
| OpenSSH | SSH remotes для GitHub |

Полезные примеры `tuicr`:

```bash
tuicr -w
tuicr -r main..HEAD
tuicr pr 125
```

## Общие Git defaults

Публичный конфиг включает:

- `main` как default branch;
- `fetch.prune=true`;
- сортировку веток по последнему commit;
- сортировку тегов по version semantics;
- rewrite `https://github.com/` → `git@github.com:`;
- `nvim` как editor;
- `delta` как основной pager;
- `diffnav` для `git diff`;
- histogram diff;
- moved-line coloring;
- `zdiff3` merge conflict style;
- `rerere` с autoupdate;
- `delta --color-only` для interactive operations.

## Установка fallback-бинарников

На поддерживаемых дистрибутивах установщик сначала использует системный
package manager. Если `delta`, `diffnav` или `tuicr` недоступны после
этого, `scripts/install-git-tools.sh` скачивает официальный latest GitHub
Release в `~/.local/bin`.

Перед установкой archive SHA-256 сверяется с `digest`, опубликованным
GitHub Releases API.
