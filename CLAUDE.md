# 1C AI Workspace — Claude Code Configuration

## О проекте

Портативная AI-конфигурация для разработки на 1С:Предприятие 8.3. Содержит 74 skills, документацию по XML форматам, JSON DSL спецификации, интеграцию с MCP серверами.

## Структура

```
.claude/skills/    — 74 skills для Claude Code (SKILL.md + скрипты)
.claude/docs/      — спецификации и гайды по форматам 1С
openspec/          — Specification-Driven Development
scripts/           — инфраструктурные скрипты (не hooks)
```

## MANDATORY: MCP-First Rule

**These rules apply to initialized 1C projects (where MCP tools are connected via `/1c-project-init`).**
**This workspace itself has only `rlm-toolkit` (global) and `playwright` (local).**

### When to use which MCP tool (in 1C projects)

| Situation | Tool | Action |
|-----------|------|--------|
| Need 1C platform syntax / method docs | `1c-help` | Call `helpsearch` BEFORE writing code |
| Working with BSP subsystems | `1c-ssl` | Call `ssl_search` to find correct BSP patterns |
| Need a code template / pattern | `1c-templates` | Call `template_search` BEFORE writing from scratch |
| Wrote BSL code | `1c-syntax-checker` | Call `check_syntax` ALWAYS after writing BSL |
| Complex logic / architecture review | `1c-code-checker` | Call to verify logic via 1C Companion |
| Working with managed forms XML | `1c-forms` | Call `get_form_schema` for structure reference |
| Need to remember project context | `rlm-toolkit` | Call `rlm_route_context` at session start |
| Work with 1C in browser (forms, data, testing) | `playwright` | Use `/1c-web-session` skill |

### Non-negotiable rules (in 1C projects)

- **NEVER** write 1C code without first checking `1c-help` for syntax
- **NEVER** use a BSP subsystem without checking `1c-ssl` for correct pattern
- **NEVER** skip `1c-syntax-checker` after writing BSL code
- **NEVER** guess a code template — search `1c-templates` first
- If MCP server is unavailable — say so explicitly, don't silently fall back

### MCP vs Grep decision (in 1C projects)

| Task | Use |
|------|-----|
| Search project source code | Grep/Glob |
| Search 1C metadata XML | Grep/Glob |
| 1C platform docs / syntax | `1c-help` |
| BSP patterns | `1c-ssl` |
| Code templates | `1c-templates` |

---

## MANDATORY: Skills-First Rule

**BEFORE writing any script, code, or solution — check if a skill exists.**

Workflow:
1. User asks for something → scan skill list below
2. Skill exists → use `Skill` tool immediately, do NOT reinvent
3. No skill → only then write custom code

This applies to ALL 1C operations: creating bases, loading configs, compiling objects, working with forms, BSP, SKD, roles, etc. **Never generate your own PowerShell/BAT scripts for operations that skills cover.**

## MANDATORY: Autonomy After Approval

**One approval point per task. After user says "ok" — execute autonomously.**

- Ask clarifying questions BEFORE showing the plan
- Show design+plan → get ONE approval
- After "ok": do NOT ask "can I proceed with step N?", "is this part ok?", "should I continue?"
- Only stop for blockers (impossible to continue, contradictory requirements)
- Report results at the end

## Task Routing (automatic)

AI determines the mode based on task complexity:

| Complexity | Mode | What to do |
|-----------|------|-----------|
| 1-2 objects, obvious | **direct** | Use skills directly, no ceremony |
| 3-5 tasks, needs design | **standard** | `/brainstorm` → brief plan → execute |
| 6+ tasks, architectural | **full** | `/brainstorm` → `/write-plan` → `/subagent-dev` |
| 6+ files, parallel work needed | **team** | "новая задача" → Agent Teams (Opus leader + Sonnet teammates). See `~/.claude/CLAUDE.md` for protocol |
| Formal spec management | **openspec** | `/openspec-proposal` → `/openspec-apply` |

