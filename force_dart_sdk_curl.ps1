Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  MINDLOCK - CURL Dart SDK Fix" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

$engineVersion = Get-Content "C:\flutter\flutter\bin\internal\engine.version"
$dartZipUrl = "https://storage.googleapis.com/flutter_infra_release/flutter/$engineVersion/dart-sdk-windows-x64.zip"
$zipPath = "C:\flutter\dart-sdk.zip"
$cachePath = "C:\flutter\flutter\bin\cache"
$dartSdkPath = "$cachePath\dart-sdk"

Write-Host "Downloading Dart SDK using CURL (Native Network Stack)..." -ForegroundColor Yellow

if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
if (Test-Path $dartSdkPath) { Remove-Item $dartSdkPath -Recurse -Force }
if (-not (Test-Path $cachePath)) { New-Item -ItemType Directory -Path $cachePath | Out-Null }

# Use native curl to bypass PowerShell network issues
curl.exe -L -o $zipPath -# $dartZipUrl

Write-Host "`nDownload complete. Extracting..." -ForegroundColor Yellow
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $cachePath)

New-Item -ItemType File -Path "$cachePath\dart-sdk.stamp" -Force | Out-Null
Remove-Item $zipPath -Force

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
