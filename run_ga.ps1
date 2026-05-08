param(
    [string]$BaseDir = "BASE",
    [string]$RootOutputDir = "RESULTS\GA",
    [string]$Executable = "GA/main.jl",
    [string]$JuliaThreads = "auto",
    [string]$JuliaDepotPath = "",
    [int]$Seed = 1234,
    [int]$PopFactor = 2,
    [double]$CrossoverRate = 0.90,
    [double]$MutationRate = 0.20,
    [double]$ElitismRate = 0.10,
    [int]$MaxGen = 200,
    [int]$MaxStagnation = 100,
    [int]$Trials = 30
)

$ErrorActionPreference = "Stop"

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message"
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Run {
    param([string]$Message)
    Write-Host "[RUN ] $Message"
}

function Write-Skip {
    param([string]$Message)
    Write-Host "[SKIP] $Message" -ForegroundColor DarkGray
}

function Get-RelativePathCompat {
    param(
        [string]$BasePath,
        [string]$TargetPath
    )

    if (-not $BasePath.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
        $BasePath = $BasePath + [System.IO.Path]::DirectorySeparatorChar
    }

    $baseUri = New-Object System.Uri($BasePath)
    $targetUri = New-Object System.Uri($TargetPath)
    $relativeUri = $baseUri.MakeRelativeUri($targetUri)
    return [System.Uri]::UnescapeDataString($relativeUri.ToString()).Replace('/', [System.IO.Path]::DirectorySeparatorChar)
}

if (-not (Test-Path -LiteralPath $BaseDir -PathType Container)) {
    throw "[ERRO] Pasta '$BaseDir' nao existe."
}

if (-not (Test-Path -LiteralPath $Executable -PathType Leaf)) {
    throw "[ERRO] Arquivo '$Executable' nao encontrado. Ajuste -Executable no script."
}

$juliaCmd = Get-Command julia -ErrorAction SilentlyContinue
$juliaCandidates = Get-ChildItem -Path "$HOME\.julia\juliaup" -Recurse -Filter "julia.exe" -ErrorAction SilentlyContinue |
    Sort-Object FullName -Descending

if ($juliaCmd -and ($juliaCmd.Source -notlike "*\Microsoft\WindowsApps\*")) {
    $juliaExe = $juliaCmd.Source
} elseif ($juliaCandidates) {
    $juliaExe = $juliaCandidates[0].FullName

    if ($juliaCmd) {
        Write-Warn "PATH aponta para o alias '$($juliaCmd.Source)'; usando '$juliaExe'."
    } else {
        Write-Warn "Julia nao encontrado no PATH; usando '$juliaExe'."
    }
} else {
    throw "[ERRO] Julia nao encontrado no PATH nem em '$HOME\.julia\juliaup'. Instale Julia ou adicione julia.exe ao PATH."
}

if (-not $env:JULIA_HISTORY) {
    $env:JULIA_HISTORY = Join-Path (Get-Location) ".julia_history"
}

if ([string]::IsNullOrWhiteSpace($JuliaDepotPath)) {
    Remove-Item Env:JULIA_DEPOT_PATH -ErrorAction SilentlyContinue
} else {
    $env:JULIA_DEPOT_PATH = $JuliaDepotPath
}

New-Item -ItemType Directory -Path $RootOutputDir -Force | Out-Null

Write-Info "BASE_DIR       = $BaseDir"
Write-Info "OUTPUT_DIR     = $RootOutputDir"
Write-Info "EXECUTABLE     = $Executable"
Write-Info "JULIA_EXE      = $juliaExe"
Write-Info "JULIA_THREADS  = $JuliaThreads"
if ($env:JULIA_DEPOT_PATH) {
    Write-Info "JULIA_DEPOT    = $env:JULIA_DEPOT_PATH"
} else {
    Write-Info "JULIA_DEPOT    = <default>"
}
Write-Info "Params: seed=$Seed pop_factor=$PopFactor cx=$CrossoverRate mut=$MutationRate elit=$ElitismRate gen=$MaxGen stagnation=$MaxStagnation trials=$Trials"
Write-Host ""

$startAll = Get-Date
$total = 0
$skipped = 0
$processed = 0

$instances = Get-ChildItem -LiteralPath $BaseDir -Recurse -File -Filter "*.txt" |
    ForEach-Object {
        [PSCustomObject]@{
            File = $_
            Lines = (Get-Content -LiteralPath $_.FullName | Measure-Object -Line).Lines
        }
    } |
    Sort-Object Lines, { $_.File.FullName }

if (-not $instances) {
    Write-Warn "Nenhuma instancia .txt encontrada em '$BaseDir'."
    exit 0
}

$baseFullPath = (Resolve-Path -LiteralPath $BaseDir).Path

foreach ($item in $instances) {
    $total++

    $instanceFullPath = $item.File.FullName
    $relativePath = Get-RelativePathCompat $baseFullPath $instanceFullPath
    $relativeDir = [System.IO.Path]::GetDirectoryName($relativePath)
    $instanceStem = [System.IO.Path]::GetFileNameWithoutExtension($instanceFullPath)

    if ([string]::IsNullOrWhiteSpace($relativeDir)) {
        $outDir = $RootOutputDir
    } else {
        $outDir = Join-Path $RootOutputDir $relativeDir
    }

    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    $outCsv = Join-Path $outDir "$instanceStem.csv"

    if (Test-Path -LiteralPath $outCsv -PathType Leaf) {
        Write-Skip "$relativePath (csv ja existe)"
        $skipped++
        continue
    }

    Write-Run "$relativePath (linhas=$($item.Lines))"
    Write-Host "      -> $outCsv"

    & $juliaExe --project=. --threads $JuliaThreads $Executable `
        --instance $instanceFullPath `
        --seed $Seed `
        --pop_factor $PopFactor `
        --crossover_rate $CrossoverRate `
        --mutation_rate $MutationRate `
        --elitism_rate $ElitismRate `
        --max_gen $MaxGen `
        --max_stagnation $MaxStagnation `
        --trials $Trials `
        --output $outCsv

    if ($LASTEXITCODE -ne 0) {
        throw "[ERRO] Julia retornou codigo $LASTEXITCODE ao processar '$relativePath'."
    }

    $processed++
}

$elapsed = [int]((Get-Date) - $startAll).TotalSeconds

Write-Host ""
Write-Host "[DONE] total=$total processed=$processed skipped=$skipped elapsed_sec=$elapsed"