## Skills (ключевые команды)

### Объекты метаданных
- `/meta-compile`, `/meta-edit`, `/meta-remove`, `/meta-validate` — CRUD для 23 типов объектов
- `/inspect` — анализ структуры объекта (реквизиты, ТЧ, формы, движения, типы)

### Формы
- `/form-compile`, `/form-edit`, `/form-add`, `/form-validate`, `/form-patterns`
- `/inspect` — анализ структуры формы (Form.xml: элементы, реквизиты, команды)
- `/help-add` — встроенная справка к объекту 1С

### Обработки и отчёты
- `/epf-init`, `/epf-build`, `/epf-dump`, `/epf-validate`, `/epf-add-form`
- `/erf-init`, `/erf-build`, `/erf-dump`, `/erf-validate`

### БСП интеграция
- `/epf-bsp-init` — регистрация в БСП
- `/epf-bsp-add-command` — добавление команды
- `/bsp-patterns` — паттерны работы с подсистемами

### СКД (отчёты)
- `/skd-compile`, `/skd-edit`, `/skd-validate`
- `/inspect` — анализ структуры СКД (наборы, поля, параметры, варианты, трассировка)

### Макеты (печатные формы)
- `/mxl-compile`, `/mxl-decompile`, `/mxl-validate`
- `/inspect` — анализ структуры MXL-макета (области, параметры, наборы колонок)
- `/template-add`, `/template-remove` — добавить/удалить макет к объекту конфигурации
- `/img-grid` — наложить сетку на изображение для определения пропорций колонок

### Роли и права
- `/role-compile`, `/role-validate`
- `/inspect` — аудит прав роли (Rights.xml: объекты, действия, RLS, шаблоны)

### Конфигурация и расширения
- `/cf-init`, `/cf-edit`, `/cf-validate`
- `/inspect` — обзор структуры конфигурации (объекты по типам, свойства)
- `/cfe-init`, `/cfe-borrow`, `/cfe-patch-method`, `/cfe-validate`, `/cfe-diff`

### Подсистемы
- `/subsystem-compile`, `/subsystem-edit`, `/subsystem-validate`
- `/inspect` — анализ структуры подсистемы (состав, CI, дерево иерархии)
- `/interface-edit`, `/interface-validate`

### База данных
- `/db-create`, `/db-list`, `/db-dump-cf`, `/db-load-cf`
- `/db-dump-xml`, `/db-load-xml`, `/db-update`, `/db-run`
- `/db-load-git` — умная загрузка изменений из Git

### Веб-клиент (Playwright)
- `/1c-web-session` — управление 1С в браузере: сеансы, навигация, формы, справочники, документы, тестовые данные

### Веб-публикация (Apache)
- `/web-publish` — публикация базы через portable Apache (генерирует default.vrd + httpd.conf, скачивает Apache при необходимости)
- `/web-unpublish` — удаление публикации (одной или всех)
- `/web-info` — статус Apache + список опубликованных баз
- `/web-stop` — остановка Apache (публикации сохраняются)
- `/web-test` — Playwright-автоматизация веб-клиента 1С (Node.js: autonomous/interactive/piped режимы, video recording, dom.mjs)

### Инициализация и тестирование
- `/1c-project-init` — инициализация/обогащение 1С проекта (skills, docs, CLAUDE.md, MCP)
- `/1c-test-runner` — AI-тестирование бизнес-логики через `1c-ai-debug` MCP (без внешних зависимостей)
- `/playwright-test` — scaffold UI-теста после деплоя (package.json + spec.js с JSONL-логом)

### Workflow
- `/brainstorm` — **основной**: обсуждение → план → автономное выполнение (express/standard/full)
- `/write-plan` — отдельно создать tasks.md из design.md (обычно вызывается из brainstorm)
- `/subagent-dev` — отдельно выполнить tasks.md субагентами (обычно вызывается из brainstorm full)
- `/1c-help-mcp` — поиск по документации платформы
- `/1c-query-opt` — оптимизация запросов

