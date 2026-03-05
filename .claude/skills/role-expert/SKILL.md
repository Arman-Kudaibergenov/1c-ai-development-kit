---
name: role-expert
description: >
  Этот скилл MUST быть вызван когда нужно создать новую роль 1С с набором прав на объекты.
  SHOULD также вызывать при настройке разграничения доступа для новой функциональности.
  Do NOT использовать для анализа роли — используй inspect; для валидации — validate;
  для изменения существующей роли — meta-edit.
argument-hint: "<JsonPath> <RolesDir>"
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
---

# /role-expert — Создание роли 1С из JSON DSL

Принимает JSON-определение роли → генерирует `Roles/Имя.xml` (метаданные) и `Roles/Имя/Ext/Rights.xml` (права). UUID автоматически.

## Usage

```
/role-expert <JsonPath> <RolesDir>
```

| Параметр | Описание |
|----------|----------|
| `JsonPath` | Путь к JSON-определению роли |
| `RolesDir` | Каталог `Roles/` в исходниках конфигурации |

## Команда

```powershell
powershell.exe -NoProfile -File .claude/skills/role-expert/scripts/role-compile.ps1 -JsonPath "<json>" -OutputDir "<RolesDir>"
```

`<Role>ИмяРоли</Role>` автоматически добавляется в `<ChildObjects>` файла `Configuration.xml` (ожидается в parent от `RolesDir`).

## DSL-формат

Описание JSON DSL для определения роли: `.claude/skills/role-expert/dsl-reference.md`

## Смежные операции

| Задача | Скилл |
|--------|-------|
| Анализ прав роли | `/inspect` (режим role-info) |
| Валидация роли | `/validate` (режим role) |
| Изменение свойств объекта | `/meta-edit` |
