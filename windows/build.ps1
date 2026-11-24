$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$srcDir = Join-Path $PSScriptRoot "src"
$assets = Join-Path $root "assets"
$dist = Join-Path $PSScriptRoot "dist"

$csc = Join-Path $env:WINDIR "Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if (-not (Test-Path $csc)) {
    $csc = Join-Path $env:WINDIR "Microsoft.NET\Framework\v4.0.30319\csc.exe"
}
if (-not (Test-Path $csc)) {
    throw "C# compiler not found. GearLab targets the .NET Framework 4.8 that ships with Windows."
}

New-Item -ItemType Directory -Force $dist | Out-Null
$sources = Get-ChildItem (Join-Path $srcDir "*.cs") | ForEach-Object { $_.FullName }
$resources = @()
Get-ChildItem (Join-Path $assets "cameras\*.png") | ForEach-Object {
    $resources += "/resource:$($_.FullName),GearLab.Resources.cameras.$($_.Name)"
}
Get-ChildItem (Join-Path $assets "samples\*.jpg") | ForEach-Object {
    $resources += "/resource:$($_.FullName),GearLab.Resources.samples.$($_.Name)"
}

$common = @(
    "/nologo",
    "/platform:anycpu",
    "/optimize+",
    "/codepage:65001",
    "/langversion:5",
    "/win32icon:$(Join-Path $assets 'app.ico')",
    "/win32manifest:$(Join-Path $PSScriptRoot 'assets\app.manifest')",
    "/r:System.dll",
    "/r:System.Core.dll",
    "/r:System.Drawing.dll",
    "/r:System.Windows.Forms.dll"
)

$guiArgs = @("/target:winexe", "/main:GearLab.Program", "/out:$(Join-Path $dist 'GearLab.exe')") + $common + $resources + $sources
$cliArgs = @("/target:exe", "/main:GearLab.Cli", "/out:$(Join-Path $dist 'GearLabCLI.exe')") + $common + $resources + $sources

& $csc $guiArgs
if ($LASTEXITCODE -ne 0) { throw "GearLab GUI build failed." }
& $csc $cliArgs
if ($LASTEXITCODE -ne 0) { throw "GearLab CLI build failed." }

Write-Host "Built:" (Join-Path $dist "GearLab.exe")
Write-Host "Built:" (Join-Path $dist "GearLabCLI.exe")
