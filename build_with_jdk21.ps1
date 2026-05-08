Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  MINDLOCK - JAVA 21 BUILD WORKAROUND" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

$zipPath = "D:\jdk21.zip"
$jdkPath = "D:\jdk21"

if (-not (Test-Path $jdkPath)) {
    Write-Host "1. Downloading JDK 21..." -ForegroundColor Yellow
    node "d:\DEV\projects\COSTOM REMINDER\FocusLock\download_jdk.js"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "JDK Download failed!" -ForegroundColor Red
        exit
    }
    
    Write-Host "`n2. Extracting JDK 21..." -ForegroundColor Yellow
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $jdkPath)
} else {
    Write-Host "JDK 21 already downloaded and extracted." -ForegroundColor Green
}

# Find the extracted JDK folder (it extracts to a subfolder like jdk21.0.x)
$jdkSubFolder = Get-ChildItem -Path $jdkPath -Directory | Select-Object -First 1
$javaDir = $jdkSubFolder.FullName

Write-Host "3. Setting JAVA_HOME to $javaDir" -ForegroundColor Yellow
$env:JAVA_HOME = $javaDir
$env:Path = "$javaDir\bin;" + $env:Path

Write-Host "4. Building APK..." -ForegroundColor Cyan
cd "d:\DEV\projects\COSTOM REMINDER\FocusLock"
$flutterBin = "C:\flutter\flutter\bin\flutter.bat"
& $flutterBin build apk

Write-Host "`nDone! Your APK is ready." -ForegroundColor Green
