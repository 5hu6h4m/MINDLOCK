Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  MINDLOCK - Auto Android SDK Setup" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

$sdkPath = "D:\android_sdk"
$cmdlinePath = "$sdkPath\cmdline-tools"
$latestPath = "$cmdlinePath\latest"
$zipPath = "D:\cmdline-tools.zip"

Write-Host "1. Downloading Minimal Android SDK (~140 MB)..." -ForegroundColor Yellow
if (-not (Test-Path $sdkPath)) { New-Item -ItemType Directory -Path $sdkPath -Force | Out-Null }
if (-not (Test-Path $cmdlinePath)) { New-Item -ItemType Directory -Path $cmdlinePath -Force | Out-Null }

if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

Import-Module BitsTransfer
Start-BitsTransfer -Source "https://dl.google.com/android/repository/commandlinetools-win-11479070_latest.zip" -Destination $zipPath

Write-Host "`n2. Extracting SDK Tools..." -ForegroundColor Yellow
if (Test-Path $latestPath) { Remove-Item $latestPath -Recurse -Force }
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $cmdlinePath)
Rename-Item -Path "$cmdlinePath\cmdline-tools" -NewName "latest" -Force

Write-Host "3. Installing Android Platform & Build Tools (Please wait)..." -ForegroundColor Yellow
$sdkmanager = "$latestPath\bin\sdkmanager.bat"
# Accept all licenses automatically
"y`n" * 50 | & $sdkmanager --licenses
# Install required packages
& $sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0" "build-tools;33.0.1"

Write-Host "4. Linking Android SDK to Flutter..." -ForegroundColor Yellow
$flutterBin = "C:\flutter\flutter\bin\flutter.bat"
& $flutterBin config --android-sdk $sdkPath
"y`n" * 50 | & $flutterBin doctor --android-licenses

Write-Host "`n======================================" -ForegroundColor Green
Write-Host "  ANDROID SDK INSTALLED! 🚀" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host "Now building your APK file..." -ForegroundColor Cyan

cd "d:\DEV\projects\COSTOM REMINDER\FocusLock"
& $flutterBin build apk

Write-Host "`nDone! Your APK is ready." -ForegroundColor Green
