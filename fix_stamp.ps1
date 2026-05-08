Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  MINDLOCK - Stamp Fix" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

$engineVersion = Get-Content "C:\flutter\flutter\bin\internal\engine.version"
$zipPath = "C:\flutter\dart-sdk.zip"
$cachePath = "C:\flutter\flutter\bin\cache"
$dartSdkPath = "$cachePath\dart-sdk"

Write-Host "Extracting previously downloaded Dart SDK..." -ForegroundColor Yellow
if (Test-Path $dartSdkPath) { Remove-Item $dartSdkPath -Recurse -Force }
if (-not (Test-Path $cachePath)) { New-Item -ItemType Directory -Path $cachePath | Out-Null }

Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $cachePath)

Write-Host "Applying correct version stamp ($engineVersion)..." -ForegroundColor Yellow
# EXACT MATCH REQUIRED FOR FLUTTER ENGINE
[IO.File]::WriteAllText("$cachePath\dart-sdk.stamp", $engineVersion)

Write-Host "`nSetting up dependencies for MINDLOCK..." -ForegroundColor Yellow
cd "d:\DEV\projects\COSTOM REMINDER\FocusLock"
$flutterBin = "C:\flutter\flutter\bin\flutter.bat"
& $flutterBin pub get
& $flutterBin pub run build_runner build --delete-conflicting-outputs
& $flutterBin pub run flutter_launcher_icons

Write-Host "`n======================================" -ForegroundColor Green
Write-Host "  ALL SET! 🚀" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host "Connect your phone, and run this command:" -ForegroundColor Cyan
Write-Host "flutter run" -ForegroundColor White
