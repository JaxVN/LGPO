# Exception/ - Cấu hình ngoại lệ theo bộ phận/người dùng (ngoài template)

Template GPO (`Templates/Win11`, áp bằng `L3b`) chỉ giữ cấu hình **chung** cho mọi máy, gồm 14 thư viện chung ở nhánh **Computer**. Thư mục này chứa cấu hình **riêng của từng bộ phận hoặc người dùng**, áp vào nhánh **Non-Administrators** của Local GPO, **không đụng nhánh Computer** và không phụ thuộc template.

| File | Dùng để |
|---|---|
| `T9_Apply_AutoMount_NonAdmin.ps1` | Chạy trên máy đích (Action1, SYSTEM). Tải file danh sách trong thư mục này, kiểm tra an toàn, backup, `LGPO /t`, `gpupdate`, đối chiếu số thư viện |
| `L9_AutoMount_PLY-DA.ps1` | Launcher Action1 cho bộ phận PLY-DA (đặt `EXC_FILE`). Bộ phận khác: copy file, đổi `EXC_FILE` |
| `OneDrive-AutoMount-PLY-DA-NonAdmin-lgpo.txt` | Danh sách 40 thư viện `PLY-DA-*` (xuất bằng T7 từ máy STCD00520, đã đối chiếu 40/40 với ID trong thư mục settings của OneDrive) |

## Áp bằng Action1
1. **Sau T3/L3b** (T3 nạp lại `Registry.pol` của nhóm Non-Administrators từ template nên sẽ xóa danh sách này), chạy `Exception/L9_AutoMount_PLY-DA.ps1` cho nhóm máy của bộ phận.
2. Báo người dùng đăng xuất và đăng nhập lại (hoặc khởi động lại OneDrive).
3. Log: `C:\Soft\GPO-Exception\exception.log`. Backup trước khi ghi: `C:\Soft\GPO-Backup\Exception-<giờ>\NonAdmin-Registry.pol`.

T9 dừng (exit 1, không ghi policy) khi: file có khối không phải `User:Non-Administrators`, file không có dòng `SZ:tenantId=`, hoặc máy Entra joined mà tenant của máy không nằm trong file (ép: `EXC_FORCE=1`). Sau khi ghi, T9 đếm số thư viện trong `Registry.pol` Non-Admin và báo lỗi nếu khác số trong file.

## Áp tay (không qua Action1), CMD Administrator
```bat
curl.exe -sSL "https://raw.githubusercontent.com/JaxVN/LGPO/main/Exception/OneDrive-AutoMount-PLY-DA-NonAdmin-lgpo.txt" -o C:\Soft\SCT\OneDrive-AutoMount-PLY-DA-NonAdmin-lgpo.txt
C:\Soft\SCT\LGPO_30\LGPO.exe /t C:\Soft\SCT\OneDrive-AutoMount-PLY-DA-NonAdmin-lgpo.txt
gpupdate /force
```

## Thêm bộ phận mới
1. Trên máy mẫu của bộ phận, user đã Sync đủ thư viện, mở PowerShell thường của user đó và chạy T7:
   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\Soft\T7_Export_OneDrive_Libraries.ps1 -Scope "User:Non-Administrators"
   ```
2. Kiểm tra `OneDrive-Libraries.csv`: cột `Status` đều `OK`, `tenantId` đúng.
3. Đặt `OneDrive-TenantAutoMount-lgpo.txt` vào thư mục này với tên `OneDrive-AutoMount-<BOPHAN>-NonAdmin-lgpo.txt`, copy `L9_AutoMount_PLY-DA.ps1` thành `L9_AutoMount_<BOPHAN>.ps1` và đổi `EXC_FILE`.

## Lưu ý
- Nhánh Non-Administrators áp cho **mọi user thường trên máy**, không riêng một người. User là local admin thì không nhận (`net localgroup administrators`).
- Người dùng thấy **cả hai danh sách**: 14 thư viện chung (nhánh Computer, từ template) và danh sách của bộ phận. Khối `DELETEALLVALUES` trong file chỉ xóa danh sách cũ của nhánh Non-Administrators.
- Gỡ danh sách: lưu đoạn sau thành `.txt` rồi `LGPO.exe /t <file>` và `gpupdate /force`:
  ```
  User:Non-Administrators
  SOFTWARE\Policies\Microsoft\OneDrive\TenantAutoMount
  *
  DELETEALLVALUES
  ```

## GPO đã có danh sách nhưng thư viện chưa hiện (máy STCD00062)
Kiểm tra lần lượt, trên máy đó:
1. Đăng nhập bằng đúng user thường, `net localgroup administrators` không có tên user đó.
2. Sau khi đăng xuất/đăng nhập lại: `reg query "HKCU\SOFTWARE\Policies\Microsoft\OneDrive\TenantAutoMount"` phải ra đủ các dòng. Không có: policy chưa vào HKCU của user (kiểm `gpresult /r /scope user`, chạy `gpupdate /force` bằng chính user đó).
3. Có dòng nhưng Explorer chưa hiện: OneDrive đã đăng nhập đúng tài khoản `@kiena.vn`, thoát hẳn OneDrive rồi mở lại. Thư viện có thể xuất hiện chậm sau khi policy đến (tài liệu Microsoft nói có độ trễ, chưa tra lại con số).
4. Kiểm tra ID: dùng T7 trên máy mẫu, so `siteId/webId/listId` trong file với giá trị thật; ID sai thì policy vẫn hiện trong gpedit nhưng thư viện không sync.
5. Cách cuối, sẽ phải sync lại từ đầu: `%localappdata%\Microsoft\OneDrive\onedrive.exe /reset`.
