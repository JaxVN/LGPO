# Script C: Upload file Zip GPO Backup lên SharePoint
# Cần chỉnh 3 thông tin bên dưới trước khi chạy

$ErrorActionPreference = "Stop"

# ========== CẤU HÌNH - CHỈNH Ở ĐÂY ==========
$SharePointSiteUrl   = "https://yourtenant.sharepoint.com/sites/YourSite"   # URL site SharePoint
$SharePointFolder    = "Shared Documents/GPO-Backups"                       # Thư mục đích (relative path)
$ZipSourceFolder     = "C:\Soft\GPO-Zip"                                     # Thư mục chứa file zip local
# ============================================

# Tìm file zip mới nhất
$latestZip = Get-ChildItem -Path $ZipSourceFolder -Filter "*.zip" | 
             Sort-Object LastWriteTime -Descending | 
             Select-Object -First 1

if (-not $latestZip) {
    Write-Host "ERROR: Không tìm thấy file .zip nào trong $ZipSourceFolder" -ForegroundColor Red
    exit 1
}

Write-Host "File sẽ upload: $($latestZip.FullName)" -ForegroundColor Cyan
Write-Host "Đích: $SharePointSiteUrl / $SharePointFolder" -ForegroundColor Cyan

# Cách 1: Dùng PnP.PowerShell (khuyến nghị nếu đã cài module)
# Cài module 1 lần: Install-Module PnP.PowerShell -Scope AllUsers -Force

try {
    # Kết nối SharePoint (sẽ dùng credential của máy / app registration tùy môi trường)
    # Với Action1 chạy SYSTEM → nên dùng App Registration hoặc Certificate
    # Tạm thời dùng interactive / current user cho máy test:

    Import-Module PnP.PowerShell -ErrorAction Stop

    # Kết nối (máy test có thể dùng -Interactive hoặc -UseWebLogin)
    Connect-PnPOnline -Url $SharePointSiteUrl -Interactive

    # Upload file
    Add-PnPFile -Path $latestZip.FullName -Folder $SharePointFolder -ErrorAction Stop

    Write-Host "✓ Upload thành công lên SharePoint!" -ForegroundColor Green
} catch {
    Write-Host "✗ Lỗi khi upload: $_" -ForegroundColor Red
    Write-Host "Gợi ý: Cài PnP.PowerShell và cấu hình authentication phù hợp." -ForegroundColor Yellow
    exit 1
}

exit 0