### OpenSpec
- `/openspec-proposal` — создать предложение изменения
- `/openspec-apply` — реализовать одобренное изменение
- `/openspec-archive` — архивировать завершённое изменение

## Правила разработки

### 1С кодирование
- Следовать стандартам БСП и ITS
- Кириллица для кода 1С (BSL), латиница для инфраструктуры
- Табы для отступов в BSL коде
- UTF-8 BOM для PowerShell скриптов с кириллицей

### Workflow доработок
- Для любых доработок: `/brainstorm` (сам выберет режим express/standard/full)
- Для формальных спецификаций: `/openspec-proposal` → `/openspec-apply`
- Одно одобрение → автономная реализация → отчёт в конце
- НИКОГДА не спрашивать разрешения после одобрения плана

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

### В этом проекте (1c-AI-workspace)

Это workspace/toolkit — не 1С проект. Подключены только:
- `rlm-toolkit` — глобальный (`~/.claude/mcp.json`), персистентная память
- `playwright` — локальный, управление браузером для тестирования

### При инициализации 1С проекта (`/1c-project-init`)

Шаблон `.mcp.json` (`.claude/skills/1c-project-init/templates/mcp.json.template`) разворачивает:

**Общие 1С (CT103, YOUR_MCP_SERVER):**
- `1c-help` (:8003) — документация платформы (`helpsearch`)
- `1c-ssl` (:8008) — паттерны БСП (`ssl_search`)
- `1c-templates` (:8004) — шаблоны кода (`template_search`)
- `1c-syntax-checker` (:8002) — проверка синтаксиса BSL
- `1c-code-checker` (:8007) — проверка логики через 1С:Напарник
- `1c-forms` (:8011) — схема управляемых форм (`get_form_schema`)

**Глобальные:**
- `rlm-toolkit` (CT105, YOUR_RLM_SERVER:8200) — персистентная память

**Проектные (настраиваются под конкретный проект):**
- `mcp-bsl-lsp` (CT100) — LSP-анализ BSL через Docker-контейнер проекта
- `1c-ai-debug` — MCP-мост к HTTP-сервису 1С (запросы, метаданные, данные)

**Локальные:**
- `playwright` — управление браузером (веб-клиент 1С, тестирование)

## OpenSpec

Методология Specification-Driven Development:
- `openspec/project.md` — контекст и соглашения проекта
- `openspec/changes/` — активные предложения изменений
- `openspec/specs/` — текущие спецификации возможностей

Skills: `/openspec-proposal`, `/openspec-apply`, `/openspec-archive`

## Инфраструктура

См. полную карту в `~/.claude/CLAUDE.md`. Ключевое для этого проекта:
- CT103 (mcp-common): YOUR_MCP_SERVER — 6 общих MCP серверов, разворачиваются в проекты через `/1c-project-init`
- CT105 (rlm): YOUR_RLM_SERVER — RLM-toolkit:8200 (глобальный)
- CT107 (onec-dev): YOUR_EDT_SERVER — Docker: onec-server-24/25/27, onec-postgres, onec-web-24/25


# Agent Instructions (injected by dispatch)

You are a Sonnet AGENT dispatched by Opus. Rules marked 'Opus NEVER/ONLY' do NOT apply to you. You CAN and MUST write code, edit files, run commands, and commit.

DISPATCHED TASK (start immediately, no confirmation needed):
Read and implement SDD at C:/Users/Arman/workspace/Jefest/openspec/specs/skills-cleanup-20260304.md. Do ALL 4 tasks in order. For task 2 (sync), use robocopy to mirror skills from ai-workspace to KAF, MinimKG_new, AKK, ARCA. For task 3, edit ~/.claude/hooks/context-monitor.ps1. For task 4, edit Jefest dispatch-interactive.ps1. Commit each repo separately.

