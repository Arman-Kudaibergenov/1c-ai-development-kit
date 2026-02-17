param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("create", "index-cloud", "switch-local", "enable", "disable", "status")]
    [string]$Action,
    
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath,
    
    [string]$ProjectName,
    [int]$BasePort = 8000,
    [string]$CloudModel = "qwen/qwen-2.5-72b-instruct",
    [string]$LocalModel = "qwen3:8b",
    [string]$OllamaHost = "http://YOUR_SERVER:11434"
)

$ErrorActionPreference = "Stop"
chcp 65001 > $null

if (-not $ProjectName) {
    $ProjectName = Split-Path $ProjectPath -Leaf
}

$projectMcpJson = Join-Path $ProjectPath ".cursor\mcp.json"
$mcpBasePath = Join-Path $ProjectPath "mcp\base"
$mcpExtPath = Join-Path $ProjectPath "mcp\ext"

# Sanitize project name for MCP IDs (lowercase, no spaces)
$mcpId = $ProjectName.ToLower() -replace '\s+', '-' -replace '[^a-z0-9\-]', ''

Write-Host ""
Write-Host "=== Project MCP Manager ===" -ForegroundColor Cyan
Write-Host "Action: $Action" -ForegroundColor Cyan
Write-Host "Project: $ProjectName" -ForegroundColor Cyan
Write-Host "MCP ID: $mcpId" -ForegroundColor Cyan
Write-Host ""

function Get-ProjectMcpConfig {
    param([string]$Model, [string]$ModelType)
    
    $config = @{
        mcpServers = @{
            # Общие MCP (всегда доступны)
            "1c-help" = @{
                url = "http://YOUR_SERVER:8003/mcp"
                connection_id = "1c_docs_service_001"
                description = "Справка по платформе 1С:Предприятие 8.3"
            }
            "1c-ssl" = @{
                url = "http://YOUR_SERVER:8008/mcp"
                connection_id = "1c_ssl_service_001"
                description = "Справка по БСП 3.1.11"
            }
            "1c-templates" = @{
                url = "http://YOUR_SERVER:8004/mcp"
                connection_id = "1c_templates_service_001"
                description = "Шаблоны кода 1С"
            }
            "1c-syntax-checker" = @{
                url = "http://YOUR_SERVER:8002/mcp/"
                connection_id = "1c_lsp_service_001"
                description = "Проверка синтаксиса через BSL Language Server"
            }
            "1c-code-checker" = @{
                url = "http://YOUR_SERVER:8007/mcp"
                connection_id = "1c_code_checker_001"
                description = "Проверка логики кода через 1С:Напарника"
            }
            "1c-forms" = @{
                url = "http://YOUR_SERVER:8011/mcp"
                connection_id = "1c_forms_service_001"
                description = "Контекст для генерации управляемых форм"
            }
            "rlm-toolkit" = @{
                url = "http://YOUR_SERVER:8200/sse"
                connection_id = "rlm_toolkit_001"
                description = "RLM-Toolkit: персистентная память между чатами"
            }
            "bsl-lsp-bridge" = @{
                type = "stdio"
                command = "ssh"
                args = @("YOUR_SERVER", "pct", "exec", "100", "--", "docker", "exec", "-i", "mcp-lsp-home-infra", "mcp-lsp-bridge")
                connection_id = "bsl_lsp_bridge_001"
                description = "BSL LSP Bridge: singleton LSP сервер"
            }
        }
    }
    
    # Проектные MCP (только для этого проекта)
    $config.mcpServers["$mcpId-codemetadata"] = @{
        url = "http://localhost:$BasePort/mcp"
        connection_id = "${mcpId}_codemetadata_001"
        description = "$ProjectName - семантический поиск (модель: $Model, тип: $ModelType)"
    }
    
    $config.mcpServers["$mcpId-graph"] = @{
        url = "http://localhost:$($BasePort + 1)/mcp"
        connection_id = "${mcpId}_graph_001"
        description = "$ProjectName - графовый поиск по связям объектов (Neo4j)"
    }
    
    return $config
}

function Save-McpConfig {
    param($Config, $Path)
    
    $json = $Config | ConvertTo-Json -Depth 10
    $utf8bom = New-Object System.Text.UTF8Encoding($true)
    [System.IO.File]::WriteAllText($Path, $json, $utf8bom)
}

