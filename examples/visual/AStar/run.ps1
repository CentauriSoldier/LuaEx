$ErrorActionPreference = 'Stop'
$taskRepoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
$taskBudo = Join-Path $taskRepoRoot 'Budo/budo.exe'
if (-not (Test-Path -LiteralPath $taskBudo)) { throw "Budo not found at $taskBudo" }
New-Item -ItemType Directory -Path (Join-Path $PSScriptRoot 'saved') -Force | Out-Null
Push-Location $taskRepoRoot
try {
    & $taskBudo run $PSScriptRoot --width 1120 --height 800 --title 'LuaEx AStar laboratory' --file-root (Join-Path $PSScriptRoot 'saved')
} finally { Pop-Location }
