Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  MINDLOCK - NODE.JS ANDROID SETUP" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

$sdkPath = "D:\android_sdk"
$cmdlinePath = "$sdkPath\cmdline-tools"
$latestPath = "$cmdlinePath\latest"
$zipPath = "D:\android-tools-node.zip"

Write-Host "1. Downloading Minimal Android SDK (~140 MB) via NODE.JS..." -ForegroundColor Yellow
if (-not (Test-Path $sdkPath)) { New-Item -ItemType Directory -Path $sdkPath -Force | Out-Null }
if (-not (Test-Path $cmdlinePath)) { New-Item -ItemType Directory -Path $cmdlinePath -Force | Out-Null }

if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

# Run the Node downloader
node "d:\DEV\projects\COSTOM REMINDER\FocusLock\download.js"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Download failed!" -ForegroundColor Red
    exit
}

Write-Host "`n2. Extracting SDK Tools..." -ForegroundColor Yellow
if (Test-Path $latestPath) { Remove-Item $latestPath -Recurse -Force }
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $cmdlinePath)

$extractedFolder = "$cmdlinePath\cmdline-tools"
if (Test-Path $extractedFolder) {
    Rename-Item -Path $extractedFolder -NewName "latest" -Force
} else {
    Write-Host "WARNING: Expected folder $extractedFolder not found. Script might fail." -ForegroundColor Red
}

Write-Host "3. Installing Android Platform & Build Tools (Please wait)..." -ForegroundColor Yellow
$sdkmanager = "$latestPath\bin\sdkmanager.bat"

if (Test-Path $sdkmanager) {
    "y`n" * 50 | & $sdkmanager --licenses
    & $sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0" "build-tools;33.0.1"
} else {
    Write-Host "ERROR: sdkmanager not found at $sdkmanager" -ForegroundColor Red
    exit
}

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
