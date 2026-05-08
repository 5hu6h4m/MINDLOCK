# FocusLock Flutter Setup Script
# Run this script after Flutter download completes to extract and set up

Write-Host "======================================" -ForegroundColor Cyan
Write-Host " FocusLock - Flutter Setup Script    " -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

$flutterZip = "C:\flutter\flutter.zip"
$flutterDir = "C:\flutter"
$projectDir = "d:\DEV\projects\COSTOM REMINDER\FocusLock"

# Step 1: Wait for download if still running
Write-Host "`n[1/5] Checking Flutter download..." -ForegroundColor Yellow
if (-not (Test-Path $flutterZip)) {
    Write-Host "ERROR: Flutter zip not found at $flutterZip" -ForegroundColor Red
    exit 1
}

$size = [math]::Round((Get-Item $flutterZip).Length / 1MB, 0)
Write-Host "    Flutter zip: $size MB" -ForegroundColor Green

# Step 2: Extract Flutter
Write-Host "`n[2/5] Extracting Flutter SDK..." -ForegroundColor Yellow
if (-not (Test-Path "C:\flutter\flutter")) {
    Expand-Archive -Path $flutterZip -DestinationPath $flutterDir -Force
    Write-Host "    Extracted successfully!" -ForegroundColor Green
} else {
    Write-Host "    Already extracted, skipping." -ForegroundColor Green
}

# Step 3: Add Flutter to PATH for this session
Write-Host "`n[3/5] Adding Flutter to PATH..." -ForegroundColor Yellow
$env:Path = "C:\flutter\flutter\bin;$env:Path"
Write-Host "    Done. Run 'flutter --version' to verify." -ForegroundColor Green

# Add to permanent PATH
$currentPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
if (-not $currentPath.Contains("C:\flutter\flutter\bin")) {
    [System.Environment]::SetEnvironmentVariable(
        "Path",
        "C:\flutter\flutter\bin;$currentPath",
        "User"
    )
    Write-Host "    Added to permanent User PATH." -ForegroundColor Green
}

# Step 4: flutter pub get
Write-Host "`n[4/5] Installing Flutter dependencies..." -ForegroundColor Yellow
Set-Location $projectDir
& "C:\flutter\flutter\bin\flutter.bat" pub get
Write-Host "    Dependencies installed!" -ForegroundColor Green

# Step 5: flutter doctor
Write-Host "`n[5/5] Running flutter doctor..." -ForegroundColor Yellow
& "C:\flutter\flutter\bin\flutter.bat" doctor

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host " Setup Complete! Next Steps:          " -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host " 1. Connect Android device or start emulator" -ForegroundColor White
Write-Host " 2. Enable USB debugging on phone" -ForegroundColor White
Write-Host " 3. Run: flutter run" -ForegroundColor Yellow
Write-Host " 4. Or: flutter build apk --release" -ForegroundColor Yellow
Write-Host ""
Write-Host " Project location: $projectDir" -ForegroundColor Gray
