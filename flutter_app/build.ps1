param(
    [switch]$SkipWindows,
    [switch]$SkipAndroid
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $PSScriptRoot

if (-not $SkipWindows) {
    flutter build windows --release
}

if (-not $SkipAndroid) {
    flutter build apk --release
}

$dist = Join-Path $root 'dist'
New-Item -ItemType Directory -Force $dist | Out-Null

if (-not $SkipWindows) {
    $stage = Join-Path $dist 'GearLab-Windows-2.0.0'
    Remove-Item $stage -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Force $stage | Out-Null
    Copy-Item 'build\windows\x64\runner\Release\*' $stage -Recurse -Force
    Rename-Item (Join-Path $stage 'gearlab.exe') 'GearLab.exe'
    Copy-Item 'README.md' $stage
    Copy-Item (Join-Path $root 'LICENSES.md') (Join-Path $stage 'LICENSES.md')
    Compress-Archive -Path (Join-Path $stage '*') -DestinationPath (Join-Path $dist 'GearLab-Flutter-Windows-2.0.0.zip') -Force
}

if (-not $SkipAndroid) {
    Copy-Item 'build\app\outputs\flutter-apk\app-release.apk' (Join-Path $dist 'GearLab-Android-2.0.0.apk') -Force
}

Write-Host 'Build complete. See dist/'
