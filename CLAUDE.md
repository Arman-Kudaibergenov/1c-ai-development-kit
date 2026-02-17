# 1C AI Workspace — Claude Code Configuration

## О проекте

Портативная AI-конфигурация для разработки на 1С:Предприятие 8.3. Содержит 66 skills, документацию по XML форматам, JSON DSL спецификации, интеграцию с MCP серверами.

## Структура

```
.claude/skills/    — 66 skills для Claude Code (SKILL.md + скрипты)
.claude/docs/      — 29 спецификаций и гайдов по форматам 1С
.cursor/           — Cursor IDE конфигурация (agents, rules, skills)
openspec/          — Specification-Driven Development
```

## Skills (ключевые команды)

### Объекты метаданных
- `/meta-compile`, `/meta-edit`, `/meta-info`, `/meta-remove`, `/meta-validate` — CRUD для 23 типов объектов

### Формы
- `/form-compile`, `/form-edit`, `/form-add`, `/form-info`, `/form-validate`, `/form-patterns`

### Обработки и отчёты
- `/epf-init`, `/epf-build`, `/epf-dump`, `/epf-validate`, `/epf-add-form`
- `/erf-init`, `/erf-build`, `/erf-dump`, `/erf-validate`

### БСП интеграция
- `/epf-bsp-init` — регистрация в БСП
- `/epf-bsp-add-command` — добавление команды
- `/bsp-patterns` — паттерны работы с подсистемами

### СКД (отчёты)
- `/skd-compile`, `/skd-edit`, `/skd-info`, `/skd-validate`

### Макеты (печатные формы)
- `/mxl-compile`, `/mxl-decompile`, `/mxl-info`, `/mxl-validate`

### Роли и права
- `/role-compile`, `/role-info`, `/role-validate`

### Конфигурация и расширения
- `/cf-init`, `/cf-edit`, `/cf-info`, `/cf-validate`
- `/cfe-init`, `/cfe-borrow`, `/cfe-patch-method`, `/cfe-validate`, `/cfe-diff`

### Подсистемы
- `/subsystem-compile`, `/subsystem-edit`, `/subsystem-info`, `/subsystem-validate`
- `/interface-edit`, `/interface-validate`

### База данных
- `/db-create`, `/db-list`, `/db-dump-cf`, `/db-load-cf`
- `/db-dump-xml`, `/db-load-xml`, `/db-update`, `/db-run`
- `/db-load-git` — умная загрузка изменений из Git

### Workflow
- `/1c-feature-dev` — полный 9-фазный цикл разработки
- `/1c-help-mcp` — поиск по документации платформы
- `/1c-query-opt` — оптимизация запросов

## Правила разработки

### 1С кодирование
- Следовать стандартам БСП и ITS
- Кириллица для кода 1С (BSL), латиница для инфраструктуры
- Табы для отступов в BSL коде
- UTF-8 BOM для PowerShell скриптов с кириллицей

### SDD Workflow
- Для сложных доработок используй `/1c-feature-dev`
- Спецификация ДО кода (openspec/changes/)
- Ревью плана ДО реализации
- Атомарные этапы с критериями приёмки

### Git безопасность
- НИКОГДА force push на main/master
- НЕ коммитить .env, credentials, ключи
- НЕ пропускать hooks без явного запроса
- Предупреждать перед деструктивными операциями

### Выбор модели
- Sonnet для 90%+ задач (генерация, ревью, вопросы)
- Opus только для критических: архитектура, безопасность, production баги

### Контекст
- RLM-first: проверяй RLM перед чтением файлов
- Сохраняй решения в RLM после завершения задач
- Task agents для параллельных задач (изоляция контекста)

## MCP серверы

Доступные MCP серверы определены в `.mcp.json`:

**Общие (для всех проектов):**
- `rlm-toolkit` (CT XXX, YOUR_RLM_SERVER:8200) — персистентная память между сессиями

**Проектные (разворачиваются под каждый проект на CT XXX, YOUR_MCP_SERVER):**
- `PROJECT-codemetadata` — документация платформы 1С (`helpsearch`). Каждый проект — свой контейнер на своём порту. Текущий: порт 7530

**Локальные:**
- `playwright` — управление браузером (веб-клиент 1С, отладка форм, тестирование)

### Правила поиска: Grep vs MCP
- **Поиск по коду проекта** → Grep (быстрее, точнее, без зависимостей)
- **Поиск по метаданным** → Grep/Glob по XML-файлам
- **Документация платформы 1С** (синтаксис, API, методы) → `helpsearch`
- НЕ используй `codesearch`/`metadatasearch` — Grep справляется лучше

## OpenSpec

Методология Specification-Driven Development:
- `openspec/project.md` — контекст и соглашения проекта
- `openspec/changes/` — активные предложения изменений
- `openspec/specs/` — текущие спецификации возможностей

Skills: `/openspec-proposal`, `/openspec-apply`, `/openspec-archive`

## Инфраструктура

- Proxmox host: YOUR_PROXMOX_HOST
- CT XXX (RLM): YOUR_RLM_HOST
- CT XXX (Ollama): YOUR_OLLAMA_SERVER, RLM-toolkit: YOUR_RLM_SERVER:8200
- CT XXX (Projects MCP): YOUR_MCP_SERVER
- MinimKG Enhanced: CT XXX, YOUR_MCP_SERVER:7530
- Серверы 1С: на ноутбуке (8.3.24 порт 1641, 8.3.25 порт 1541, 8.3.27 порт 1741)
