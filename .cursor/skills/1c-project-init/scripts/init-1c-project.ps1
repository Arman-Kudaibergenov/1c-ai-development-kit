param(
    [Parameter(Mandatory=$true)][string]$ProjectPath,
    [Parameter(Mandatory=$true)][string]$Server,
    [Parameter(Mandatory=$true)][string]$Database,
    [string]$Username = "",
    [string]$Password = "",
    [string]$ProjectName,
    [string]$OneCPath,
    [string[]]$Extensions = @(),
    [switch]$SkipExtensions,
    [switch]$Force,
    [string]$GitUserName = "Developer",
    [string]$GitUserEmail = "dev@local",
    [string]$SkillsSource = "C:\Users\YOUR_USERNAME\workspace\Home_Infrastructure\.cursor\skills"
)

$ErrorActionPreference = "Stop"
$startTime = Get-Date

# Set console encoding for Cyrillic I/O
chcp 65001 > $null

# Prepare UTF-8 BOM encoding for file writes
$utf8bom = New-Object System.Text.UTF8Encoding($true)

if (-not $ProjectName) { $ProjectName = Split-Path $ProjectPath -Leaf }

Write-Host ""
Write-Host "=== 1C Project Init ===" -ForegroundColor Cyan
Write-Host "Project: $ProjectName" -ForegroundColor Cyan
Write-Host "Path: $ProjectPath" -ForegroundColor Cyan
Write-Host "Database: $Server\$Database" -ForegroundColor Cyan
Write-Host ""

# Step 1: Create structure
Write-Host "[1/12] Creating structure..." -ForegroundColor Yellow

if (Test-Path $ProjectPath) {
    if (-not $Force) {
        Write-Host "  [FAIL] Path already exists. Use -Force to overwrite." -ForegroundColor Red
        exit 1
    }
    Write-Host "  [WARN] Path exists, continuing (-Force)" -ForegroundColor Yellow
} else {
    New-Item -ItemType Directory -Path $ProjectPath -Force | Out-Null
}

