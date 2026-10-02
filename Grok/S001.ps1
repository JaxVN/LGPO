# Action1 - Deploy OneDrive KFM + Hide C: Drive
# Chạy với quyền SYSTEM

$ErrorActionPreference = "Stop"
$tenantId = "YOUR-TENANT-ID-HERE"   # <-- Thay bằng Tenant ID thật

# ===== 1. OneDrive Known Folder Move (Silent) =====
$odPath = "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive"
if (-not (Test-Path $odPath)) {
    New-Item -Path $odPath -Force | Out-Null
}

Set-ItemProperty -Path $odPath -Name "KFMSilentOptIn" -Value $tenantId -Type String -Force
Set-ItemProperty -Path $odPath -Name "KFMSilentOptInWithNotification" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $odPath -Name "KFMBlockOptOut" -Value 1 -Type DWord -Force   # Chặn user tắt KFM

# ===== 2. Hide C: drive (áp dụng cho tất cả user hiện tại + Default) =====
# HKLM để ảnh hưởng máy
$explorerPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
if (-not (Test-Path $explorerPath)) {
    New-Item -Path $explorerPath -Force | Out-Null
}
Set-ItemProperty -Path $explorerPath -Name "NoDrives" -Value 4 -Type DWord -Force   # 4 = C:

# Áp dụng cho user đang login (nếu có)
$users = Get-ChildItem "C:\Users" -Directory | Where-Object { $_.Name -notin @("Public","Default","Default User","All Users") }
foreach ($u in $users) {
    $ntuser = "$($u.FullName)\NTUSER.DAT"
    if (Test-Path $ntuser) {
        # Load hive tạm nếu cần, nhưng cách đơn giản hơn là set HKCU khi user login
    }
}

# Set cho Default User (máy mới)
reg load "HKU\DefaultUser" "C:\Users\Default\NTUSER.DAT" 2>$null
if ($?) {
    reg add "HKU\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDrives /t REG_DWORD /d 4 /f
    reg unload "HKU\DefaultUser"
}

Write-Output "KFM and Hide C: configured successfully"
exit 0
