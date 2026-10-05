# Script A: Backup Local Group Policy hiện tại
# Chạy với quyền Administrator / SYSTEM

$ErrorActionPreference = "Stop"

$lgpoExe = "C:\Soft\SCT\LGPO_30\LGPO.exe"
$backupRoot = "C:\Soft\GPO-Backup"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupPath = Join-Path $backupRoot "Backup-$timestamp"

# Kiểm tra LGPO.exe
if (-not (Test-Path $lgpoExe)) {
    Write-Host "ERROR: Không tìm thấy LGPO.exe tại $lgpoExe" -ForegroundColor Red
    exit 1
}

# Tạo thư mục backup
New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
Write-Host "Đang backup Local Policy vào: $backupPath" -ForegroundColor Cyan

try {
    & $lgpoExe /b $backupPath
    if ($LASTEXITCODE -ne 0) {
        throw "LGPO.exe trả về mã lỗi: $LASTEXITCODE"
    }
    Write-Host "✓ Backup thành công!" -ForegroundColor Green
    Write-Host "Thư mục backup: $backupPath"
    
    # Liệt kê nội dung để kiểm tra
    Get-ChildItem $backupPath -Recurse | Select-Object FullName
} catch {
    Write-Host "✗ Lỗi khi backup: $_" -ForegroundColor Red
    exit 1
}

exit 0
