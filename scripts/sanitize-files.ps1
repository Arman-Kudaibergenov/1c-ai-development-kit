# Sanitize files - remove private information

$replacements = @{
    # IP addresses (http:// variants first, then bare IPs)
    'http://192\.168\.0\.101' = 'http://YOUR_SERVER'
    'http://192\.168\.0\.105' = 'http://YOUR_SERVER'
    'http://192\.168\.0\.106' = 'http://YOUR_SERVER'
    'http://192\.168\.0\.107' = 'http://YOUR_SERVER'
    'http://192\.168\.0\.108' = 'http://YOUR_SERVER'
    'http://192\.168\.0\.109' = 'http://YOUR_SERVER'
    'http://192\.168\.0\.111' = 'http://YOUR_SERVER'
    '192\.168\.0\.99'  = 'YOUR_PROXMOX_HOST'
    '192\.168\.0\.101' = 'YOUR_SERVER'
    '192\.168\.0\.105' = 'YOUR_MCP_SERVER'
    '192\.168\.0\.106' = 'YOUR_RLM_SERVER'
    '192\.168\.0\.107' = 'YOUR_SERVER'
    '192\.168\.0\.108' = 'YOUR_OLLAMA_SERVER'
    '192\.168\.0\.109' = 'YOUR_RLM_HOST'
    '192\.168\.0\.111' = 'YOUR_MCP_SERVER'

    # Project-specific MCP servers
    'user-kaf-codemetadata-codesearch'    = 'user-PROJECT-codemetadata-codesearch'
    'user-kaf-codemetadata-metadatasearch' = 'user-PROJECT-codemetadata-metadatasearch'
    'user-kaf-graph-cypher'  = 'user-PROJECT-graph-cypher'
    'kaf-codemetadata'       = 'PROJECT-codemetadata'
    'kaf-graph'              = 'PROJECT-graph'
    'minimkg-enhanced'       = 'PROJECT-codemetadata'

    # Paths
    '(?i)C:\\Users\\Arman' = 'C:\Users\YOUR_USERNAME'
    '/home/arman'          = '/home/YOUR_USERNAME'

    # Infrastructure
    'CT 100' = 'CT XXX'
    'CT 104' = 'CT XXX'
    'CT 105' = 'CT XXX'
    'CT 106' = 'CT XXX'
    'CT 108' = 'CT XXX'
    'LXC 100' = 'LXC XXX'
    'LXC 104' = 'LXC XXX'
    'LXC 105' = 'LXC XXX'
    'LXC 106' = 'LXC XXX'
    'LXC 108' = 'LXC XXX'
    'homeserver' = 'YOUR_SERVER'
}

# Collect ALL text files that may contain private data
$files = @()

# Cursor files
$files += Get-ChildItem ".cursor\agents\*.md" -Recurse -ErrorAction SilentlyContinue
$files += Get-ChildItem ".cursor\rules\*.mdc" -Recurse -ErrorAction SilentlyContinue
$files += Get-ChildItem ".cursor\skills\*.md" -Recurse -ErrorAction SilentlyContinue
$files += Get-ChildItem ".cursor\skills\*.ps1" -Recurse -ErrorAction SilentlyContinue
$files += Get-ChildItem ".cursor\skills\*.txt" -Recurse -ErrorAction SilentlyContinue
$files += Get-ChildItem ".cursor\skills\*.json" -Recurse -ErrorAction SilentlyContinue
$files += Get-ChildItem ".cursor\commands\*.md" -Recurse -ErrorAction SilentlyContinue
$files += Get-ChildItem ".cursor\mcp.json" -ErrorAction SilentlyContinue

# Claude Code files
$files += Get-ChildItem ".claude\skills\*.md" -Recurse -ErrorAction SilentlyContinue
$files += Get-ChildItem ".claude\skills\*.ps1" -Recurse -ErrorAction SilentlyContinue
$files += Get-ChildItem ".claude\docs\*.md" -Recurse -ErrorAction SilentlyContinue

# Root files
$files += Get-ChildItem "CLAUDE.md" -ErrorAction SilentlyContinue
$files += Get-ChildItem ".mcp.json" -ErrorAction SilentlyContinue
$files += Get-ChildItem "README.md" -ErrorAction SilentlyContinue
$files += Get-ChildItem "PROJECT_SUMMARY.md" -ErrorAction SilentlyContinue
$files += Get-ChildItem "PUBLISH_*.md" -ErrorAction SilentlyContinue
$files += Get-ChildItem "CAPABILITIES.md" -ErrorAction SilentlyContinue
$files += Get-ChildItem "DEPLOYMENT.md" -ErrorAction SilentlyContinue
$files += Get-ChildItem "UPDATE_SUMMARY.md" -ErrorAction SilentlyContinue

# Docs
$files += Get-ChildItem "docs\*.md" -Recurse -ErrorAction SilentlyContinue

$sanitized = 0

Write-Host "Processing $($files.Count) files..."

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    $modified = $false

    foreach ($pattern in $replacements.Keys) {
        if ($content -match $pattern) {
            $content = $content -replace $pattern, $replacements[$pattern]
            $modified = $true
        }
    }

    if ($modified) {
        Set-Content $file.FullName -Value $content -Encoding UTF8 -NoNewline
        Write-Host "  Sanitized: $($file.FullName)"
        $sanitized++
    }
}

# Verification: check for remaining private data
Write-Host ""
Write-Host "Verification - checking for remaining private data..."
$leaks = 0

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    if ($content -match '192\.168\.0\.\d+') {
        Write-Host "  WARNING: IP address found in $($file.FullName)" -ForegroundColor Red
        $leaks++
    }
    if ($content -match '(?i)C:\\Users\\Arman') {
        Write-Host "  WARNING: User path found in $($file.FullName)" -ForegroundColor Red
        $leaks++
    }
    if ($content -match '(?i)\bhomeserver\b') {
        Write-Host "  WARNING: Hostname found in $($file.FullName)" -ForegroundColor Red
        $leaks++
    }
}

if ($leaks -eq 0) {
    Write-Host "  All clean!" -ForegroundColor Green
} else {
    Write-Host "  $leaks leak(s) remaining - manual review needed" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Done! Sanitized $sanitized file(s)."
