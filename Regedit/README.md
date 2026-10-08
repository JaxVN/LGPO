# Regedit – cấu hình bằng file `.reg` (không qua PowerShell / Local GPO)

File `.reg` lấy từ máy **STCD00558** (bản export của key đang chạy tốt). Nhập trực tiếp vào registry mức máy (HKLM), áp cho mọi tài khoản.

| File | Tác dụng | Số giá trị |
|---|---|---|
| `OneDrive-AllowTenantList.reg` | Chỉ cho OneDrive sync tài khoản của 6 tenant (KIA + 5 tenant Guest) – policy *Allow syncing OneDrive accounts for only specific organizations* | 6 |
| `OneDrive-TenantAutoMount.reg` | Tự mount 14 thư viện SharePoint `H-*` – policy *Configure team site libraries to sync automatically* | 14 |
| `OneDrive-Remove.reg` | Gỡ cả hai policy trên (rollback) | – |

Mỗi file bắt đầu bằng dòng `[-HKEY_...]` (xóa key cũ) rồi tạo lại key, nên **chạy lại nhiều lần an toàn** và giá trị không còn trong danh sách sẽ bị xóa.

## Cách dùng
- **Thủ công:** chuột phải file `.reg` → *Merge* (cần quyền Administrator), hoặc `reg import "đường dẫn\file.reg"`.
- **Action1 (CMD, không cần PowerShell):**
  ```bat
  curl -L -o "%TEMP%\OneDrive-AllowTenantList.reg" https://raw.githubusercontent.com/JaxVN/LGPO/main/Regedit/OneDrive-AllowTenantList.reg
  reg import "%TEMP%\OneDrive-AllowTenantList.reg"
  curl -L -o "%TEMP%\OneDrive-TenantAutoMount.reg" https://raw.githubusercontent.com/JaxVN/LGPO/main/Regedit/OneDrive-TenantAutoMount.reg
  reg import "%TEMP%\OneDrive-TenantAutoMount.reg"
  ```
  (`main` chỉ có file sau khi PR được merge.)
- Sau khi nhập: thoát và mở lại OneDrive (`onedrive.exe /shutdown`, rồi mở lại) hoặc đăng nhập lại Windows. Thư viện hiện trong thư mục `KIA` trong File Explorer.

## Lưu ý
- **Ghi thẳng registry, không đi qua Local GPO:** `gpedit.msc` không hiển thị, `T1_Backup_Template` không backup và `T3_Deploy_Template` không áp lại các giá trị này. Khi dựng máy mới phải nhập `.reg` riêng.
- `AllowTenantList` **không dùng cùng** policy `BlockTenantList` của OneDrive (hai policy loại trừ nhau).
- Thư viện chỉ hiện với tài khoản **có quyền** truy cập site. Kiểm tra trên 558: tài khoản cá nhân thấy 14/14, tài khoản admin thấy 13/14 (thiếu `H-QLTK` dù chuỗi ID đúng và admin vào được site; xem ghi chú xử lý trong lịch sử trao đổi).
- File chứa tenant ID, site ID và tên miền SharePoint. Chuyển repo sang private khi hoàn tất giai đoạn phát triển (xem backlog trong `A/readme.md`).
