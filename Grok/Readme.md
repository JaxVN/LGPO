# LGPO + Action1 Deployment Guide

**Môi trường:** Windows 10/11 Pro Workgroup (~100 máy)  
**Công cụ:** Action1 RMM + LGPO.exe + GitHub  
**Tenant:** KIA (50 user native + 50 Guest từ 5 tenant khác)  
**Cập nhật:** 02/10/2026

---

## 1. Mục tiêu chính

| Hạng mục | Mô tả |
|----------|------|
| 1 | Redirect Desktop / Documents / Pictures → OneDrive (Known Folder Move) |
| 2 | Ẩn ổ C: trong File Explorer |
| 3 | Ghim OneDrive + SharePoint lên Quick Access |
| 4 | Office chỉ cho phép lưu vào OneDrive for Business + SharePoint (ẩn This PC + OneDrive Personal) |
| 5 | Pipeline Backup → Zip → Upload SharePoint → Restore |

---

## 2. Cấu trúc thư mục & Repo

```
https://github.com/JaxVN/LGPO
├── LGPO.zip                          # LGPO.exe
├── Grok/
│   ├── S001.ps1                      # Download + Extract LGPO
│   ├── S002.ps1                      # Backup GPO
│   ├── S003.ps1                      # Restore GPO (đã clean stderr)
│   ├── S004.ps1                      # Apply Hide C: (Non-Administrators)
│   ├── S005.ps1                      # Office Cloud-only Save
│   └── Readme.md                     # File này
├── Policies/
│   └── NonAdmin-Registry.pol         # Registry.pol của Non-Administrators
└── DOCUMENTATION.md
```

**Đường dẫn chuẩn trên máy:**

- LGPO.exe: `C:\Soft\SCT\LGPO_30\LGPO.exe`
- Backup: `C:\Soft\GPO-Backup\Backup-YYYYMMDD-HHMMSS\`
- Zip: `C:\Soft\GPO-Zip\`

---

## 3. Action1 Launcher (chạy trực tiếp từ GitHub)

```powershell
# Action1 Script - Chạy script từ GitHub (không lưu file)
$ErrorActionPreference = "Stop"
$ScriptUrl = "https://raw.githubusercontent.com/JaxVN/LGPO/refs/heads/main/Grok/S003.ps1"

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $scriptContent = (Invoke-WebRequest -Uri $ScriptUrl -UseBasicParsing).Content
    Invoke-Expression $scriptContent
    Write-Output "✓ Script chạy thành công"
} catch {
    Write-Output "✗ Lỗi: $_"
    exit 1
}
exit 0
```

---

## 4. Các Script chính

### 4.1. Download + Extract LGPO

```powershell
$url = "https://github.com/JaxVN/LGPO/raw/main/LGPO.zip"
$destinationFolder = "C:\Soft\SCT"
$zipFile = "$destinationFolder\LGPO.zip"

if (-not (Test-Path $destinationFolder)) {
    New-Item -ItemType Directory -Path $destinationFolder -Force | Out-Null
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $url -OutFile $zipFile -UseBasicParsing
Expand-Archive -Path $zipFile -DestinationPath $destinationFolder -Force
```

### 4.2. Backup GPO

```powershell
$lgpoExe = "C:\Soft\SCT\LGPO_30\LGPO.exe"
$backupRoot = "C:\Soft\GPO-Backup"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupPath = Join-Path $backupRoot "Backup-$timestamp"

New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
& $lgpoExe /b $backupPath /n "Backup-$timestamp"
Write-Output "✓ Backup thành công: $backupPath"
```

### 4.3. Restore GPO (clean – khuyến nghị)

```powershell
$ErrorActionPreference = "Stop"
$lgpoExe    = "C:\Soft\SCT\LGPO_30\LGPO.exe"
$backupRoot = "C:\Soft\GPO-Backup"

$latestBackup = Get-ChildItem -Path $backupRoot -Directory | 
                Sort-Object LastWriteTime -Descending | 
                Select-Object -First 1

if (-not $latestBackup) {
    Write-Output "ERROR: Không tìm thấy backup"
    exit 1
}

$backupPath = $latestBackup.FullName
Write-Output "Đang restore từ: $backupPath"

$result = & $lgpoExe /g $backupPath 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) {
    Write-Output "ERROR: LGPO exit code $LASTEXITCODE"
    Write-Output $result
    exit $LASTEXITCODE
}

