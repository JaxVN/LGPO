# Restrict Office Save: Ẩn OneDrive Personal + This PC (chỉ còn OneDrive Business + SharePoint)

$ErrorActionPreference = "Stop"

# 1. Bật chế độ chỉ lưu Cloud
$path1 = "HKCU:\SOFTWARE\Microsoft\Office\16.0\Common\FileIO"
if (-not (Test-Path $path1)) { New-Item -Path $path1 -Force | Out-Null }
Set-ItemProperty -Path $path1 -Name "EnableCloudOnlySaveAsMode" -Value 1 -Type DWord -Force

# 2. Ưu tiên Cloud
$path2 = "HKCU:\Software\Microsoft\Office\16.0\Common\General"
if (-not (Test-Path $path2)) { New-Item -Path $path2 -Force | Out-Null }
Set-ItemProperty -Path $path2 -Name "PreferCloudSaveLocations" -Value 1 -Type DWord -Force

# 3. Ẩn OneDrive Personal (1) + This PC (4) = 5
# 
$path3 = "HKCU:\Software\Policies\Microsoft\Office\16.0\Common\Internet"
if (-not (Test-Path $path3)) { New-Item -Path $path3 -Force | Out-Null }
Set-ItemProperty -Path $path3 -Name "OnlineStorage" -Value 5 -Type DWord -Force

Write-Host "✓ Đã cấu hình: Chỉ hiện OneDrive for Business + SharePoint"
