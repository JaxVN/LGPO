# Policies

| File | Nội dung |
|---|---|
| `NonAdmin-Registry.pol` | Registry.pol của nhóm Non-Administrators (bản cũ) |
| `Machine-registry.pol` | Registry.pol mức máy (đang trống) |
| `SRP-NonAdmin-lgpo.txt` | **LGPO text** – SRP (whitelist ứng dụng) cho nhóm **Non-Administrators**: `DefaultLevel=0`, 33 rule Unrestricted + 1 Disallowed (MS Store). Lọc từ GPO domain (máy 410) |
| `SRP-NonAdmin-remove-lgpo.txt` | Gỡ SRP của nhóm Non-Administrators (rollback) |
| `OneDrive-Machine-lgpo.txt` | **LGPO text** – policy OneDrive mức máy: `EnableSyncAdminReports`, `AllowTenantList` (6 tenant), `TenantAutoMount` (14 thư viện `H-*`) |

## Áp `OneDrive-Machine-lgpo.txt` lên máy mẫu (CMD Administrator)

Áp trực tiếp vào Local Group Policy, nên gpedit hiển thị được và `T1` backup được (khác với `Regedit/*.reg` ghi thẳng registry).

```bat
:: 1. Đóng gpedit.msc nếu đang mở. Backup trước (T1 hoặc):
copy C:\Windows\System32\GroupPolicy\Machine\registry.pol "%USERPROFILE%\Desktop\registry.pol.bak"

:: 2. Áp
C:\Soft\SCT\LGPO_30\LGPO.exe /t "C:\đường dẫn\OneDrive-Machine-lgpo.txt"

:: 3. Cập nhật policy
gpupdate /force

:: 4. Kiểm tra: liệt kê nội dung registry.pol mức máy
C:\Soft\SCT\LGPO_30\LGPO.exe /parse /m C:\Windows\System32\GroupPolicy\Machine\registry.pol
reg query "HKLM\SOFTWARE\Policies\Microsoft\OneDrive\TenantAutoMount"
```

Kết quả mong đợi: `TenantAutoMount` có **14** giá trị, `AllowTenantList` có **6**, `EnableSyncAdminReports = 1`. Trong gpedit (*Computer Configuration → Administrative Templates → OneDrive*) policy *Configure team site libraries to sync automatically* hiện 14 mục.

Sau đó: thoát và mở lại OneDrive (hoặc đăng nhập lại Windows) → thư viện hiện trong thư mục `KIA`. Rồi chạy lại **T1** (`A/L1_Run_T1.ps1`) và **T2** để đưa vào gói mẫu `Templates/Win11` hoặc `Templates/Win10`.

## Ghi chú
- `DELETEALLVALUES` xóa giá trị cũ trong key trước khi ghi lại (kể cả 14 giá trị đã nhập bằng `.reg` trước đó), nên danh sách luôn đúng với file.
- Để chỉnh danh sách: sửa file (mỗi thư viện là một khối 4 dòng `Computer` / key / tên giá trị / `SZ:chuỗi ID`), rồi áp lại.
- File chứa tenant ID, site ID, tên miền SharePoint. Chuyển repo sang private khi hoàn tất giai đoạn phát triển (xem backlog trong `A/readme.md`).

## Áp `SRP-NonAdmin-lgpo.txt` (CMD Administrator, **thử trên VM trước**)

```bat
:: backup trước (T1 hoặc):
copy "C:\Windows\System32\GroupPolicyUsers\S-1-5-32-545\User\Registry.pol" "%USERPROFILE%\Desktop\NonAdmin-Registry.pol.bak"

C:\Soft\SCT\LGPO_30\LGPO.exe /t "C:\đường dẫn\SRP-NonAdmin-lgpo.txt"
gpupdate /force
C:\Soft\SCT\LGPO_30\LGPO.exe /parse /u "C:\Windows\System32\GroupPolicyUsers\S-1-5-32-545\User\Registry.pol"
```
Sau đó **khởi động lại** (SRP lần đầu cần reboot), đăng nhập bằng **tài khoản user thường** để thử: Office, OneDrive, Edge, phần mềm nghiệp vụ (FAST/VFP, Viber, iTax…) phải chạy; ứng dụng không có trong danh sách sẽ bị chặn (đúng ý). Tài khoản Administrators không bị ảnh hưởng.

- **`CLEAR`** xóa SRP cũ trong GPO nhóm Non-Administrators rồi ghi lại bộ rule mới; các policy khác của nhóm này (ẩn ổ C, OneDrive HKCU, Office, chặn USB) không đổi.
- **Rule đã lược** so với domain: file tạm `__PSScriptPolicyTest_*`, đường dẫn gắn tên người (`C:\Users\ngan.hong\…`), các rule bị `Program Files` / `Windows` đã bao phủ (Acrobat, iTax Viewer, SecurityHealth, BackgroundTaskHost…), rule trùng lặp trong `FASTFOXPRO`.
- **Mục TUY CHON (đang comment)**: rule quá rộng (`%UserProfile%\Desktop`, `…\Local\Microsoft\*`, `F:\*\*\*\*`…) và rule chỉ có nghĩa với domain. Nếu OneDrive/Teams bị chặn thì bỏ dấu `;` ở các rule `Local\Microsoft\*` rồi áp lại.
- Rule `…\OneDrive\OneDrive.exe` (cài theo user) là rule **thêm mới**, không có trong GPO domain.
- Gỡ SRP: `LGPO.exe /t "…\SRP-NonAdmin-remove-lgpo.txt"`, `gpupdate /force`, khởi động lại.
