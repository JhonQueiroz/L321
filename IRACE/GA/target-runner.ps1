param(
    [string]$CandidateId,
    [string]$InstanceId,
    [int]$Seed,
    [string]$Instance,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ParameterArgs
)

$ErrorActionPreference = "Stop"

function Resolve-RunnerPath {
    param([string]$Path)

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return (Resolve-Path -LiteralPath $Path).Path
    }

    return (Resolve-Path -LiteralPath (Join-Path $script:ScriptDir $Path)).Path
}

function Get-JuliaExe {
    $juliaCmd = Get-Command julia -ErrorAction SilentlyContinue
    if ($juliaCmd -and ($juliaCmd.Source -notlike "*\Microsoft\WindowsApps\*")) {
        return $juliaCmd.Source
    }

    $candidate = Get-ChildItem -Path "$HOME\.julia\juliaup" -Recurse -Filter "julia.exe" -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending |
        Select-Object -First 1

    if ($candidate) {
        return $candidate.FullName
    }

    throw "Julia not found."
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = (Resolve-Path -LiteralPath (Join-Path $ScriptDir "..\..")).Path
$InstancePath = Resolve-RunnerPath $Instance
$JuliaExe = Get-JuliaExe

$RunDir = Join-Path $ScriptDir "runs"
New-Item -ItemType Directory -Path $RunDir -Force | Out-Null

$safeId = "$CandidateId-$InstanceId-$Seed" -replace "[^A-Za-z0-9_.-]", "_"
$OutputCsv = Join-Path $RunDir "$safeId.csv"
$OutputCurve = Join-Path $RunDir "$safeId`_curve.csv"
$LogFile = Join-Path $RunDir "$safeId.log"

Remove-Item -LiteralPath $OutputCsv, $OutputCurve, $LogFile -ErrorAction SilentlyContinue

$juliaArgs = @(
    "--project=.",
    "--threads", "auto",
    "GA/main.jl",
    "--instance", $InstancePath,
    "--seed", $Seed,
    "--max_gen", "200",
    "--trials", "1",
    "--output", $OutputCsv
) + $ParameterArgs

Push-Location $ProjectRoot
try {
    & $JuliaExe @juliaArgs *> $LogFile
    if ($LASTEXITCODE -ne 0) {
        throw "Julia returned exit code $LASTEXITCODE. See $LogFile"
    }
} finally {
    Pop-Location
}

$result = Import-Csv -LiteralPath $OutputCsv | Select-Object -First 1
[Console]::Out.WriteLine($result.bestSpan)