$folders = @(
    "src\cf", 
    "src\cfe", 
    "mcp\base\report",      # Отчёт из конфигурации (основная)
    "mcp\base\src",         # Симлинк на src\cf
    "mcp\ext\report",       # Отчёт расширения
    "mcp\ext\src",          # Симлинк на src\cfe
    "openspec\changes\_template", 
    ".cursor\skills", 
    ".cursor\agents", 
    ".cursor\rules", 
    "configs", 
    "docs"
)
foreach ($folder in $folders) {
    $fullPath = Join-Path $ProjectPath $folder
    if (-not (Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
    }
}

# Create junctions for MCP (src folders point to actual code)
# Note: Using junctions instead of symlinks (no admin rights required)
$mcpBaseSrc = Join-Path $ProjectPath "mcp\base\src"
$srcCf = Join-Path $ProjectPath "src\cf"
if ((Test-Path $srcCf) -and -not (Get-Item $mcpBaseSrc -ErrorAction SilentlyContinue).Target) {
    # Remove directory if exists (for junction creation)
    if (Test-Path $mcpBaseSrc) { Remove-Item $mcpBaseSrc -Force -Recurse }
    # Use cmd mklink /J (junction) - doesn't require admin rights
    Push-Location $ProjectPath
    cmd /c "mklink /J `"mcp\base\src`" `"src\cf`"" | Out-Null
    Pop-Location
    Write-Host "  [OK] Created junction: mcp\base\src -> src\cf" -ForegroundColor Green
}

$mcpExtSrc = Join-Path $ProjectPath "mcp\ext\src"
$srcCfe = Join-Path $ProjectPath "src\cfe"
if ((Test-Path $srcCfe) -and -not (Get-Item $mcpExtSrc -ErrorAction SilentlyContinue).Target) {
    # Remove directory if exists (for junction creation)
    if (Test-Path $mcpExtSrc) { Remove-Item $mcpExtSrc -Force -Recurse }
    # Use cmd mklink /J (junction) - doesn't require admin rights
    Push-Location $ProjectPath
    cmd /c "mklink /J `"mcp\ext\src`" `"src\cfe`"" | Out-Null
    Pop-Location
    Write-Host "  [OK] Created junction: mcp\ext\src -> src\cfe" -ForegroundColor Green
}

# Create MCP README
$mcpReadme = @"
# MCP Data Folder

Эта папка содержит данные для MCP серверов (Model Context Protocol).

## Структура

### base/ — Основная конфигурация
- **report/** — Отчёт по конфигурации (экспорт из 1С)
  - Формат: Текстовые файлы (*.txt)
  - Как экспортировать: Конфигуратор → Конфигурация → Отчёты → Отчёт по конфигурации
  - Выбрать: Все объекты
  - Сохранить в: mcp/base/report/
- **src/** → Symlink на src/cf/ (XML выгрузка модулей)

### ext/ — Расширения
- **report/** — Отчёт по расширению
  - Аналогично отчёту конфигурации
  - Экспортировать для каждого расширения отдельно
- **src/** → Symlink на src/cfe/ (XML выгрузка расширений)

## Зачем нужны эти папки?

MCP серверы используют 2 типа данных:

1. **report/** — Метаданные (описания объектов)
   - Используется для семантического поиска
   - Позволяет AI понимать структуру конфигурации
   - Индексируется в Neo4j граф

2. **src/** — Код модулей (BSL)
   - Используется для полнотекстового поиска
   - Позволяет AI искать функции, процедуры
   - Индексируется в векторную БД

## Как экспортировать отчёт

### Для конфигурации (mcp/base/report/)

1. Открыть Конфигуратор 1С
2. Конфигурация → Отчёты → Отчёт по конфигурации
3. Выбрать все объекты (галочки)
4. Формат: Текстовые файлы
5. Сохранить в: {ProjectPath}\mcp\base\report\

### Для расширения (mcp/ext/report/)

1. Открыть Конфигуратор 1С
2. Расширения → <Имя расширения> → Отчёты → Отчёт по конфигурации
3. Выбрать все объекты
4. Формат: Текстовые файлы
5. Сохранить в: {ProjectPath}\mcp\ext\report\

## После экспорта

1. Убедитесь что папки report/ содержат файлы *.txt
2. Убедитесь что symlink src/ указывают на правильные папки
3. Следуйте инструкциям в configs/mcp-setup.md для развёртывания MCP серверов

## Важно

- **report/** — НЕ в Git (большие файлы, часто меняются)
- **src/** — Symlink, НЕ копия (экономия места)
- Обновляйте report/ после изменений метаданных
- Обновляйте src/ через dump-config.bat / dump-extension.bat
"@

[System.IO.File]::WriteAllText((Join-Path $ProjectPath "mcp\README.md"), $mcpReadme, $utf8bom)
Write-Host "  [OK] MCP README created" -ForegroundColor Green

Write-Host "  [OK] Structure created (including MCP folders)" -ForegroundColor Green

# Step 2: Copy skills
Write-Host "[2/12] Copying skills..." -ForegroundColor Yellow

# Core skills (always copy)
$coreSkills = @("1c-batch", "1c-feature-dev-enhanced", "1c-help-mcp", "auto-skill-bootstrap")

# Extended skills (new from cursor_rules_1c integration)
$extendedSkills = @("1c-forms", "1c-mxl", "1c-roles", "1c-bsp", "1c-query-optimization")

# Combine all skills
$skillsToCopy = $coreSkills + $extendedSkills
$copiedSkills = @()

foreach ($skill in $skillsToCopy) {
    $sourcePath = Join-Path $SkillsSource $skill
    $destPath = Join-Path $ProjectPath ".cursor\skills\$skill"
    
    if (Test-Path $sourcePath) {
        Copy-Item -Path $sourcePath -Destination $destPath -Recurse -Force
        $copiedSkills += $skill
        Write-Host "  [OK] $skill" -ForegroundColor Green
    } else {
        Write-Host "  [SKIP] $skill (not found in source)" -ForegroundColor Yellow
    }
}
Write-Host "  [OK] Copied: $($copiedSkills.Count) skills" -ForegroundColor Green

# Step 2.5: Copy agents
Write-Host "[2.5/12] Copying agents..." -ForegroundColor Yellow

$agentsSource = Join-Path (Split-Path $SkillsSource -Parent) "agents"
$agentsDestDir = Join-Path $ProjectPath ".cursor\agents"

$agentsToCopy = @(
    "onec-code-architect.md",
    "onec-code-explorer.md",
    "onec-code-reviewer.md",
    "onec-code-writer.md",
    "onec-code-simplifier.md",
    "onec-form-generator.md",
    "onec-metadata-helper.md",
    "onec-query-optimizer.md",
    "onec-test-generator.md",
    "onec-admin.md",
    "mcp-deploy.md",
    "dev-optimizer.md"
)

$copiedAgents = @()

foreach ($agent in $agentsToCopy) {
    $agentSource = Join-Path $agentsSource $agent
    $agentDest = Join-Path $agentsDestDir $agent
    
    if (Test-Path $agentSource) {
        Copy-Item -Path $agentSource -Destination $agentDest -Force
        $copiedAgents += $agent
    } else {
        Write-Host "  [SKIP] $agent (not found)" -ForegroundColor Yellow
    }
}

Write-Host "  [OK] Copied: $($copiedAgents.Count) agents" -ForegroundColor Green

# Step 3: Find 1C
Write-Host "[3/12] Finding 1C..." -ForegroundColor Yellow

if (-not $OneCPath) {
    # Extract major version from server port: 1540->8.3.25, 1640->8.3.24, 1740->8.3.27
    $serverPort = ""
    if ($Server -match ':(\d+)$') { $serverPort = $Matches[1] }
    
    $possiblePaths = @()
    $programFiles = @(${env:ProgramFiles}, ${env:ProgramFiles(x86)})
    foreach ($pf in $programFiles) {
        if ($pf) {
            $onecDir = Join-Path $pf "1cv8"
            if (Test-Path $onecDir) {
                Get-ChildItem -Path $onecDir -Directory | ForEach-Object {
                    $exePath = Join-Path $_.FullName "bin\1cv8.exe"
                    if (Test-Path $exePath) { $possiblePaths += $exePath }
                }
            }
        }
    }
    
    if ($possiblePaths.Count -eq 0) {
        Write-Host "  [FAIL] 1C not found" -ForegroundColor Red
        exit 1
    }
    
    # Try to match version by server port (known ports: 1540->8.3.25, 1640->8.3.24, 1740->8.3.27)
    $portVersionMap = @{ "1540" = "8.3.25"; "1541" = "8.3.25"; "1640" = "8.3.24"; "1641" = "8.3.24"; "1740" = "8.3.27"; "1741" = "8.3.27" }
    $targetMajor = ""
    if ($serverPort -and $portVersionMap.ContainsKey($serverPort)) {
        $targetMajor = $portVersionMap[$serverPort]
        Write-Host "  [INFO] Port $serverPort -> targeting version $targetMajor" -ForegroundColor Gray
    }
    
    if ($targetMajor) {
        # Find path matching target major version
        $matched = $possiblePaths | Where-Object { $_ -match [regex]::Escape($targetMajor) } | Select-Object -First 1
        if ($matched) {
            $OneCPath = $matched
        } else {
            Write-Host "  [WARN] Version $targetMajor not found, using latest" -ForegroundColor Yellow
            $OneCPath = $possiblePaths | Sort-Object -Descending | Select-Object -First 1
        }
    } else {
        $OneCPath = $possiblePaths | Sort-Object -Descending | Select-Object -First 1
    }
}

$versionInfo = (Get-Item $OneCPath).VersionInfo
$version = "$($versionInfo.FileMajorPart).$($versionInfo.FileMinorPart).$($versionInfo.FileBuildPart)"
Write-Host "  [OK] 1C version: $version" -ForegroundColor Green

# Step 4: Create .1c-devbase.bat from 1c-batch template
Write-Host "[4/12] Creating config..." -ForegroundColor Yellow

$targetPath = Join-Path $ProjectPath ".1c-devbase.bat"

if (Test-Path $targetPath) {
    # .1c-devbase.bat already exists (created by agent via Write tool for Cyrillic support)
    # Read Username from it for later steps (ibcmd, README)
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    $existingContent = $utf8NoBom.GetString([System.IO.File]::ReadAllBytes($targetPath))
    if ($existingContent -match 'set "ONEC_USER=([^"]*)"') {
        $Username = $Matches[1]
        Write-Host "  [OK] Using existing config (user: $Username)" -ForegroundColor Green
    } else {
        Write-Host "  [OK] Using existing config" -ForegroundColor Green
    }
    if ($existingContent -match 'set "ONEC_PASSWORD=([^"]*)"') {
        $Password = $Matches[1]
    }
    # Also read OneCPath if not specified
    if (-not $OneCPath -and $existingContent -match 'set "ONEC_PATH=([^"]*)"') {
        $OneCPath = $Matches[1]
    }
} else {
    $templatePath = Join-Path $ProjectPath ".cursor\skills\1c-batch\.1c-devbase.bat.example"

    if (-not (Test-Path $templatePath)) {
        Write-Host "  [FAIL] Template not found: $templatePath" -ForegroundColor Red
        exit 1
    }

    # Read template as bytes to preserve original encoding (UTF-8 without BOM)
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    $templateBytes = [System.IO.File]::ReadAllBytes($templatePath)
    $content = $utf8NoBom.GetString($templateBytes)
    $lines = $content -split "`r`n"

    # Replace only active lines (starting with 'set "ONEC_'), REM lines stay intact
    $result = @()
    foreach ($line in $lines) {
        if ($line -match '^set "ONEC_PATH=') {
            $result += "set ""ONEC_PATH=$OneCPath"""
        } elseif ($line -match '^set "ONEC_SERVER=') {
            $result += "set ""ONEC_SERVER=$Server"""
        } elseif ($line -match '^set "ONEC_BASE=') {
            $result += "set ""ONEC_BASE=$Database"""
        } elseif ($line -match '^set "ONEC_USER=') {
            $result += "set ""ONEC_USER=$Username"""
        } elseif ($line -match '^set "ONEC_PASSWORD=') {
            $result += "set ""ONEC_PASSWORD=$Password"""
        } else {
            $result += $line
        }
    }

    # Write as UTF-8 with BOM for proper Cyrillic handling
    $finalContent = $result -join "`r`n"
    [System.IO.File]::WriteAllText($targetPath, $finalContent, $utf8bom)

    if (Test-Path $targetPath) {
        Write-Host "  [OK] Config created (from template)" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] Config creation failed" -ForegroundColor Red
        exit 1
    }
}

# Step 5: Dump configuration (via 1c-batch skill)
Write-Host "[5/12] Dumping configuration..." -ForegroundColor Yellow

$dumpScript = Join-Path $ProjectPath ".cursor\skills\1c-batch\scripts\dump-config.bat"
if (Test-Path $dumpScript) {
    Push-Location $ProjectPath
    try {
        $output = & cmd /c $dumpScript "src\cf" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Configuration dumped" -ForegroundColor Green
        } else {
            Write-Host "  [FAIL] Dump failed" -ForegroundColor Red
            Write-Host $output -ForegroundColor Yellow
            exit 1
        }
    } finally {
        Pop-Location
    }
} else {
    Write-Host "  [FAIL] dump-config.bat not found" -ForegroundColor Red
    exit 1
}

# Step 6: Dump extensions (via 1c-batch skill)
Write-Host "[6/12] Dumping extensions..." -ForegroundColor Yellow

if ($SkipExtensions) {
    Write-Host "  [SKIP] Extensions skipped (-SkipExtensions)" -ForegroundColor Yellow
} else {
    # Extensions must be specified explicitly (ibcmd extension list doesn't work with server databases)
    if ($Extensions.Count -eq 0) {
        Write-Host "  [INFO] No extensions specified, skipping" -ForegroundColor Gray
        Write-Host "  [INFO] To dump extensions, re-run with: -Extensions @('Name1','Name2')" -ForegroundColor Gray
    }
    
    if ($Extensions.Count -gt 0) {
        $dumpExtScript = Join-Path $ProjectPath ".cursor\skills\1c-batch\scripts\dump-extension.bat"
        if (-not (Test-Path $dumpExtScript)) {
            Write-Host "  [FAIL] dump-extension.bat not found" -ForegroundColor Red
            exit 1
        }
        
        $foundExtensions = @()
        Push-Location $ProjectPath
        try {
            foreach ($extName in $Extensions) {
                $extDir = "src\cfe\$extName"
                Write-Host "  Dumping extension: $extName..." -ForegroundColor Gray
                $output = & cmd /c $dumpExtScript $extDir $extName 2>&1
                if ($LASTEXITCODE -eq 0) {
                    $foundExtensions += $extName
                    Write-Host "  [OK] $extName" -ForegroundColor Green
                } else {
                    Write-Host "  [FAIL] $extName" -ForegroundColor Red
                    Write-Host $output -ForegroundColor Yellow
                }
            }
        } finally {
            Pop-Location
        }
        
        Write-Host "  [OK] Extensions dumped: $($foundExtensions.Count) of $($Extensions.Count)" -ForegroundColor Green
    }
}

# Step 7: Copy rules
Write-Host "[7/12] Copying rules..." -ForegroundColor Yellow

$rulesSource = Join-Path (Split-Path $SkillsSource -Parent) "rules"
$rulesDestDir = Join-Path $ProjectPath ".cursor\rules"

if (-not (Test-Path $rulesDestDir)) {
    New-Item -ItemType Directory -Path $rulesDestDir -Force | Out-Null
}

# Core rules (always copy)
$rulesToCopy = @(
    "skills-first.mdc",
    "no-roi-estimates.mdc",
    "context-management.mdc",
    "model-selection.mdc",
    "bsl-lsp-integration.mdc",
    "rlm-toolkit-autoload.mdc",
    "mcp-tools-usage.mdc"
)

$copiedRules = @()

foreach ($rule in $rulesToCopy) {
    $ruleSource = Join-Path $rulesSource $rule
    $ruleDest = Join-Path $rulesDestDir $rule
    
    if (Test-Path $ruleSource) {
        Copy-Item -Path $ruleSource -Destination $ruleDest -Force
        $copiedRules += $rule
        Write-Host "  [OK] $rule" -ForegroundColor Green
    } else {
        Write-Host "  [SKIP] $rule (not found)" -ForegroundColor Yellow
    }
}
Write-Host "  [OK] Copied: $($copiedRules.Count) rules" -ForegroundColor Green

# Step 7.5: Copy documentation and .cursorignore
Write-Host "[7.5/12] Copying documentation..." -ForegroundColor Yellow

$homeInfraRoot = "C:\Users\YOUR_USERNAME\workspace\Home_Infrastructure"

# Copy .cursorignore
$cursorignoreSource = Join-Path $homeInfraRoot ".cursorignore"
if (Test-Path $cursorignoreSource) {
    Copy-Item -Path $cursorignoreSource -Destination (Join-Path $ProjectPath ".cursorignore") -Force
    Write-Host "  [OK] .cursorignore" -ForegroundColor Green
} else {
    Write-Host "  [SKIP] .cursorignore (not found)" -ForegroundColor Yellow
}

# Copy CURSOR-CONTEXT-LIMITS.md
$contextLimitsSource = Join-Path $homeInfraRoot "CURSOR-CONTEXT-LIMITS.md"
if (Test-Path $contextLimitsSource) {
    Copy-Item -Path $contextLimitsSource -Destination (Join-Path $ProjectPath "CURSOR-CONTEXT-LIMITS.md") -Force
    Write-Host "  [OK] CURSOR-CONTEXT-LIMITS.md" -ForegroundColor Green
} else {
    Write-Host "  [SKIP] CURSOR-CONTEXT-LIMITS.md (not found)" -ForegroundColor Yellow
}

# Copy cursor-optimization.md to docs/
$cursorOptSource = Join-Path $homeInfraRoot "docs\cursor-optimization.md"
if (Test-Path $cursorOptSource) {
    Copy-Item -Path $cursorOptSource -Destination (Join-Path $ProjectPath "docs\cursor-optimization.md") -Force
    Write-Host "  [OK] docs/cursor-optimization.md" -ForegroundColor Green
} else {
    Write-Host "  [SKIP] docs/cursor-optimization.md (not found)" -ForegroundColor Yellow
}

# Copy export-configuration-report.md to docs/
$exportReportSource = Join-Path $SkillsSource "..\1c-project-init\docs\export-configuration-report.md"
if (Test-Path $exportReportSource) {
    Copy-Item -Path $exportReportSource -Destination (Join-Path $ProjectPath "docs\export-configuration-report.md") -Force
    Write-Host "  [OK] docs/export-configuration-report.md" -ForegroundColor Green
} else {
    Write-Host "  [SKIP] docs/export-configuration-report.md (not found)" -ForegroundColor Yellow
}

Write-Host "  [OK] Documentation copied" -ForegroundColor Green

# Step 8: Create OpenSpec
Write-Host "[8/12] Creating OpenSpec..." -ForegroundColor Yellow

$openspecSource = "C:\Users\YOUR_USERNAME\workspace\Home_Infrastructure\openspec"
if (Test-Path $openspecSource) {
    $agentsSource = Join-Path $openspecSource "AGENTS.md"
    if (Test-Path $agentsSource) {
        Copy-Item $agentsSource (Join-Path $ProjectPath "openspec\AGENTS.md")
    }
    
    $specTemplate = Join-Path $openspecSource "changes\_template\spec.md"
    if (Test-Path $specTemplate) {
        Copy-Item $specTemplate (Join-Path $ProjectPath "openspec\changes\_template\spec.md")
    }
}

$projectMd = @"
# Project Context: $ProjectName

## Purpose

1C project for database: $Database

## Tech Stack

- Platform: 1C:Enterprise $version
- Database: $Server\$Database
- VCS: Git

## Development Environment

- 1C:Enterprise $version
- VS Code + Cursor

Connection:
- File: .1c-devbase.bat (not in git)
- Server: $Server
- Database: $Database
"@

[System.IO.File]::WriteAllText((Join-Path $ProjectPath "openspec\project.md"), $projectMd, $utf8bom)

$openspecReadme = @"
# OpenSpec - Specification-Driven Development

## Structure

- changes/ - active changes
- changes/_template/ - template for new changes
- project.md - project context
- AGENTS.md - AI instructions

## Creating new change

1. Create folder: openspec/changes/<change-name>/
2. Copy template from _template/spec.md
3. Fill specification
4. Develop in extension src/cfe/

See: AGENTS.md
"@

[System.IO.File]::WriteAllText((Join-Path $ProjectPath "openspec\README.md"), $openspecReadme, $utf8bom)
Write-Host "  [OK] OpenSpec created" -ForegroundColor Green

# Step 9: Create README
Write-Host "[9/12] Creating README..." -ForegroundColor Yellow

$readme = @"
# $ProjectName - 1C Project

**Important:** Cursor has a context limit of **200K tokens**. See `CURSOR-CONTEXT-LIMITS.md` for optimization strategies.

## Connection

Server: $Server
Database: $Database
User: $Username

## Structure

- src/cf/ - configuration (XML выгрузка)
- src/cfe/ - extensions (XML выгрузка)
- mcp/base/ - данные для MCP (конфигурация)
  - report/ - отчёт по конфигурации (экспорт из 1С)
  - src/ → symlink на src/cf/
- mcp/ext/ - данные для MCP (расширения)
  - report/ - отчёт по расширению
  - src/ → symlink на src/cfe/
- .cursor/agents/ - specialized AI agents (12)
  - onec-code-architect, onec-code-explorer, onec-code-reviewer
  - onec-code-writer, onec-code-simplifier, onec-form-generator
  - onec-metadata-helper, onec-query-optimizer, onec-test-generator
  - onec-admin, mcp-deploy, dev-optimizer
- .cursor/skills/ - skills
  - 1c-batch/ - batch operations
  - 1c-feature-dev-enhanced/ - full dev cycle
  - 1c-help-mcp/ - 1C documentation
  - auto-skill-bootstrap/ - auto-install skills
- .cursor/rules/ - AI rules (7 rules)
  - skills-first.mdc - use skills before custom code
  - no-roi-estimates.mdc - no time/cost estimates
  - context-management.mdc - context optimization (200K limit)
  - model-selection.mdc - Opus vs Sonnet selection
  - bsl-lsp-integration.mdc - BSL LSP usage
  - rlm-toolkit-autoload.mdc - RLM memory system
  - mcp-tools-usage.mdc - MCP tools guide
- openspec/ - specifications (SDD)
- configs/ - configuration guides
  - mcp-setup.md - MCP deployment instructions
- docs/ - documentation
  - cursor-optimization.md - optimization guide
  - export-configuration-report.md - how to export report for MCP
- .1c-devbase.bat - connection settings (not in git)
- .cursorignore - Cursor cache optimization
- CURSOR-CONTEXT-LIMITS.md - context limits and strategies

## Working with configuration

### Dump configuration

.cursor\skills\1c-batch\scripts\dump-config.bat src\cf

### Load configuration

.cursor\skills\1c-batch\scripts\load-config.bat src\cf

## Working with extensions

### Dump extension

.cursor\skills\1c-batch\scripts\dump-extension.bat src\cfe\<Name> <Name>

### Load extension

.cursor\skills\1c-batch\scripts\load-extension.bat src\cfe\<Name> <Name>

## Optional: Deploy MCP servers

For full AI capabilities (metadata graph, code search, semantic search):

See: configs/mcp-setup.md

## History

- $(Get-Date -Format "yyyy-MM-dd HH:mm"): Project created via init-1c-project.ps1
"@

[System.IO.File]::WriteAllText((Join-Path $ProjectPath "README.md"), $readme, $utf8bom)
Write-Host "  [OK] README created" -ForegroundColor Green

# Step 10: Create MCP deployment guide
Write-Host "[10/12] Creating MCP deployment guide..." -ForegroundColor Yellow

$projectLower = $ProjectName.ToLower() -replace '[^a-z0-9]', ''

$mcpSetup = @"
# MCP Deployment Guide for $ProjectName

## Overview

This guide helps deploy project-specific MCP servers for enhanced AI capabilities.

**Timeline:** ~60 minutes per object (mostly indexing)

## Prerequisites

- Docker LXC (YOUR_SERVER) accessible
- SSH access to YOUR_SERVER
- Project configuration dumped to src/cf/
- **Configuration report exported** (see "Prepare Data" below)

## Prepare Data for MCP

MCP servers need **2 types of data**:

### 1. Configuration Report (mcp/base/report/)
**What:** Текстовый отчёт по конфигурации из 1С
**How to export:**
``````
1. Open 1C Designer → Configuration → Reports → Configuration Report
2. Select all objects
3. Export to: mcp/base/report/
4. Format: Text files (*.txt)
``````

**Purpose:** Metadata descriptions for semantic search

### 2. Code Files (mcp/base/src/ → symlink to src/cf/)
**What:** XML выгрузка модулей (уже есть в src/cf/)
**How:** Symlink created automatically by init script

``````
mcp/base/src -> src/cf/  (symlink)
``````

**Purpose:** BSL code for full-text search

### For Extensions (if any)
Same structure in `mcp/ext/`:
- `mcp/ext/report/` — Configuration Report for extension
- `mcp/ext/src/` → symlink to `src/cfe/`

## MCP Servers to Deploy

**IMPORTANT:** For each object (configuration or extension), you need **2 MCP servers**:
1. **`{name}-codemetadata`** — Semantic search (embeddings for AI-powered code search)
2. **`{name}-graph`** — Neo4j graph database (metadata structure and relationships)

**Objects to deploy:**
- **Configuration (mcp/base/)** — base metadata and code
- **Extensions (mcp/ext/)** — each extension separately

**Recommendation:**
- Small projects (<5,000 files): Configuration only (2 servers)
- Medium projects (5,000-20,000 files): Configuration + main extension (4 servers)
- Large projects (>20,000 files): Configuration + all extensions (2 servers per object)

---

### Configuration: ${projectLower}-codemetadata
**Purpose:** Semantic search with embeddings (AI-powered code search)

**Source:** ``mcp/base/report/`` + ``mcp/base/src/``

**Port:** 7500

**Deployment:**
``````bash
ssh YOUR_SERVER "pct exec 100 -- docker run -d \\
  --name ${projectLower}-codemetadata \\
  --restart unless-stopped \\
  -p 7500:8000 \\
  -e EMBEDDING_PROVIDER=openrouter \\
  -e OPENROUTER_API_KEY=\$OPENROUTER_API_KEY \\
  -e EMBEDDING_MODEL=qwen/qwen3-embedding-8b \\
  -e SOURCE_PATH=/data/src \\
  -e CHROMA_PATH=/data/chroma_db \\
  -e AUTO_INDEX=true \\
  -v /opt/mcp-projects/${projectLower}/base:/data \\
  1c-cloud-mcp:latest"
``````

**Indexing time:** ~10-15 minutes

---

### Configuration: ${projectLower}-graph
**Purpose:** Neo4j graph database of configuration metadata and relationships

**Source:** ``mcp/base/report/`` + ``mcp/base/src/``

**Ports:** 7501 (HTTP), 7502 (Bolt)

**Deployment:**
``````bash
ssh YOUR_SERVER "pct exec 100 -- docker run -d \\
  --name ${projectLower}-graph \\
  --restart unless-stopped \\
  -p 7501:7474 \\
  -p 7502:7687 \\
  -e NEO4J_AUTH=neo4j/neo4j \\
  -v /opt/mcp-projects/${projectLower}/base/neo4j:/data \\
  neo4j:latest"
``````

**Indexing time:** ~40-60 minutes

---

### Extension: ${projectLower}-{extname}-codemetadata (if extensions exist)
**Purpose:** Semantic search for extension code

**Source:** ``mcp/ext/report/`` + ``mcp/ext/src/``

**Port:** 7510

**Deployment:**
``````bash
ssh YOUR_SERVER "pct exec 100 -- docker run -d \\
  --name ${projectLower}-{extname}-codemetadata \\
  --restart unless-stopped \\
  -p 7510:8000 \\
  -e EMBEDDING_PROVIDER=openrouter \\
  -e OPENROUTER_API_KEY=\$OPENROUTER_API_KEY \\
  -e EMBEDDING_MODEL=qwen/qwen3-embedding-8b \\
  -e SOURCE_PATH=/data/src \\
  -e CHROMA_PATH=/data/chroma_db \\
  -e AUTO_INDEX=true \\
  -v /opt/mcp-projects/${projectLower}/ext:/data \\
  1c-cloud-mcp:latest"
``````

**Indexing time:** ~10-15 minutes

---

### Extension: ${projectLower}-{extname}-graph
**Purpose:** Neo4j graph database of extension metadata

**Source:** ``mcp/ext/report/`` + ``mcp/ext/src/``

**Ports:** 7511 (HTTP), 7512 (Bolt)

**Deployment:**
``````bash
ssh YOUR_SERVER "pct exec 100 -- docker run -d \\
  --name ${projectLower}-{extname}-graph \\
  --restart unless-stopped \\
  -p 7511:7474 \\
  -p 7512:7687 \\
  -e NEO4J_AUTH=neo4j/neo4j \\
  -v /opt/mcp-projects/${projectLower}/ext/neo4j:/data \\
  neo4j:latest"
``````

**Indexing time:** ~40-60 minutes

---

**Note:** Each object (configuration or extension) gets **2 MCP servers** with separate ports

### Project Documentation: ${projectLower}-help
**Purpose:** Project documentation and help system

**Source:** README.md, openspec/, docs/

**Deployment:**
``````bash
ssh YOUR_SERVER "pct exec 100 -- docker run -d \\
  --name ${projectLower}-help \\
  --restart unless-stopped \\
  -p 7503:8080 \\
  -v /opt/mcp-projects/${projectLower}/docs:/data \\
  <help-image>"
``````

## Quick Start (Automated)

Use the **mcp-deploy** agent:

``````
User: "Deploy MCP servers for $ProjectName"

Agent will ask:
1. "Создать MCP для конфигурации (src/cf/)?" → Yes/No
2. "Есть расширения в src/cfe/?" → Yes/No
3. If Yes: "Для каких расширений создать MCP?" → List names or "all"

Then agent will:
1. Create Docker containers on YOUR_SERVER
2. Configure mcp.json
3. Start indexing
4. Report when ready (~60 min per object)
``````

### Example Interaction

**Scenario 1: Configuration only**
``````
User: "Deploy MCP for $ProjectName"
Agent: "Создать MCP для конфигурации (mcp/base/)?"
User: "Да"
Agent: "Есть расширения в mcp/ext/?"
User: "Нет"
Agent: → Deploys 2 servers:
  - ${projectLower}-codemetadata (port 7500) — semantic search
  - ${projectLower}-graph (ports 7501-7502) — Neo4j metadata graph
``````

**Scenario 2: Configuration + Extension**
``````
User: "Deploy MCP for $ProjectName"
Agent: "Создать MCP для конфигурации (mcp/base/)?"
User: "Да"
Agent: "Есть расширения в mcp/ext/?"
User: "Да, расширение ExtName"
Agent: "Создать MCP для расширения ExtName?"
User: "Да"
Agent: → Deploys 4 servers:
  Configuration:
  - ${projectLower}-codemetadata (port 7500) — semantic search
  - ${projectLower}-graph (ports 7501-7502) — Neo4j graph
  Extension:
  - ${projectLower}-extname-codemetadata (port 7510) — semantic search
  - ${projectLower}-extname-graph (ports 7511-7512) — Neo4j graph
``````

**Scenario 3: Extension only (rare)**
``````
User: "Deploy MCP for $ProjectName extension ExtName"
Agent: "Создать MCP для конфигурации (mcp/base/)?"
User: "Нет, только для расширения"
Agent: → Deploys 2 servers:
  - ${projectLower}-extname-codemetadata (port 7510) — semantic search
  - ${projectLower}-extname-graph (ports 7511-7512) — Neo4j graph
``````

## Manual Deployment

### Step 1: Choose ports

**Port allocation strategy:**
``````
Configuration (base):
- ${projectLower}-codemetadata: 7500 — semantic search
- ${projectLower}-graph: 7501 (HTTP), 7502 (Bolt) — Neo4j

Extension 1 (e.g., ExtName):
- ${projectLower}-extname-codemetadata: 7510 — semantic search
- ${projectLower}-extname-graph: 7511 (HTTP), 7512 (Bolt) — Neo4j

Extension 2 (if any):
- ${projectLower}-ext2-codemetadata: 7520 — semantic search
- ${projectLower}-ext2-graph: 7521 (HTTP), 7522 (Bolt) — Neo4j
``````

**Rule:** Each object (cf or extension) gets +10 port offset

### Step 2: Deploy containers
See individual server sections above

### Step 3: Update mcp.json
Add to ``C:\Users\YOUR_USERNAME\.cursor\mcp.json``:

**Configuration only:**
``````json
{
  "${projectLower}-codemetadata": {
    "command": "curl",
    "args": ["-X", "POST", "http://YOUR_SERVER:7500/search", "-H", "Content-Type: application/json", "-d", "@-"]
  },
  "${projectLower}-graph": {
    "command": "docker",
    "args": ["exec", "-i", "${projectLower}-graph", "cypher-shell", "-u", "neo4j", "-p", "neo4j"]
  }
}
``````

**Configuration + Extension (ExtName):**
``````json
{
  "${projectLower}-codemetadata": {
    "command": "curl",
    "args": ["-X", "POST", "http://YOUR_SERVER:7500/search", "-H", "Content-Type: application/json", "-d", "@-"]
  },
  "${projectLower}-graph": {
    "command": "docker",
    "args": ["exec", "-i", "${projectLower}-graph", "cypher-shell", "-u", "neo4j", "-p", "neo4j"]
  },
  "${projectLower}-extname-codemetadata": {
    "command": "curl",
    "args": ["-X", "POST", "http://YOUR_SERVER:7510/search", "-H", "Content-Type: application/json", "-d", "@-"]
  },
  "${projectLower}-extname-graph": {
    "command": "docker",
    "args": ["exec", "-i", "${projectLower}-extname-graph", "cypher-shell", "-u", "neo4j", "-p", "neo4j"]
  }
}
``````

### Step 4: Index metadata
Run indexing script (provided by mcp-deploy agent)

### Step 5: Verify
``````bash
# Check semantic search (codemetadata)
curl http://YOUR_SERVER:7500/health

# Check Neo4j graph
curl http://YOUR_SERVER:7501

# For extension (if deployed)
curl http://YOUR_SERVER:7510/health  # semantic search
curl http://YOUR_SERVER:7511          # Neo4j
``````

## After Deployment

1. Restart Cursor to load new MCP servers
2. Use specialized agents:
   - onec-metadata-helper: Navigate metadata graph
   - onec-code-explorer: Deep code analysis
   - onec-query-optimizer: Query optimization with metadata
3. Agents will automatically use project-specific MCP servers

## Troubleshooting

### MCP server not responding
``````bash
ssh YOUR_SERVER "pct exec 100 -- docker logs ${projectLower}-metadata"
``````

### Indexing stuck
Check disk space and memory on Docker LXC

### Cursor doesn't see MCP
1. Verify mcp.json syntax
2. Restart Cursor
3. Check MCP server health endpoints

## Cost Estimate

- Storage: ~500MB-2GB (depending on project size)
- Memory: ~512MB per server
- CPU: Minimal after indexing

## Notes

- MCP servers are **optional** — project works without them
- Deploy when ready for advanced AI features
- Can deploy incrementally (metadata first, then others)
"@

# Write with UTF-8 BOM for proper Cyrillic display
[System.IO.File]::WriteAllText((Join-Path $ProjectPath "configs\mcp-setup.md"), $mcpSetup, $utf8bom)
Write-Host "  [OK] MCP deployment guide created" -ForegroundColor Green

# Step 11: Create .cursorrules (optional project-specific rules)
Write-Host "[11/12] Creating project rules..." -ForegroundColor Yellow

$cursorRules = @"
# Project-Specific Rules for $ProjectName

## Database Connection

- Server: $Server
- Database: $Database
- Version: 1C:Enterprise $version

## Development Workflow

1. Use SDD workflow (openspec/)
2. All changes via extensions (src/cfe/)
3. Configuration (src/cf/) is reference only

## Agents Available

- onec-code-architect: Design features
- onec-code-writer: Implement code
- onec-code-reviewer: Review changes
- onec-form-generator: Generate forms
- onec-test-generator: Generate tests
- onec-admin: Manage 1C servers/databases
- mcp-deploy: Deploy MCP servers
- dev-optimizer: Optimize workflow

## Skills Available

- 1c-batch: Dump/load config/extensions
- 1c-feature-dev-enhanced: Full dev cycle
- 1c-help-mcp: 1C documentation search
- auto-skill-bootstrap: Auto-install skills
"@

# Write with UTF-8 BOM for proper Cyrillic display
[System.IO.File]::WriteAllText((Join-Path $ProjectPath ".cursorrules"), $cursorRules, $utf8bom)
Write-Host "  [OK] Project rules created" -ForegroundColor Green

# Step 12: Git init
Write-Host "[12/13] Creating project MCP configuration..." -ForegroundColor Yellow

# Вызываем manage-project-mcp.ps1 для создания проектного MCP конфига
$manageMcpScript = Join-Path $PSScriptRoot "manage-project-mcp.ps1"
if (Test-Path $manageMcpScript) {
    & $manageMcpScript -Action "create" -ProjectPath $ProjectPath -ProjectName $ProjectName
    Write-Host "  [OK] Project MCP config created" -ForegroundColor Green
} else {
    Write-Host "  [WARN] manage-project-mcp.ps1 not found, skipping" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[13/13] Initializing Git..." -ForegroundColor Yellow

Push-Location $ProjectPath
try {
    if (-not (Test-Path ".git")) {
        git init | Out-Null
        Write-Host "  [OK] Git initialized" -ForegroundColor Green
    }
    
    # Set local git identity (for fresh repos without global config)
    git config user.name $GitUserName 2>$null
    git config user.email $GitUserEmail 2>$null
    
    $gitignore = @"
# Credentials
.1c-devbase.bat

# Logs and temp files
*.log
*.tmp

# MCP data (large, frequently updated)
mcp/base/report/
mcp/ext/report/

# Note: mcp/base/src and mcp/ext/src are symlinks (tracked by git)
"@
    # Write with UTF-8 BOM for proper Cyrillic display
    [System.IO.File]::WriteAllText(".gitignore", $gitignore, $utf8bom)
    
    git add src/cf mcp .gitignore .cursorignore .cursor/skills .cursor/rules .cursor/agents openspec README.md CURSOR-CONTEXT-LIMITS.md configs docs .cursorrules
    git commit -m "feat: Initial commit - configuration, MCP folders, agents, rules, and optimization docs" | Out-Null
    Write-Host "  [OK] Commit 1: Configuration + MCP structure" -ForegroundColor Green
    
    if (Test-Path "src\cfe") {
        $cfeFiles = Get-ChildItem "src\cfe" -Recurse -File -ErrorAction SilentlyContinue
        if ($cfeFiles.Count -gt 0) {
            git add src/cfe
            git commit -m "feat: Add extensions" | Out-Null
            Write-Host "  [OK] Commit 2: Extensions" -ForegroundColor Green
        }
    }
    
    Write-Host "  [OK] Git configured" -ForegroundColor Green
    
} finally {
    Pop-Location
}

$duration = (Get-Date) - $startTime
Write-Host ""
Write-Host "=== SUCCESS ===" -ForegroundColor Green
Write-Host "Path: $ProjectPath" -ForegroundColor Cyan
Write-Host "Time: $($duration.TotalSeconds.ToString('0.0')) sec" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. cd $ProjectPath"
Write-Host "2. Open in Cursor"
Write-Host "3. Start development via openspec/changes/"
Write-Host ""
