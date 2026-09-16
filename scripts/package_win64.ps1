# Mistspire — package Win64 standalone build on Windows.
#Requires -Version 5.1
param(
    [ValidateSet("Development", "Shipping")]
    [string]$Configuration = "Development",

    [string]$PackageRoot = "",
    [switch]$NoBuild,
    [switch]$Clean
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

Write-Host "============================================"
Write-Host "  Mistspire — Package Win64 ($Configuration)"
Write-Host "============================================"

# Locate Unreal Engine 5.8
$ueCandidates = @(
    "$env:ProgramFiles\Epic Games\UE_5.8",
    "C:\UE_5.8",
    "$env:LOCALAPPDATA\Programs\Epic Games\UE_5.8"
)
if ($env:UE_ROOT) {
    $ueCandidates = @($env:UE_ROOT) + $ueCandidates
}

$UERoot = $null
foreach ($c in $ueCandidates) {
    $uatCandidate = Join-Path $c "Engine\Build\BatchFiles\RunUAT.bat"
    if (Test-Path $uatCandidate) {
        $UERoot = $c
        break
    }
}

if (-not $UERoot) {
    Write-Host "!! Unreal Engine 5.8 RunUAT not found."
    Write-Host "   Set UE_ROOT or install UE 5.8 via Epic Games Launcher."
    exit 1
}

$RunUAT = Join-Path $UERoot "Engine\Build\BatchFiles\RunUAT.bat"
$UProject = Join-Path $Root "game\Mistspire.uproject"

if (-not $PackageRoot) {
    $PackageRoot = Join-Path $Root "game\Package\Win64"
}

Write-Host "Engine:  $UERoot"
Write-Host "Project: $UProject"
Write-Host "Config:  $Configuration"
Write-Host "Output:  $PackageRoot"
Write-Host ""

$UATArgs = @(
    "BuildCookRun",
    "-project=$UProject",
    "-platform=Win64",
    "-clientconfig=$Configuration",
    "-map=/Game/Maps/Main_WP",
    "-cook",
    "-stage",
    "-pak",
    "-archive",
    "-archivedirectory=$PackageRoot",
    "-nop4",
    "-utf8output"
)

if (-not $NoBuild) {
    $UATArgs += "-build"
}

if ($Clean) {
    $UATArgs += "-clean"
}

Write-Host "==> Running RunUAT BuildCookRun..."
Write-Host "    $RunUAT $($UATArgs -join ' ')"
Write-Host ""

& $RunUAT @UATArgs

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "!! RunUAT packaging failed with exit code $LASTEXITCODE."
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "============================================"
Write-Host "  Packaging complete!"
Write-Host "============================================"
Write-Host "Launch packaged demo build:"
Write-Host "  .\scripts\launch_packaged_win64.ps1"
Write-Host "  or: .\run.ps1 packaged"
Write-Host ""

exit 0
