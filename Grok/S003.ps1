# Script: Restore Local Group Policy (Action1-friendly)
$ErrorActionPreference = "Stop"

$lgpoExe    = "C:\Soft\SCT\LGPO_30\LGPO.exe"
$backupRoot = "C:\Soft\GPO-Backup"

$latestBackup = Get-ChildItem -Path $backupRoot -Directory -ErrorAction SilentlyContinue | 
                Sort-Object LastWriteTime -Descending | 
                Select-Object -First 1

if (-not $latestBackup) {
    Write-Output "ERROR: Không tìm thấy thư mục backup nào trong $backupRoot"
    exit 1
}

$backupPath = $latestBackup.FullName
Write-Output "Đang restore từ: $backupPath"

if (-not (Test-Path $lgpoExe)) {
    Write-Output "ERROR: Không tìm thấy LGPO.exe"
    exit 1
}

try {
    # Chạy LGPO, chuyển toàn bộ output về stdout, ẩn banner
    $result = & $lgpoExe /g $backupPath 2>&1 | Out-String

    if ($LASTEXITCODE -ne 0) {
        Write-Output "ERROR: LGPO.exe trả về mã lỗi $LASTEXITCODE"
        Write-Output $result
        exit $LASTEXITCODE
    }

    # Chỉ in những dòng quan trọng
    Write-Output "LGPO restore completed successfully"

    Write-Output "Đang chạy gpupdate /force ..."
    gpupdate /force | Out-Null

    Write-Output "✓ Restore GPO thành công!"
    Write-Output "Đã áp dụng backup: $($latestBackup.Name)"
} catch {
    Write-Output "✗ Lỗi khi restore: $_"
    exit 1
}

exit 0
