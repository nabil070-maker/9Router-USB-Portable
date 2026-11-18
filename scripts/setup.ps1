param([switch]$Update)
$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'
$Root    = Split-Path -Parent $PSScriptRoot
$NodeVer = '26.13.1'   # latest Node.js LTS ("Lithium") as of Nov 2026

foreach ($d in 'runtime','app\npm','data','cache\npm','temp','home\AppData\Roaming','home\AppData\Local') {
    New-Item -ItemType Directory -Force -Path (Join-Path $Root $d) | Out-Null
}

$arch    = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'arm64' } else { 'x64' }
$nodeDir = Join-Path $Root 'runtime\node'

if (-not (Test-Path "$nodeDir\node.exe")) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $name = "node-v$NodeVer-win-$arch"
    $zip  = Join-Path $Root "temp\$name.zip"
    Write-Host "Downloading Node $NodeVer ($arch)..."
    Invoke-WebRequest "https://nodejs.org/dist/v$NodeVer/$name.zip" -OutFile $zip -UseBasicParsing

    # Verify the download against nodejs.org's published checksums
    $c = (Invoke-WebRequest "https://nodejs.org/dist/v$NodeVer/SHASUMS256.txt" -UseBasicParsing).Content
    if ($c -is [byte[]]) { $c = [Text.Encoding]::UTF8.GetString($c) }
    $line = ($c -split "`n") | Where-Object { $_ -match "\s$([regex]::Escape($name)).zip\s*$" } | Select-Object -First 1
    if ($line) {
        $expected = ($line.Trim() -split '\s+')[0].ToLower()
        $actual   = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
        if ($actual -ne $expected) { Remove-Item $zip -Force; throw "Node download checksum mismatch" }
    } else { Write-Warning "No published checksum found for $name.zip; skipping verification" }

    Expand-Archive $zip -DestinationPath (Join-Path $Root 'temp') -Force
    if (Test-Path $nodeDir) { Remove-Item $nodeDir -Recurse -Force }
    Move-Item (Join-Path $Root "temp\$name") $nodeDir
    Remove-Item $zip -Force
}

# Keep npm and 9router's runtime entirely inside the folder
$home_ = Join-Path $Root 'home'
$env:PATH                       = "$nodeDir;$env:PATH"
$env:USERPROFILE                = $home_
$env:HOME                       = $home_
$env:APPDATA                    = Join-Path $home_ 'AppData\Roaming'
$env:LOCALAPPDATA               = Join-Path $home_ 'AppData\Local'
$env:TEMP                       = Join-Path $Root 'temp'
$env:TMP                        = $env:TEMP
$env:DATA_DIR                   = Join-Path $Root 'data'
$env:npm_config_prefix          = Join-Path $Root 'app\npm'
$env:npm_config_cache           = Join-Path $Root 'cache\npm'
$env:npm_config_update_notifier = 'false'
$env:npm_config_fund            = 'false'

if ($Update -or -not (Test-Path (Join-Path $Root 'app\npm\9router.cmd'))) {
    Write-Host "Installing 9router..."
    & "$nodeDir\npm.cmd" install -g 9router@latest
    if ($LASTEXITCODE -ne 0) { throw "npm install failed" }
}

# Disable a crashing better-sqlite3 native binary if this PC has one
& "$nodeDir\node.exe" (Join-Path $PSScriptRoot 'sqlite-guard.js')

# Default dashboard password (edit data\initial-password.txt to change it)
$pw = Join-Path $Root 'data\initial-password.txt'
if (-not (Test-Path $pw)) {
    Set-Content -Path $pw -Value '123456' -Encoding ASCII -NoNewline
}
Write-Host "Setup complete."