switch ($Action) {
    "create" {
        Write-Host "[1/3] Creating project MCP config..." -ForegroundColor Yellow
        
        # Создаем конфиг с облачной моделью для начальной индексации
        $config = Get-ProjectMcpConfig -Model $CloudModel -ModelType "cloud"
        $cursorDir = Join-Path $ProjectPath ".cursor"
        if (-not (Test-Path $cursorDir)) {
            New-Item -ItemType Directory -Path $cursorDir -Force | Out-Null
        }
        
        Save-McpConfig -Config $config -Path $projectMcpJson
        Write-Host "  [OK] Created: $projectMcpJson" -ForegroundColor Green
        Write-Host "  [INFO] Using CLOUD model: $CloudModel" -ForegroundColor Cyan
        
        Write-Host ""
        Write-Host "[2/3] Creating docker-compose.yml..." -ForegroundColor Yellow
        
        $dockerCompose = @"
version: '3.8'

services:
  ${mcpId}-codemetadata:
    image: ghcr.io/arqadium/mcp-1c-server:latest
    container_name: ${mcpId}-codemetadata
    ports:
      - "${BasePort}:8000"
    volumes:
      - ./mcp/base/report:/app/data/report
      - ./mcp/base/src:/app/data/src
      - ./mcp/ext/report:/app/data/ext_report
      - ./mcp/ext/src:/app/data/ext_src
      - ${mcpId}-chroma:/app/chroma_data
    environment:
      - MCP_SERVER_NAME=${ProjectName}
      - EMBEDDING_MODEL=${CloudModel}
      - EMBEDDING_PROVIDER=openrouter
      - OPENROUTER_API_KEY=\${OPENROUTER_API_KEY}
      - OLLAMA_HOST=${OllamaHost}
    restart: unless-stopped
    networks:
      - mcp-network

  ${mcpId}-graph:
    image: neo4j:5.15.0
    container_name: ${mcpId}-graph
    ports:
      - "$($BasePort + 1):7474"
      - "$($BasePort + 2):7687"
    volumes:
      - ${mcpId}-neo4j:/data
    environment:
      - NEO4J_AUTH=neo4j/password
      - NEO4J_dbms_memory_pagecache_size=512M
      - NEO4J_dbms_memory_heap_max__size=1G
    restart: unless-stopped
    networks:
      - mcp-network

volumes:
  ${mcpId}-chroma:
  ${mcpId}-neo4j:

networks:
  mcp-network:
    driver: bridge
"@
        
        $dockerComposePath = Join-Path $ProjectPath "docker-compose.yml"
        $utf8bom = New-Object System.Text.UTF8Encoding($true)
        [System.IO.File]::WriteAllText($dockerComposePath, $dockerCompose, $utf8bom)
        
        Write-Host "  [OK] Created: docker-compose.yml" -ForegroundColor Green
        
        Write-Host ""
        Write-Host "[3/3] Creating management scripts..." -ForegroundColor Yellow
        
        # Скрипт для запуска с облачной индексацией
        $startScript = @"
# Запуск проектных MCP с облачной индексацией
# После завершения индексации используйте: .\switch-to-local.ps1

Write-Host "Starting $ProjectName MCP servers with CLOUD indexing..." -ForegroundColor Cyan
Write-Host "Model: $CloudModel" -ForegroundColor Yellow
Write-Host ""

# Проверка OPENROUTER_API_KEY
if (-not `$env:OPENROUTER_API_KEY) {
    Write-Host "[ERROR] OPENROUTER_API_KEY not set!" -ForegroundColor Red
    Write-Host "Set it: `$env:OPENROUTER_API_KEY = 'your-key'" -ForegroundColor Yellow
    exit 1
}

docker-compose up -d

Write-Host ""
Write-Host "[OK] MCP servers started" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Wait for indexing to complete (check logs: docker-compose logs -f)" -ForegroundColor White
Write-Host "2. Switch to local model: .\switch-to-local.ps1" -ForegroundColor White
Write-Host "3. Restart Cursor to apply MCP config" -ForegroundColor White
"@
        
        $startScriptPath = Join-Path $ProjectPath "start-mcp-cloud.ps1"
        [System.IO.File]::WriteAllText($startScriptPath, $startScript, $utf8bom)
        
        # Скрипт для переключения на локальную модель
        $switchScript = @"
# Переключение на локальную модель Ollama (qwen3:8b)
# Запускать после завершения облачной индексации

Write-Host "Switching $ProjectName MCP to LOCAL model..." -ForegroundColor Cyan
Write-Host "Model: $LocalModel @ $OllamaHost" -ForegroundColor Yellow
Write-Host ""

Write-Host "[1/3] Stopping containers..." -ForegroundColor Yellow
docker-compose down

Write-Host ""
Write-Host "[2/3] Updating docker-compose.yml..." -ForegroundColor Yellow

`$dockerComposePath = "docker-compose.yml"
`$content = Get-Content `$dockerComposePath -Raw -Encoding UTF8

# Replace cloud model with local
`$content = `$content -replace "EMBEDDING_MODEL=${CloudModel}", "EMBEDDING_MODEL=${LocalModel}"
`$content = `$content -replace "EMBEDDING_PROVIDER=openrouter", "EMBEDDING_PROVIDER=ollama"

`$utf8bom = New-Object System.Text.UTF8Encoding(`$true)
[System.IO.File]::WriteAllText(`$dockerComposePath, `$content, `$utf8bom)

Write-Host "  [OK] Updated to LOCAL model: $LocalModel" -ForegroundColor Green

Write-Host ""
Write-Host "[3/3] Starting with local model..." -ForegroundColor Yellow
docker-compose up -d

Write-Host ""
Write-Host "[OK] Switched to LOCAL model" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Update .cursor\mcp.json (run: manage-project-mcp.ps1 -Action switch-local)" -ForegroundColor White
Write-Host "2. Restart Cursor" -ForegroundColor White
"@
        
        $switchScriptPath = Join-Path $ProjectPath "switch-to-local.ps1"
        [System.IO.File]::WriteAllText($switchScriptPath, $switchScript, $utf8bom)
        
        Write-Host "  [OK] Created: start-mcp-cloud.ps1" -ForegroundColor Green
        Write-Host "  [OK] Created: switch-to-local.ps1" -ForegroundColor Green
        
        Write-Host ""
        Write-Host "=== SETUP COMPLETE ===" -ForegroundColor Green
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Cyan
        Write-Host "1. Export Configuration Report to mcp/base/report/" -ForegroundColor White
        Write-Host "2. Export Extension Report to mcp/ext/report/ (if extensions)" -ForegroundColor White
        Write-Host "3. Run: .\start-mcp-cloud.ps1" -ForegroundColor White
        Write-Host "4. Wait for indexing (check: docker-compose logs -f)" -ForegroundColor White
        Write-Host "5. Switch to local: .\switch-to-local.ps1" -ForegroundColor White
        Write-Host "6. Restart Cursor" -ForegroundColor White
        Write-Host ""
    }
    
    "switch-local" {
        Write-Host "[1/2] Updating MCP config to LOCAL model..." -ForegroundColor Yellow
        
        if (-not (Test-Path $projectMcpJson)) {
            Write-Host "  [FAIL] MCP config not found: $projectMcpJson" -ForegroundColor Red
            exit 1
        }
        
        $config = Get-ProjectMcpConfig -Model $LocalModel -ModelType "local"
        Save-McpConfig -Config $config -Path $projectMcpJson
        
        Write-Host "  [OK] Updated: $projectMcpJson" -ForegroundColor Green
        Write-Host "  [INFO] Using LOCAL model: $LocalModel @ $OllamaHost" -ForegroundColor Cyan
        
        Write-Host ""
        Write-Host "[2/2] Restart Cursor to apply changes" -ForegroundColor Yellow
        Write-Host "  Press Ctrl+Shift+P → 'Reload Window'" -ForegroundColor White
        Write-Host ""
    }
    
    "enable" {
        Write-Host "[INFO] Enabling project MCP servers..." -ForegroundColor Yellow
        
        if (-not (Test-Path $projectMcpJson)) {
            Write-Host "  [FAIL] MCP config not found. Run 'create' first." -ForegroundColor Red
            exit 1
        }
        
        Write-Host "  [OK] MCP config exists: $projectMcpJson" -ForegroundColor Green
        Write-Host "  [INFO] Restart Cursor to enable" -ForegroundColor Cyan
        Write-Host ""
    }
    
    "disable" {
        Write-Host "[INFO] Disabling project MCP servers..." -ForegroundColor Yellow
        
        if (Test-Path $projectMcpJson) {
            # Создаем конфиг только с общими MCP (без проектных)
            $config = @{
                mcpServers = @{
                    "1c-help" = @{
                        url = "http://YOUR_SERVER:8003/mcp"
                        connection_id = "1c_docs_service_001"
                        description = "Справка по платформе 1С:Предприятие 8.3"
                    }
                    "1c-ssl" = @{
                        url = "http://YOUR_SERVER:8008/mcp"
                        connection_id = "1c_ssl_service_001"
                        description = "Справка по БСП 3.1.11"
                    }
                    "1c-templates" = @{
                        url = "http://YOUR_SERVER:8004/mcp"
                        connection_id = "1c_templates_service_001"
                        description = "Шаблоны кода 1С"
                    }
                    "1c-syntax-checker" = @{
                        url = "http://YOUR_SERVER:8002/mcp/"
                        connection_id = "1c_lsp_service_001"
                        description = "Проверка синтаксиса через BSL Language Server"
                    }
                    "1c-code-checker" = @{
                        url = "http://YOUR_SERVER:8007/mcp"
                        connection_id = "1c_code_checker_001"
                        description = "Проверка логики кода через 1С:Напарника"
                    }
                    "1c-forms" = @{
                        url = "http://YOUR_SERVER:8011/mcp"
                        connection_id = "1c_forms_service_001"
                        description = "Контекст для генерации управляемых форм"
                    }
                    "rlm-toolkit" = @{
                        url = "http://YOUR_SERVER:8200/sse"
                        connection_id = "rlm_toolkit_001"
                        description = "RLM-Toolkit: персистентная память"
                    }
                    "bsl-lsp-bridge" = @{
                        type = "stdio"
                        command = "ssh"
                        args = @("YOUR_SERVER", "pct", "exec", "100", "--", "docker", "exec", "-i", "mcp-lsp-home-infra", "mcp-lsp-bridge")
                        connection_id = "bsl_lsp_bridge_001"
                        description = "BSL LSP Bridge: singleton LSP сервер"
                    }
                }
            }
            
            Save-McpConfig -Config $config -Path $projectMcpJson
            Write-Host "  [OK] Disabled project MCP servers" -ForegroundColor Green
            Write-Host "  [INFO] Only common MCP servers remain" -ForegroundColor Cyan
        } else {
            Write-Host "  [INFO] MCP config not found (already disabled)" -ForegroundColor Yellow
        }
        
        Write-Host "  [INFO] Restart Cursor to apply changes" -ForegroundColor Cyan
        Write-Host ""
    }
    
    "status" {
        Write-Host "[INFO] Checking MCP status..." -ForegroundColor Yellow
        Write-Host ""
        
        if (Test-Path $projectMcpJson) {
            $config = Get-Content $projectMcpJson -Raw -Encoding UTF8 | ConvertFrom-Json
            $projectServers = $config.mcpServers.PSObject.Properties | Where-Object { $_.Name -like "$mcpId-*" }
            
            if ($projectServers) {
                Write-Host "  [OK] Project MCP servers ENABLED:" -ForegroundColor Green
                foreach ($server in $projectServers) {
                    Write-Host "    - $($server.Name): $($server.Value.url)" -ForegroundColor White
                }
            } else {
                Write-Host "  [INFO] Project MCP servers DISABLED" -ForegroundColor Yellow
                Write-Host "    Only common MCP servers active" -ForegroundColor White
            }
        } else {
            Write-Host "  [INFO] No MCP config found" -ForegroundColor Yellow
            Write-Host "    Using global ~/.cursor/mcp.json" -ForegroundColor White
        }
        
        Write-Host ""
        Write-Host "Docker containers:" -ForegroundColor Cyan
        Push-Location $ProjectPath
        docker-compose ps 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  [INFO] No docker-compose.yml or containers not running" -ForegroundColor Yellow
        }
        Pop-Location
        Write-Host ""
    }
}
