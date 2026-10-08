# Policies

| File | Nội dung |
|---|---|
| `NonAdmin-Registry.pol` | Registry.pol của nhóm Non-Administrators (bản cũ) |
| `Machine-registry.pol` | Registry.pol mức máy (đang trống) |
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
