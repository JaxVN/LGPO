# Script A: Backup Local Group Policy hiện tại
# Chạy với quyền Administrator / SYSTEM
# Đã xử lý stderr của LGPO.exe để Action1 không báo Error

$lgpoExe    = "C:\Soft\SCT\LGPO_30\LGPO.exe"
$backupRoot = "C:\Soft\GPO-Backup"
$timestamp  = Get-Date -Format "yyyyMMdd-HHmmss"
$backupPath = Join-Path $backupRoot "Backup-$timestamp"

# Kiểm tra LGPO.exe
if (-not (Test-Path $lgpoExe)) {
    Write-Output "ERROR: Không tìm thấy LGPO.exe tại $lgpoExe"
    exit 1
}

# Tạo thư mục backup
New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
Write-Output "Đang backup Local Policy vào: $backupPath"

try {
    # Tạm tắt Stop để LGPO không làm script bị dừng
    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = "Continue"

    $result = & $lgpoExe /b $backupPath 2>&1 | Out-String
    $exitCode = $LASTEXITCODE

    $ErrorActionPreference = $prevEAP

    if ($exitCode -ne 0) {
        Write-Output "ERROR: LGPO.exe trả về mã lỗi: $exitCode"
        Write-Output $result
        exit $exitCode
    }

    Write-Output "✓ Backup thành công!"
    Write-Output "Thư mục backup: $backupPath"

    # Liệt kê nội dung để kiểm tra
    Get-ChildItem $backupPath -Recurse | ForEach-Object {
        Write-Output $_.FullName
    }
}
catch {
    Write-Output "✗ Lỗi khi backup: $_"
    exit 1
}

exit 0
