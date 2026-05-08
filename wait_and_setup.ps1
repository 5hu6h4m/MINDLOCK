Write-Host "FocusLock - Waiting for Flutter download..." -ForegroundColor Cyan

$zipPath = "C:\flutter\flutter.zip"
$extractPath = "C:\flutter"
$flutterBin = "C:\flutter\flutter\bin\flutter.bat"
$project = "d:\DEV\projects\COSTOM REMINDER\FocusLock"

# Wait until download finishes (file size stops growing)
Write-Host "Monitoring download..." -ForegroundColor Yellow
$lastSize = 0
while ($true) {
    Start-Sleep -Seconds 5
    $currentSize = (Get-Item $zipPath -ErrorAction SilentlyContinue).Length
    $mb = [math]::Round($currentSize / 1MB, 0)
    Write-Host "  Downloaded: $mb MB" -ForegroundColor Gray
    if ($currentSize -gt 100MB -and $currentSize -eq $lastSize) {
        Write-Host "Download complete! $mb MB" -ForegroundColor Green
        break
    }
    $lastSize = $currentSize
}

# Extract
Write-Host "`nExtracting Flutter SDK..." -ForegroundColor Yellow
if (Test-Path "$extractPath\flutter") {
    Remove-Item "$extractPath\flutter" -Recurse -Force -ErrorAction SilentlyContinue
}
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $extractPath)
Write-Host "Extracted!" -ForegroundColor Green

# Add to PATH
$currentPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
if (-not $currentPath.Contains("C:\flutter\flutter\bin")) {
    [System.Environment]::SetEnvironmentVariable("Path", "C:\flutter\flutter\bin;$currentPath", "User")
}
$env:Path = "C:\flutter\flutter\bin;$env:Path"
Write-Host "Flutter added to PATH" -ForegroundColor Green

# flutter pub get
Write-Host "`nRunning flutter pub get..." -ForegroundColor Yellow
Set-Location $project
& $flutterBin pub get

# flutter doctor
Write-Host "`nRunning flutter doctor..." -ForegroundColor Yellow
& $flutterBin doctor

Write-Host "`n=== DONE! Now run: flutter run ===" -ForegroundColor Cyan
