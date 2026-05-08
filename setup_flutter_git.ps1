Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  MINDLOCK - Reliable Flutter Setup" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Removing corrupted zip files..." -ForegroundColor Yellow

if (Test-Path "C:\flutter\flutter.zip") { Remove-Item "C:\flutter\flutter.zip" -Force }
if (Test-Path "C:\flutter\flutter") { Remove-Item "C:\flutter\flutter" -Recurse -Force }

if (-not (Test-Path "C:\flutter")) { New-Item -ItemType Directory -Path "C:\flutter" | Out-Null }

Write-Host "Downloading Flutter via Git (Fast & Reliable)..." -ForegroundColor Yellow
cd "C:\flutter"
git clone https://github.com/flutter/flutter.git -b stable

$flutterBin = "C:\flutter\flutter\bin\flutter.bat"
$env:Path += ";C:\flutter\flutter\bin"
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\flutter\flutter\bin", [EnvironmentVariableTarget]::User)

Write-Host "`nSetting up dependencies for MINDLOCK..." -ForegroundColor Yellow
cd "d:\DEV\projects\COSTOM REMINDER\FocusLock"
& $flutterBin pub get
& $flutterBin pub run build_runner build --delete-conflicting-outputs
& $flutterBin pub run flutter_launcher_icons

Write-Host "`n======================================" -ForegroundColor Green
Write-Host "  SETUP COMPLETE! 🚀" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host "Connect your phone, and run this command:" -ForegroundColor Cyan
Write-Host "flutter run" -ForegroundColor White