# ⚠️ CRITICAL: Result File is NOT Optional

**FAILURE TO WRITE RESULT FILE = TASK FAILED. There is no exception.**

You MUST write a JSON result file before exiting, regardless of task outcome.

## Result File Specification

**Path:** `C:/Users/Arman/AppData/Local/Temp/jefest-dispatch/result-1c-ai-workspace-20260304-111111.json`

**Format:**
```json
{
  "status": "completed|blocked|context_overflow",
  "project": "1c-ai-workspace",
  "summary": "<what was done in 1-3 sentences>",
  "files": ["<changed/created files>"],
  "remaining": "<what's left if blocked or overflow>"
}
```

**When to write:**
- Task completed ✓
- Task blocked (need clarification, external dependency, etc.)
- Context overflow (too much work, need continuation)

**If blocked or overflow:** commit partial work first, then write result with `remaining` field.

---

# Agent Rules

- Execute the task exactly. No extras, no refactoring, no improvements beyond scope.
- Use project skills (`.claude/skills/`) before manual approaches.
- Follow project CLAUDE.md rules strictly, with this CRITICAL OVERRIDE:
  **YOU ARE NOT OPUS. You are a Sonnet agent.** Any rule that says "Opus NEVER", "Opus ONLY", "HARD RULE — Opus NEVER executes" does NOT apply to you. IGNORE all Opus restrictions completely. You CAN and MUST: create files, edit files, run bash commands, run infrastructure commands (SSH, docker, deploy), commit, and push. If a rule restricts "file creation" or "script implementation" to Sonnet — that means YOU. Do it.
- Subagents: sonnet/haiku only, never opus.

## Git
- Commit your work to the current branch. Do NOT push, do NOT merge. Post-exit handles push automatically.
- NEVER touch main branch.

## Project Rules
# 1C AI Workspace — Claude Code Configuration

## О проекте

Портативная AI-конфигурация для разработки на 1С:Предприятие 8.3. Содержит 74 skills, документацию по XML форматам, JSON DSL спецификации, интеграцию с MCP серверами.

## Структура

```
.claude/skills/    — 74 skills для Claude Code (SKILL.md + скрипты)
.claude/docs/      — спецификации и гайды по форматам 1С
openspec/          — Specification-Driven Development
scripts/           — инфраструктурные скрипты (не hooks)
```

## MANDATORY: MCP-First Rule

**These rules apply to initialized 1C projects (where MCP tools are connected via `/1c-project-init`).**
**This workspace itself has only `rlm-toolkit` (global) and `playwright` (local).**

### When to use which MCP tool (in 1C projects)

| Situ
...(truncated)

## Available Skills


---

### Global Skill: powershell-windows
---
name: powershell-windows
description: >
  This skill MUST be invoked when writing PowerShell scripts on Windows.
  SHOULD also invoke when user says "powershell", "ps1", "Windows automation".
  Do NOT use for bash/shell scripts on Linux.
risk: unknown
source: community
date_added: "2026-02-27"
---

# PowerShell Windows Patterns

> Critical patterns and pitfalls for Windows PowerShell.

---

## 1. Operator Syntax Rules

### CRITICAL: Parentheses Required

| ❌ Wrong | ✅ Correct |
|----------|-----------|
| `if (Test-Path "a" -or Test-Path "b")` | `if ((Test-Path "a") -or (Test-Path "b"))` |
| `if (Get-Item $x -and $y -eq 5)` | `if ((Get-Item $x) -and ($y -eq 5))` |

**Rule:** Each cmdlet call MUST be in parentheses when using logical operators.

---

## 2. Unicode/Emoji Restriction

### CRITICAL: No Unicode in Scripts

| Purpose | Don't Use | Use |
|---------|-----------|-----|
| Success | checkmark emoji | [OK] [+] |
| Error | X emoji | [!] [X] |
| Warning | warning emoji | [*] [WARN] |
| Info | info emoji | [i] [INFO] |
| Progress | hourglass emoji | [...] |