gpupdate /force | Out-Null
Write-Output "✓ Restore GPO thành công! Backup: $($latestBackup.Name)"
exit 0
```

### 4.4. Ẩn ổ C: chỉ cho Non-Administrators

**Cách làm:**

1. Trên máy mẫu → MMC → Add Group Policy Object Editor → **Non-Administrators**
2. Bật: `User Configuration → Administrative Templates → Windows Components → File Explorer → Hide these specified drives in My Computer → Restrict C drive only`
3. Copy file: `C:\Windows\System32\GroupPolicyUsers\S-1-5-32-545\User\Registry.pol`
4. Apply trên máy khác:

```powershell
$lgpoExe = "C:\Soft\SCT\LGPO_30\LGPO.exe"
$polFile = "C:\Soft\GPO-NonAdmin\Registry.pol"
& $lgpoExe /un $polFile
gpupdate /force | Out-Null
```

> **Lưu ý:** `/un` = Non-Administrators · `/ua` = Administrators · `/u` = tất cả user

### 4.5. Office chỉ lưu vào OneDrive Business + SharePoint

```powershell
# Ẩn OneDrive Personal (1) + This PC (4) = 5
$path1 = "HKCU:\SOFTWARE\Microsoft\Office\16.0\Common\FileIO"
if (-not (Test-Path $path1)) { New-Item -Path $path1 -Force | Out-Null }
Set-ItemProperty -Path $path1 -Name "EnableCloudOnlySaveAsMode" -Value 1 -Type DWord -Force

$path2 = "HKCU:\Software\Microsoft\Office\16.0\Common\General"
if (-not (Test-Path $path2)) { New-Item -Path $path2 -Force | Out-Null }
Set-ItemProperty -Path $path2 -Name "PreferCloudSaveLocations" -Value 1 -Type DWord -Force

$path3 = "HKCU:\Software\Policies\Microsoft\Office\16.0\Common\Internet"
if (-not (Test-Path $path3)) { New-Item -Path $path3 -Force | Out-Null }
Set-ItemProperty -Path $path3 -Name "OnlineStorage" -Value 5 -Type DWord -Force

Write-Output "✓ Office chỉ hiện OneDrive for Business + SharePoint"
```

**Bảng giá trị OnlineStorage:**

| Giá trị | Ý nghĩa |
|---------|---------|
| 1 | Ẩn OneDrive Personal |
| 4 | Ẩn This PC |
| 8 | Ẩn SharePoint On-Prem |
| 16 | Ẩn Recent Places |
| 32 | Ẩn SharePoint Online |
| 64 | Ẩn OneDrive for Business |
| 128 | Ẩn Third Party |
| **5** | 1+4 → Ẩn Personal + This PC (khuyến nghị) |

Nguồn: [ADMX Guide - OnlineStorageFilter](https://admxguide.com/policies/Office/L_OnlineStorageFilter.html)

---

## 5. Multi-tenant & SharePoint Sync

- 50 user thuộc tenant **KIA** (native)
- 50 user Guest từ 5 tenant khác → truy cập KIA bằng Guest account
- Khi cấu hình sync 10 trang SharePoint Public:
  - User **không có quyền** → **không sync** trang đó, **không gây lỗi** toàn hệ thống
  - Nên tách Endpoint Group trên Action1 giữa Member và Guest

---

## 6. Lưu ý quan trọng khi dùng Action1

1. Action1 chạy dưới **SYSTEM** → script Office registry (HKCU) cần chạy dưới user context (Scheduled Task hoặc Action1 User session)
2. LGPO.exe thường ghi ra **stderr** → Action1 hiện **Error** dù exit code = 0  
   → Luôn dùng `2>&1 | Out-String` + `Write-Output`
3. Sau khi restore GPO nên `gpupdate /force` và khuyến khích user logoff/login

---

## 7. Checklist triển khai tiếp theo

- [ ] Hoàn thiện script Backup + Zip + Upload SharePoint
- [ ] Tạo Registry.pol Non-Administrators (Hide C:) trên máy mẫu
- [ ] Đẩy Registry.pol lên repo `Policies/`
- [ ] Viết script Apply Hide C: + Office Cloud-only (chạy dưới user)
- [ ] Tách Action1 Endpoint Group: Member vs Guest
- [ ] Test Known Folder Move (KFMSilentOptIn)
- [ ] Test pin OneDrive/SharePoint lên Quick Access (Scheduled Task)

---

## 8. Lệnh LGPO nhanh

```powershell
# Backup
LGPO.exe /b C:\Soft\GPO-Backup /n "MyBackup"

# Restore full
LGPO.exe /g C:\Soft\GPO-Backup\Backup-xxxxx

# Apply Non-Administrators only
LGPO.exe /un C:\path\Registry.pol

# Apply Administrators only
LGPO.exe /ua C:\path\Registry.pol
```

---

**Ghi chú:** File này được tổng hợp từ cuộc hội thoại ngày 02/10/2026.  
Cập nhật khi có thay đổi quy trình.
