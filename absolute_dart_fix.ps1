Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  MINDLOCK - ABSOLUTE DART FIX" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

$engineVersion = Get-Content "C:\flutter\flutter\bin\internal\engine.version"
$dartZipUrl = "https://storage.googleapis.com/flutter_infra_release/flutter/$engineVersion/dart-sdk-windows-x64.zip"
$zipPath = "C:\flutter\dart-sdk.zip"
$cachePath = "C:\flutter\flutter\bin\cache"
$dartSdkPath = "$cachePath\dart-sdk"

Write-Host "1. Downloading Dart SDK (CURL)..." -ForegroundColor Yellow
if (Test-Path $dartSdkPath) { Remove-Item $dartSdkPath -Recurse -Force }
if (-not (Test-Path $cachePath)) { New-Item -ItemType Directory -Path $cachePath | Out-Null }

if (-not (Test-Path $zipPath)) {
    curl.exe -L -o $zipPath -# $dartZipUrl
} else {
    Write-Host "Zip file already exists! Skipping download." -ForegroundColor Green
}

Write-Host "`n2. Extracting Dart SDK..." -ForegroundColor Yellow
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $cachePath)

Write-Host "3. Writing exact Engine Version Stamp..." -ForegroundColor Yellow
# EXACT MATCH REQUIRED FOR FLUTTER ENGINE
[IO.File]::WriteAllText("$cachePath\engine.stamp", $engineVersion)
[IO.File]::WriteAllText("$cachePath\engine-dart-sdk.stamp", $engineVersion)

Write-Host "`nSetting up dependencies for MINDLOCK..." -ForegroundColor Yellow
cd "d:\DEV\projects\COSTOM REMINDER\FocusLock"
$flutterBin = "C:\flutter\flutter\bin\flutter.bat"
& $flutterBin pub get
& $flutterBin pub run build_runner build --delete-conflicting-outputs
& $flutterBin pub run flutter_launcher_icons

Write-Host "`n======================================" -ForegroundColor Green
Write-Host "  ALL SET! 🚀" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host "flutter run" -ForegroundColor White