**Rule:** Use ASCII characters only in PowerShell scripts.

---

## 3. Null Check Patterns

### Always Check Before Access

| ❌ Wrong | ✅ Correct |
|----------|-----------|
| `$array.Count -gt 0` | `$array -and $array.Count -gt 0` |
| `$text.Length` | `if ($text) { $text.Length }` |

---

## 4. String Interpolation

### Complex Expressions

| ❌ Wrong | ✅ Correct |
|----------|-----------|
| `"Value: $($obj.prop.sub)"` | Store in variable first |

**Pattern:**
```
$value = $obj.prop.sub
Write-Output "Value: $value"
```

---

## 5. Error Handling

### ErrorActionPreference

| Value | Use |
|-------|-----|
| Stop | Development (fail fast) |
| Continue | Production scripts |
| SilentlyContinue | When errors expected |

### Try/Catch Pattern

- Don't return inside try block
- Use finally for cleanup
- Return after try/catch

---

## 6. File Paths

### Windows Path Rules

| Pattern | Use |
|---------|-----|
| Literal path | `C:\Users\User\file.txt` |
| Variable path | `Join-Path $env:USERPROFILE "file.txt"` |
| Relative | `Join-Path $ScriptDir "data"` |

**Rule:** Use Join-Path for cross-platform safety.

---

## 7. Array Operations

### Correct Patterns

| Operation | Syntax |
|-----------|--------|
| Empty array | `$array = @()` |
| Add item | `$array += $item` |
| ArrayList add | `$list.Add($item) | Out-Null` |

---

## 8. JSON Operations

### CRITICAL: Depth Parameter

| ❌ Wrong | ✅ Correct |
|----------|-----------|
| `ConvertTo-Json` | `ConvertTo-Json -Depth 10` |

**Rule:** Always specify `-Depth` for nested objects.

### File Operations

| Operation | Pattern |
|-----------|---------|
| Read | `Get-Content "file.json" -Raw | ConvertFrom-Json` |
| Write | `$data | ConvertTo-Json -Depth 10 | Out-File "file.json" -Encoding UTF8` |

---

## 9. Common Errors

| Error Message | Cause | Fix |
|---------------|-------|-----|
| "parameter 'or'" | Missing parentheses | Wrap cmdlets in () |
| "Unexpected token" | Unicode character | Use ASCII only |
| "Cannot find property" | Null object | Check null first |
| "Cannot convert" | Type mismatch | Use .ToString() |

---

## 10. Script Template

```powershell
# Strict mode
Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

# Paths
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Main
try {
    # Logic here
    Write-Output "[OK] Done"
    exit 0
}
catch {
    Write-Warning "Error: $_"
    exit 1
}
```

---

> **Remember:** PowerShell has unique syntax rules. Parentheses, ASCII-only, and null checks are non-negotiable.

## When to Use
This skill is applicable to execute the workflow or actions described in the overview.


---

### Global Skill: workflow-automation
---
name: workflow-automation
description: >
  This skill MUST be invoked when building automation scripts, CI/CD pipelines, or orchestration workflows.
  SHOULD also invoke when user says "automate", "pipeline", "workflow", "cron", "scheduled".
  Do NOT use for simple one-off bash commands.
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---

# Workflow Automation

Patterns for reliable, maintainable automation scripts.

## Idempotency

Scripts must be safe to re-run without side effects:
- Check before create: `if not exists → create`
- Use upsert over insert
- Avoid appending to files without checking for duplicates
- Temp files: use unique names or clean up at start

## Error handling

```bash
set -euo pipefail          # fail fast on any error
trap 'cleanup' EXIT        # always clean up

cleanup() {
  rm -f "$LOCKFILE"
  # release resources
}
```

- Exit codes: 0=success, 1=general error, 2=usage error, 3+=domain-specific
- Never swallow errors silently
- Log the error before exiting

