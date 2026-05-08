Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  MINDLOCK - Flutter Speed Fix" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

# Set fast mirror URLs for Flutter
$env:PUB_HOSTED_URL = "https://pub.flutter-io.cn"
$env:FLUTTER_STORAGE_BASE_URL = "https://storage.flutter-io.cn"

# Add Flutter to path for this session
$env:Path += ";C:\flutter\flutter\bin"

Write-Host "Downloading Dart SDK using fast mirror..." -ForegroundColor Yellow
cd "C:\flutter\flutter\bin"
.\flutter.bat precache

Write-Host "`nSetting up dependencies for MINDLOCK..." -ForegroundColor Yellow
cd "d:\DEV\projects\COSTOM REMINDER\FocusLock"
.\flutter.bat pub get
.\flutter.bat pub run build_runner build --delete-conflicting-outputs
.\flutter.bat pub run flutter_launcher_icons

Write-Host "`n======================================" -ForegroundColor Green
Write-Host "  ALL SET! 🚀" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host "Connect your phone, and run this command:" -ForegroundColor Cyan
Write-Host "flutter run" -ForegroundColor White
