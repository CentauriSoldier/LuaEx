param(
    [string]$Lua = 'C:\Users\CS\Sync\Portable Apps\Libraries\Lua\5.4\lua54.exe',
    [string]$NativeModule = "$env:TEMP\LuaEx-native-prototype-build-msvc\Release\lxc_native.dll",
    [string]$HybridModule = "$env:TEMP\LuaEx-hybrid-build-msvc\Release\lxc_hybrid.dll",
    [int]$Runs = 3
)
$ErrorActionPreference = 'Stop'
if ($Runs -lt 1) { throw 'Runs must be positive.' }
$repository = (Resolve-Path -LiteralPath "$PSScriptRoot\..\..\..").Path
$output = Join-Path $env:TEMP ('LuaExLegacyComparison-' + [guid]::NewGuid().ToString('N'))
$historical = Join-Path $output 'historical'
New-Item -ItemType Directory -Path $historical -Force | Out-Null
$archive = Join-Path $output 'historical.tar'
& git -C $repository archive --format=tar --output=$archive 82cb8432961c4c4e866a70293ffd4084f74c15c2
if ($LASTEXITCODE -ne 0) { throw 'Historical archive failed.' }
& tar -xf $archive -C $historical
if ($LASTEXITCODE -ne 0) { throw 'Historical extraction failed.' }
$previousModule = $env:LXC_NATIVE_MODULE
$previousHybrid = $env:LXC_HYBRID_MODULE
$previousBackend = $env:LXC_NATIVE_BACKEND
try {
    $env:LXC_NATIVE_MODULE = $NativeModule
    $env:LXC_HYBRID_MODULE = $HybridModule
    $env:LXC_NATIVE_BACKEND = 'lua'
    Push-Location $repository
    try {
        & $Lua "$PSScriptRoot\test.lua" *> (Join-Path $output 'native-checks.txt')
        if ($LASTEXITCODE -ne 0) { throw "Native checks failed. See $output" }
        foreach ($mode in @('lua', 'native')) {
            $env:LXC_NATIVE_BACKEND = $mode
            & $Lua "$repository\dev\tests\native_lxc_regression.lua" *> (Join-Path $output "hybrid-checks-$mode.txt")
            if ($LASTEXITCODE -ne 0) { throw "Hybrid checks failed. See $output" }
        }
    } finally { Pop-Location }
    for ($run = 1; $run -le $Runs; $run++) {
        $order = if ($run % 2) { @('legacy', 'current', 'hybrid') } else { @('hybrid', 'current', 'legacy') }
        foreach ($backend in $order) {
            $directory = if ($backend -eq 'legacy') { $historical } else { $repository }
            Push-Location $directory
            try {
                $log = Join-Path $output "$backend-$run.txt"
                $env:LXC_NATIVE_BACKEND = if ($backend -eq 'hybrid') { 'native' } else { 'lua' }
                if ($backend -eq 'legacy') {
                    & $Lua "$PSScriptRoot\legacy-benchmark.lua" "$PSScriptRoot\benchmark.lua" *> $log
                } elseif ($backend -eq 'hybrid') {
                    & $Lua "$PSScriptRoot\hybrid-benchmark.lua" *> $log
                } elseif ($run % 2) {
                    & $Lua "$PSScriptRoot\benchmark.lua" *> $log
                } else {
                    & $Lua "$PSScriptRoot\benchmark.lua" --native-first *> $log
                }
                if ($LASTEXITCODE -ne 0) { throw "Benchmark failed. See $log" }
            } finally { Pop-Location }
        }
    }
    $rows = foreach ($log in Get-ChildItem -LiteralPath $output -Filter '*.txt') {
        foreach ($line in Get-Content -LiteralPath $log.FullName) {
            if ($line -match '^RESULT\s+([^/]+)/([^\s]+)\s+(\d+)\s+([\d.]+)\s+([\d.]+)') {
                [pscustomobject]@{Backend=$Matches[1]; Workload=$Matches[2]; OpsPerSecond=[double]::Parse($Matches[5], [cultureinfo]::InvariantCulture)}
            }
        }
    }
    $rows | Export-Csv -LiteralPath (Join-Path $output 'samples.csv') -NoTypeInformation
    $medians = $rows | Group-Object Backend, Workload | ForEach-Object {
        $values = @($_.Group.OpsPerSecond | Sort-Object)
        $middle = [int][math]::Floor($values.Count / 2)
        $median = if ($values.Count % 2) { $values[$middle] } else { ($values[$middle - 1] + $values[$middle]) / 2 }
        [pscustomobject]@{Backend=$_.Group[0].Backend; Workload=$_.Group[0].Workload; MedianOpsPerSecond=$median}
    }
    $medians | Export-Csv -LiteralPath (Join-Path $output 'medians.csv') -NoTypeInformation
    $medians | Sort-Object Workload, Backend | Format-Table -AutoSize
    Write-Output "Logs: $output"
} finally {
    $env:LXC_NATIVE_MODULE = $previousModule
    $env:LXC_HYBRID_MODULE = $previousHybrid
    $env:LXC_NATIVE_BACKEND = $previousBackend
}
