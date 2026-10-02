# Script: Restore Local Group Policy từ bản backup
# Chạy với quyền Administrator / SYSTEM

$ErrorActionPreference = "Stop"

$lgpoExe    = "C:\Soft\SCT\LGPO_30\LGPO.exe"
$backupRoot = "C:\Soft\GPO-Backup"          # Thư mục chứa các bản backup

# ===== Tìm bản backup mới nhất =====
$latestBackup = Get-ChildItem -Path $backupRoot -Directory -ErrorAction SilentlyContinue | 
                Sort-Object LastWriteTime -Descending | 
                Select-Object -First 1

if (-not $latestBackup) {
    Write-Host "ERROR: Không tìm thấy thư mục backup nào trong $backupRoot" -ForegroundColor Red
    exit 1
}

$backupPath = $latestBackup.FullName
Write-Host "Đang restore từ: $backupPath" -ForegroundColor Cyan

# Kiểm tra LGPO.exe
if (-not (Test-Path $lgpoExe)) {
    Write-Host "ERROR: Không tìm thấy LGPO.exe tại $lgpoExe" -ForegroundColor Red
    exit 1
}

try {
    # Restore toàn bộ GPO backup (Machine + User)
    & $lgpoExe /g $backupPath /v

    if ($LASTEXITCODE -ne 0) {
        throw "LGPO.exe trả về mã lỗi: $LASTEXITCODE"
    }

    # Cập nhật policy ngay
    Write-Host "Đang chạy gpupdate /force ..." -ForegroundColor Cyan
    gpupdate /force | Out-Null

    Write-Host "✓ Restore GPO thành công!" -ForegroundColor Green
    Write-Host "Đã áp dụng backup: $($latestBackup.Name)"
} catch {
    Write-Host "✗ Lỗi khi restore: $_" -ForegroundColor Red
    exit 1
}

exit 0
