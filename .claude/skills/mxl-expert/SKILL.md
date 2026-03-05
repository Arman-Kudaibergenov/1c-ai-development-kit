---
name: mxl-expert
description: >
  Этот скилл MUST быть вызван для всех операций с MXL-макетами и шаблонами объектов 1С:
  создание MXL из JSON (compile), получение JSON из MXL (decompile),
  добавление макета к объекту (template-add), удаление макета (template-remove).
  SHOULD также вызывать при любой работе с печатными формами и макетами.
  Do NOT использовать для анализа MXL — используй inspect; для валидации — используй validate.
argument-hint: "<mode> [args...]  # modes: compile|decompile|template-add|template-remove"
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
---

# /mxl-expert — MXL-макеты и шаблоны 1С

Единый скилл для всех операций с MXL-макетами и шаблонами. Выбери нужный режим:

| Режим | Что делает |
|-------|-----------|
| `compile` | Создать MXL из JSON DSL-определения |
| `decompile` | Получить JSON DSL из существующего MXL |
| `template-add` | Добавить макет к объекту (обработка, справочник, документ) |
| `template-remove` | Удалить макет из объекта |

---

## Режим: compile — создание MXL из JSON

Принимает компактное JSON-определение макета и генерирует корректный Template.xml для табличного документа 1С.

### Usage

```
/mxl-expert compile <JsonPath> <OutputPath>
```

| Параметр   | Обязательный | Описание |
|------------|:------------:|----------|
| JsonPath   | да           | Путь к JSON-определению макета |
| OutputPath | да           | Путь для генерации Template.xml |

### Команда

```powershell
powershell.exe -NoProfile -File .claude/skills/mxl-expert/scripts/mxl-compile.ps1 -JsonPath "<JsonPath>" -OutputPath "<OutputPath>"
```

Claude описывает *что* нужно (области, параметры, стили), скрипт обеспечивает *корректность* XML (палитры, индексы, объединения, namespace).

---

## Режим: decompile — получение JSON из MXL

Принимает Template.xml и генерирует компактное JSON DSL-определение. Обратная операция к `compile`.

### Usage

```
/mxl-expert decompile <TemplatePath> [OutputPath]
```

| Параметр     | Обязательный | Описание |
|--------------|:------------:|----------|
| TemplatePath | да           | Путь к Template.xml |
| OutputPath   | нет          | Путь для JSON (если не указан — stdout) |

### Команда

```powershell
powershell.exe -NoProfile -File .claude/skills/mxl-expert/scripts/mxl-decompile.ps1 -TemplatePath "<TemplatePath>" [-OutputPath "<OutputPath>"]
```

---

## Режим: template-add — добавление макета к объекту

Создаёт макет указанного типа и регистрирует его в корневом XML объекта.

### Usage

```
/mxl-expert template-add <ObjectName> <TemplateName> <TemplateType> [Synonym] [SrcDir]
```

| Параметр      | Обязательный | По умолчанию   | Описание |
|---------------|:------------:|----------------|----------|
| ObjectName    | да           | —              | Имя объекта |
| TemplateName  | да           | —              | Имя макета |
| TemplateType  | да           | —              | Тип: HTML, Text, SpreadsheetDocument, BinaryData, DataCompositionSchema |
| Synonym       | нет          | = TemplateName | Синоним макета |
| SrcDir        | нет          | `src`          | Каталог исходников |
| --SetMainSKD  | нет          | —              | Установить MainDataCompositionSchema |

### Команда

```powershell
powershell.exe -NoProfile -File .claude/skills/mxl-expert/scripts/add-template.ps1 -ObjectName "<ObjectName>" -TemplateName "<TemplateName>" -TemplateType "<TemplateType>" [-Synonym "<Synonym>"] [-SrcDir "<SrcDir>"] [-SetMainSKD]
```

### Маппинг типов

| Пользователь пишет | TemplateType | Расширение | Содержимое |
|--------------------|--------------|------------|-----------|
| HTML | HTMLDocument | `.html` | Пустой HTML |
| Text, текст | TextDocument | `.txt` | Пустой файл |
| SpreadsheetDocument, MXL, табличный документ | SpreadsheetDocument | `.xml` | Минимальный spreadsheet |
| BinaryData, бинарные данные | BinaryData | `.bin` | Пустой файл |
| DataCompositionSchema, СКД | DataCompositionSchema | `.xml` | Пустая СКД |

---

## Режим: template-remove — удаление макета

Удаляет макет и убирает его регистрацию из корневого XML объекта.

### Usage

```
/mxl-expert template-remove <ObjectName> <TemplateName> [SrcDir]
```

| Параметр     | Обязательный | По умолчанию | Описание |
|--------------|:------------:|--------------|----------|
| ObjectName   | да           | —            | Имя объекта |
| TemplateName | да           | —            | Имя макета для удаления |
| SrcDir       | нет          | `src`        | Каталог исходников |

### Команда

```powershell
powershell.exe -NoProfile -File .claude/skills/mxl-expert/scripts/remove-template.ps1 -ObjectName "<ObjectName>" -TemplateName "<TemplateName>" [-SrcDir "<SrcDir>"]
```

**Операция необратима.** Скрипт:
1. Удаляет XML файл макета и каталог с содержимым
2. Убирает `<Template>` из `ChildObjects` корневого XML объекта
