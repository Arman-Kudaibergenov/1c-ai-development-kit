---
name: subsystem-expert
description: >
  Этот скилл MUST быть вызван для всех операций с подсистемами и командным интерфейсом 1С:
  создание подсистемы (compile), редактирование состава (edit),
  настройка командного интерфейса (interface-edit).
  SHOULD также вызывать при организации объектов конфигурации в логические группы.
  Do NOT использовать для анализа подсистемы — используй inspect; для валидации — validate.
argument-hint: "<mode> [args...]  # modes: compile|edit|interface-edit"
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
---

# /subsystem-expert — Подсистемы и командный интерфейс 1С

Единый скилл для всех операций с подсистемами. Выбери нужный режим:

| Режим | Что делает |
|-------|-----------|
| `compile` | Создать новую подсистему из JSON |
| `edit` | Добавить/удалить объекты из подсистемы, управлять свойствами |
| `interface-edit` | Настроить CommandInterface.xml (видимость, порядок, группы) |

---

## Режим: compile — создание подсистемы

Принимает JSON-определение подсистемы → генерирует XML + файловую структуру + регистрирует в родителе.

### Usage

```
/subsystem-expert compile [-DefinitionFile <json> | -Value <json-string>] -OutputDir <ConfigDir> [-Parent <path>]
```

| Параметр | Описание |
|----------|----------|
| `DefinitionFile` | Путь к JSON-файлу определения |
| `Value` | Инлайн JSON-строка (альтернатива DefinitionFile) |
| `OutputDir` | Корень выгрузки (где `Subsystems/`, `Configuration.xml`) |
| `Parent` | Путь к XML родительской подсистемы (для вложенных) |
| `NoValidate` | Пропустить авто-валидацию |

### Команда

```powershell
powershell.exe -NoProfile -File .claude/skills/subsystem-expert/scripts/subsystem-compile.ps1 -Value '<json>' -OutputDir '<ConfigDir>'
```

---

## Режим: edit — редактирование подсистемы

Точечное редактирование XML подсистемы: состав, дочерние подсистемы, свойства.

### Usage

```
/subsystem-expert edit -SubsystemPath <path> -Operation <op> -Value <value>
```

| Параметр | Описание |
|----------|----------|
| `SubsystemPath` | Путь к XML-файлу подсистемы |
| `DefinitionFile` | JSON-файл с массивом операций |
| `Operation` | Одна операция (альтернатива DefinitionFile) |
| `Value` | Значение для операции |
| `NoValidate` | Пропустить авто-валидацию |

### Поддерживаемые операции

| Operation | Value | Описание |
|-----------|-------|----------|
| `add-content` | `Catalog.ИмяСправочника` | Добавить объект в состав |
| `remove-content` | `Catalog.ИмяСправочника` | Убрать объект из состава |
| `add-subsystem` | имя подсистемы | Добавить дочернюю подсистему |
| `remove-subsystem` | имя подсистемы | Убрать дочернюю подсистему |
| `set-property` | `<prop>=<val>` | Изменить свойство |

### Команда

```powershell
powershell.exe -NoProfile -File .claude/skills/subsystem-expert/scripts/subsystem-edit.ps1 -SubsystemPath '<path>' -Operation add-content -Value 'Catalog.Товары'
```

---

## Режим: interface-edit — командный интерфейс

Редактирует `CommandInterface.xml` подсистемы: видимость, размещение, порядок команд.

### Usage

```
/subsystem-expert interface-edit <CIPath> <Operation> <Value>
```

| Параметр | Описание |
|----------|----------|
| `CIPath` | Путь к CommandInterface.xml |
| `Operation` | hide / show / place / order / subsystem-order / group-order |
| `Value` | Имя команды или объекта |

### Поддерживаемые операции

| Operation | Описание |
|-----------|----------|
| `hide` | Скрыть команду |
| `show` | Показать команду |
| `place` | Разместить в группе |
| `order` | Установить порядок команды |
| `subsystem-order` | Порядок подсистемы |
| `group-order` | Порядок группы |

Подробнее: `.claude/skills/subsystem-expert/reference.md`

### Команда

```powershell
powershell.exe -NoProfile -File .claude/skills/subsystem-expert/scripts/interface-edit.ps1 -CIPath '<path>' -Operation hide -Value '<cmd>'
```
