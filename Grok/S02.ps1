# Script B: Nén thư mục Backup Policy thành file Zip
# Chạy sau Script A

$ErrorActionPreference = "Stop"

$backupRoot = "C:\Soft\GPO-Backup"
$zipRoot    = "C:\Soft\GPO-Zip"

# Tìm thư mục backup mới nhất
$latestBackup = Get-ChildItem -Path $backupRoot -Directory | 
                Sort-Object LastWriteTime -Descending | 
                Select-Object -First 1

if (-not $latestBackup) {
    Write-Host "ERROR: Không tìm thấy thư mục backup nào trong $backupRoot" -ForegroundColor Red
    exit 1
}

$backupName = $latestBackup.Name
$zipFile    = Join-Path $zipRoot "$backupName.zip"

# Tạo thư mục chứa zip nếu chưa có
New-Item -ItemType Directory -Path $zipRoot -Force | Out-Null

Write-Host "Đang nén: $($latestBackup.FullName)" -ForegroundColor Cyan
Write-Host "Thành file: $zipFile" -ForegroundColor Cyan

try {
    # Xóa file zip cũ nếu tồn tại
    if (Test-Path $zipFile) {
        Remove-Item $zipFile -Force
    }

    Compress-Archive -Path "$($latestBackup.FullName)\*" -DestinationPath $zipFile -CompressionLevel Optimal -Force
    Write-Host "✓ Nén thành công!" -ForegroundColor Green
    Write-Host "File Zip: $zipFile"
    Write-Host "Kích thước: $([math]::Round((Get-Item $zipFile).Length / 1KB, 2)) KB"
} catch {
    Write-Host "✗ Lỗi khi nén: $_" -ForegroundColor Red
    exit 1
}

exit 0