## Logging

```bash
log()  { echo "[$(date -u +%H:%M:%S)] $*"; }
warn() { echo "[WARN] $*" >&2; }
die()  { echo "[ERROR] $*" >&2; exit 1; }
```

- Structured: timestamp + level + message
- Progress indicators for long steps: `log "Step 2/5: building image..."`
- Log inputs at start, outcome at end

## Parallelism

```bash
# Independent tasks in parallel
task_a & task_b & wait

# Dependent tasks sequential
result_a=$(task_a)
task_b "$result_a"
```

Rule: parallel = no shared state. If tasks share state → sequential.

## Signal / lock coordination

```bash
LOCKFILE="/tmp/deploy.lock"
[ -f "$LOCKFILE" ] && die "Another instance running"
touch "$LOCKFILE"
```

For agent coordination: write status to RLM, not shared files.

## Retry pattern

```bash
retry() {
  local n=3
  until "$@"; do
    (( n-- )) || die "Command failed after retries: $*"
    sleep 2
  done
}
```

Use for: network calls, health checks. Never retry: file writes, DB mutations.


---

### Global Skill: code-review
---
name: code-review
description: >
  This skill MUST be invoked when user says "review", "review diff", "check agent result", "code review".
  SHOULD also invoke after a dispatch agent completes work and Opus needs to review changes.
  Do NOT use for writing code — only for reviewing existing changes.
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
---

# Code Review

Review agent work before merge. Goal: catch bugs, security issues, and scope creep. Keep feedback actionable with file:line references.

## Step 1 — Get the diff

```bash
# Between branches
git diff main..HEAD

# Staged only
git diff --staged

# Specific commit
git show <sha>
```

## Step 2 — Security checks

- Hardcoded credentials, tokens, API keys — reject immediately
- SQL/shell injection: user input passed to queries or subprocesses without sanitization
- File path traversal: user-controlled paths without normalization
- Secrets in logs or error messages

## Step 3 — Logic checks

- Off-by-one errors in loops and slices
- Null/None dereference without guard
- Error return values ignored
- Race conditions in concurrent code
- Incorrect boolean logic (especially negations)

## Step 4 — Scope check (critical for agents)

Agent must have done ONLY what was asked. Flag any:
- Refactoring not requested
- Added comments or docstrings not in task
- Renamed variables/functions beyond scope
- Extra features or "improvements"
- Modified files not mentioned in the task

## Step 5 — Style

- Consistent with surrounding code (indentation, naming, quotes)
- No dead code left behind
- No debug prints/console.logs committed

## Output format

```
APPROVE  — no issues found

REQUEST CHANGES:
- file.py:42  — hardcoded password "secret123"
- utils.js:17 — undefined variable `x` used before assignment
- config.py:8 — out of scope: renamed variable not requested in task
```

One line per issue. No prose. File:line mandatory.


If full skill content is provided above, follow those instructions exactly when using the skill.
If only skill names are listed, use the `/skill-name` command to invoke them.

---

# Pre-Exit Checklist

Before you exit, verify ALL items:

- [ ] Task completed, blocked, or context-overflow state determined
- [ ] All work committed to current branch (not pushed)
- [ ] Result JSON file written to `C:/Users/Arman/AppData/Local/Temp/jefest-dispatch/result-1c-ai-workspace-20260304-111111.json`
- [ ] Result JSON contains all required fields: status, project, summary, files, remaining (if applicable)
- [ ] Result JSON is valid JSON (use `jq` or manual parse check)

**Do NOT exit without completing this checklist. Incomplete result file = task failure.**

---

# ⚠️ LAST WARNING: Write Result File Before Exiting

**YOU MUST write `C:/Users/Arman/AppData/Local/Temp/jefest-dispatch/result-1c-ai-workspace-20260304-111111.json` or your work will be lost and ignored.**

If you cannot write the file, the task has FAILED. There a
...(hard-truncated)