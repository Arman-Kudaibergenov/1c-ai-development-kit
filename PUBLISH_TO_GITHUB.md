# Публикация на GitHub

Этот документ описывает шаги для публикации проекта на GitHub после тестирования в локальном Gitea.

## Подготовка

### 1. Проверка приватных данных

Запустите проверку:

```bash
# Проверка IP-адресов (кроме localhost)
grep -r "192\.168\." .cursor/ docs/ README.md

# Проверка путей пользователя
grep -r "C:\\Users\\Arman" .cursor/ docs/ README.md
grep -r "/home/YOUR_USERNAME" .cursor/ docs/ README.md

# Проверка проектных MCP
grep -r "kaf-" .cursor/ docs/ README.md
grep -r "mcparqa24" .cursor/ docs/ README.md
grep -r "rarus" .cursor/ docs/ README.md
```

Все должно быть заменено на `YOUR_SERVER`, `YOUR_USERNAME`, `PROJECT-*`.

### 2. Обновление ссылок

Замените в файлах:

- `gitea.yourdomain.com` → `github.com/Jefest9988`
- Добавьте реальные контакты (Telegram, Email)
- Добавьте ссылку на платные MCP (если есть)

### 3. Создание GitHub репозитория

1. Зайдите на https://github.com
2. Нажмите "New repository"
3. Название: `1c-ai-development-kit`
4. Описание: "Comprehensive AI-powered development toolkit for 1C:Enterprise platform"
5. Public repository
6. НЕ создавайте README (он уже есть)

### 4. Добавление remote

```bash
cd C:\Users\YOUR_USERNAME\workspace\1c-ai-development-kit

# Добавьте GitHub remote
git remote add github https://github.com/Jefest9988/1c-ai-development-kit.git

# Проверьте
git remote -v
```

### 5. Push на GitHub

```bash
# Push main ветки
git push github main

# Push тегов (если есть)
git push github --tags
```

## После публикации

### 1. Настройка GitHub

- Добавьте Topics: `1c`, `cursor`, `ai`, `development-kit`, `bsl`
- Настройте GitHub Pages (если нужна документация)
- Добавьте описание и ссылку на сайт

### 2. Создание Release

```bash
# Создайте тег
git tag -a v1.0.0 -m "Initial public release"
git push github v1.0.0

# На GitHub создайте Release из тега
```

### 3. Обновление README

Добавьте бейджи:

```markdown
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub release](https://img.shields.io/github/release/Jefest9988/1c-ai-development-kit.svg)](https://github.com/Jefest9988/1c-ai-development-kit/releases)
[![GitHub stars](https://img.shields.io/github/stars/Jefest9988/1c-ai-development-kit.svg)](https://github.com/Jefest9988/1c-ai-development-kit/stargazers)
```

### 4. Создание документации (GitHub Pages)

```bash
# Создайте ветку gh-pages
git checkout --orphan gh-pages
git rm -rf .

# Скопируйте документацию
cp -r docs/* .
echo "# 1C AI Development Kit Documentation" > index.md

# Настройте Jekyll (опционально)
echo "theme: jekyll-theme-cayman" > _config.yml

# Commit и push
git add .
git commit -m "docs: initial documentation"
git push github gh-pages

# Вернитесь на main
git checkout main
```

## Синхронизация с основным проектом

### Автоматическая синхронизация

Создайте скрипт `sync-public.ps1` в основном проекте:

```powershell
# sync-public.ps1
# Синхронизация изменений с публичным репозиторием

$sourceDir = "C:\Users\YOUR_USERNAME\workspace\1c-AI-workspace"
$publicDir = "C:\Users\YOUR_USERNAME\workspace\1c-ai-development-kit"

# Копируем агентов
Copy-Item "$sourceDir\.cursor\agents\*.md" -Destination "$publicDir\.cursor\agents\" -Force

# Копируем правила
Copy-Item "$sourceDir\.cursor\rules\*.mdc" -Destination "$publicDir\.cursor\rules\" -Force

# Копируем навыки
Copy-Item "$sourceDir\.cursor\skills\*" -Destination "$publicDir\.cursor\skills\" -Recurse -Force -Exclude "*.json"

# Копируем команды
Copy-Item "$sourceDir\.cursor\commands\*.md" -Destination "$publicDir\.cursor\commands\" -Force

# Очищаем приватные данные
cd $publicDir
powershell -ExecutionPolicy Bypass -File "scripts\sanitize-files.ps1"

# Коммитим изменения
git add .
git commit -m "sync: update from main project"

Write-Host "Синхронизация завершена. Проверьте изменения и выполните: git push"
```

### Ручная синхронизация

```bash
# В основном проекте
cd C:\Users\YOUR_USERNAME\workspace\1c-AI-workspace

# Запустите синхронизацию
powershell -ExecutionPolicy Bypass -File sync-public.ps1

# В публичном проекте
cd C:\Users\YOUR_USERNAME\workspace\1c-ai-development-kit

# Проверьте изменения
git status
git diff

# Если все ок, push
git push github main
```

## Обслуживание

### Обновление документации

```bash
cd C:\Users\YOUR_USERNAME\workspace\1c-ai-development-kit

# Редактируйте файлы в docs/
# ...

# Коммит
git add docs/
git commit -m "docs: update installation guide"
git push github main
```

### Создание новых релизов

```bash
# Обновите версию в README.md и других файлах
# ...

# Создайте тег
git tag -a v1.1.0 -m "Release v1.1.0: Added new features"
git push github v1.1.0

# Создайте Release на GitHub с changelog
```

### Ответы на Issues

1. Проверяйте Issues регулярно
2. Отвечайте в течение 48 часов
3. Закрывайте решенные Issues
4. Добавляйте метки (bug, enhancement, documentation)

## Чеклист перед публикацией

- [ ] Проверены все файлы на приватные данные
- [ ] Обновлены ссылки (gitea → github)
- [ ] Добавлены реальные контакты
- [ ] Проверена документация (нет битых ссылок)
- [ ] Создан GitHub репозиторий
- [ ] Добавлен remote
- [ ] Выполнен push
- [ ] Настроены Topics на GitHub
- [ ] Создан первый Release
- [ ] Добавлены бейджи в README
- [ ] Настроен GitHub Pages (опционально)
- [ ] Создан скрипт синхронизации

## Контакты

После публикации обновите контакты в:
- README.md
- CONTRIBUTING.md
- docs/FAQ.md

Добавьте:
- Telegram канал/группу
- Email для связи
- Сайт (если есть)
- Discord/Slack (если есть)
