# Policies

| File | Nội dung |
|---|---|
| `NonAdmin-Registry.pol` | Registry.pol của nhóm Non-Administrators (bản cũ) |
| `Machine-registry.pol` | Registry.pol mức máy (đang trống) |
| `SRP-NonAdmin-lgpo.txt` | **LGPO text** – SRP (whitelist ứng dụng) cho nhóm **Non-Administrators**: `DefaultLevel=0`, 64 rule Unrestricted (đủ rule từ GPO domain cũ, gồm cả rule domain, `Microsoft\*`, `Desktop`, cùng Viber/Acrobat/MicroSIP...) + 1 hash rule `vfp7.exe` + 1 Disallowed (chỉ `WinStore.App.exe`). Có `CLEAR` nên áp lại sẽ xóa rule ngoại lệ |
| `SRP-NonAdmin-lgpo-Exception.txt` | **LGPO text** – SRP **ngoại lệ**: chỉ **thêm** 2 rule Unrestricted cho Zalo (`...\Programs\Zalo\Zalo.exe` và `...\Zalo-*\Zalo.exe`), **không có `CLEAR`** nên giữ nguyên các rule SRP đang có. Áp sau `SRP-NonAdmin-lgpo.txt` cho máy/user ngoại lệ |
| `SRP-NonAdmin-remove-lgpo.txt` | Gỡ SRP của nhóm Non-Administrators (rollback) |
| `OneDrive-Machine-lgpo.txt` | **LGPO text** – policy OneDrive mức máy: `EnableSyncAdminReports`, `AllowTenantList` (6 tenant), `TenantAutoMount` (14 thư viện, tên giá trị dạng `Ke_toan - Documents`) |
| `OneDrive-KFM-lgpo.txt` | **LGPO text mẫu** – `SilentAccountConfig` + Known Folder Move im lặng (Desktop/Documents/Pictures), mức máy. Chứa placeholder `YOUR-TENANT-ID-HERE`; script `A/T8_Apply_OneDrive_KFM.ps1` (6 launcher `A/L8_KFM_<TEN>.ps1`) thay bằng Tenant ID rồi áp bằng `LGPO /t`. Xem mục *OneDrive Known Folder Move theo tenant* trong `A/readme.md` |

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
- **Rule đã lược** so với domain: file tạm `__PSScriptPolicyTest_*`, đường dẫn gắn tên người (`C:\Users\ngan.hong\…`), các rule bị `Program Files` đã bao phủ (Acrobat, iTax Viewer), rule trùng lặp trong `FASTFOXPRO`.
- **Bài học từ thực tế (máy 655):** `backgroundTaskHost.exe`, `BackgroundTransferHost.exe` và `SecurityHealthHost.exe` **phải có rule riêng**, không thể dựa vào rule `Windows`. Rule Disallowed của MS Store (`…\WindowsApps\Microsoft.WindowsStore*`) chặn nhầm `backgroundTaskHost.exe` (sự kiện 866), và `SecurityHealthHost.exe` chạy với đường dẫn dạng `\\?\C:\Windows\…` nên rule `Windows` không khớp (sự kiện 865). Cả 4 đường dẫn này đã có trong file.
- **Mục TUY CHON (đang comment)**: rule quá rộng (`%UserProfile%\Desktop`, `…\Local\Microsoft\*`, `F:\*\*\*\*`…) và rule chỉ có nghĩa với domain. Nếu OneDrive/Teams bị chặn thì bỏ dấu `;` ở các rule `Local\Microsoft\*` rồi áp lại.
- Rule `…\OneDrive\OneDrive.exe` (cài theo user) là rule **thêm mới**, không có trong GPO domain.
- Gỡ SRP: `LGPO.exe /t "…\SRP-NonAdmin-remove-lgpo.txt"`, `gpupdate /force`, khởi động lại.

## Kiểm tra SRP chặn gì

Mỗi lần SRP chặn một chương trình, Windows ghi **cảnh báo** vào Application log (nguồn `Microsoft-Windows-SoftwareRestrictionPolicies`, sự kiện 865 hoặc 866). Xem 20 sự kiện mới nhất:

```bat
wevtutil qe Application "/q:*[System[Provider[@Name='Microsoft-Windows-SoftwareRestrictionPolicies']]]" /c:20 /f:text /rd:true
```
Dòng `AttemptedPath` là chương trình bị chặn; thêm một rule `Unrestricted` cho đường dẫn đó vào `SRP-NonAdmin-lgpo.txt` nếu cần chạy. Cảnh báo của `StoreDesktopExtension.exe` (Microsoft Store) là bình thường vì Store bị tắt có chủ ý.

## Tải và áp trực tiếp từ repo (CMD Administrator)

`LGPO.exe /t` chỉ đọc file trên ổ đĩa, nên tải file về `C:\Soft\SCT` rồi áp.

```bat
:: SRP cho Non-Administrators
curl -L -o "C:\Soft\SCT\SRP-NonAdmin-lgpo.txt" "https://raw.githubusercontent.com/JaxVN/LGPO/main/Policies/SRP-NonAdmin-lgpo.txt"
C:\Soft\SCT\LGPO_30\LGPO.exe /t "C:\Soft\SCT\SRP-NonAdmin-lgpo.txt"
gpupdate /force

:: OneDrive (AllowTenantList + TenantAutoMount)
curl -L -o "C:\Soft\SCT\OneDrive-Machine-lgpo.txt" "https://raw.githubusercontent.com/JaxVN/LGPO/main/Policies/OneDrive-Machine-lgpo.txt"
C:\Soft\SCT\LGPO_30\LGPO.exe /t "C:\Soft\SCT\OneDrive-Machine-lgpo.txt"

gpupdate /force
```

## Hash rule (vfp7.exe)

Ngoài path rule, `SRP-NonAdmin-lgpo.txt` có **hash rule** cho `vfp7.exe` (Visual FoxPro 7.0.0.9262, 4.354.048 byte, GUID `{133d0536-7da9-401b-94f2-8d2e20136031}`, dòng ~799–838). Hash rule cho phép chạy đúng file này dù nằm ở đường dẫn nào (ví dụ ổ `F:` map khác nhau), nên không phải tạo tay trên từng máy khách.

- Cú pháp LGPO cho giá trị nhị phân: `BINARY:3f,57,c7,...` (từng byte hai chữ số hex, **ngăn cách bằng dấu phẩy**). Viết liền (`BINARY:3f57c7...`) LGPO chỉ ghi 1 byte `FF` và rule không có tác dụng.
- Hash gắn với **nội dung file**: FoxPro/FAST cập nhật `.exe` hoặc máy khác dùng bản khác thì hash đổi, cần thêm rule mới.
- Cách lấy hash cho file khác: tạo hash rule tay một lần trên máy mẫu (gpedit → SRP → Additional Rules → New Hash Rule), chạy T6 (`L6_Run_T6.ps1`) rồi lấy mục `...\262144\Hashes\{GUID}` trong `HKCU-Policies.reg` (gồm `ItemData` MD5, `ItemSize`, và subkey `SHA256`). Không dùng `Get-FileHash` vì SRP tính hash kiểu Authenticode với file có chữ ký.
- Kiểm tra sau khi áp: `LGPO.exe /parse /u "C:\Windows\System32\GroupPolicyUsers\S-1-5-32-545\User\Registry.pol" | findstr /i 133d0536`, rồi **đăng xuất/đăng nhập lại** và xem Event 865 còn báo `vfp7.exe` không.

## Rule Store: vì sao hẹp

Rule Disallowed rộng `…\WindowsApps\Microsoft.WindowsStore*` đã **chặn nhầm `backgroundTaskHost.exe`** (sự kiện 866 lặp lại, kể cả khi có rule Unrestricted riêng cho nó) — tiến trình chạy tác vụ nền của ứng dụng Store, có thể ảnh hưởng slideshow màn hình khóa. Bản hiện tại chỉ chặn `WinStore.App.exe`; rule rộng nằm trong mục TUY CHON (comment) để tham khảo. Nếu Store vẫn mở được bằng user thường thì cần chỉnh lại rule.

## SRP ngoại lệ: cho Zalo (không xóa rule cũ)

Chạy trên máy của user ngoại lệ, CMD **Administrator**, **sau khi** đã áp `SRP-NonAdmin-lgpo.txt`:

```cmd
curl.exe -sSL "https://raw.githubusercontent.com/JaxVN/LGPO/main/Policies/SRP-NonAdmin-lgpo-Exception.txt?t=%RANDOM%" -o C:\Soft\SCT\SRP-NonAdmin-lgpo-Exception.txt
C:\Soft\SCT\LGPO_30\LGPO.exe /t C:\Soft\SCT\SRP-NonAdmin-lgpo-Exception.txt
gpupdate /force
```

Sau đó người dùng đăng xuất và đăng nhập lại.

- File **không có `CLEAR`**: LGPO chỉ ghi thêm 2 rule vào GPO nhóm Non-Administrators, các rule SRP khác giữ nguyên. Chạy lại nhiều lần an toàn (GUID cố định).
- **Thứ tự bắt buộc:** `SRP-NonAdmin-lgpo.txt` có `CLEAR`, áp lại file đó (hoặc chạy T3 rồi áp lại SRP) sẽ **xóa** rule ngoại lệ. Luôn áp lại file Exception sau cùng.
- Rule nằm ở nhóm Non-Administrators nên **mọi user thường trên máy đó** đều chạy được Zalo, không riêng một người. Muốn chỉ một tài khoản: đổi dòng `User:Non-Administrators` trong file thành `User:<tên tài khoản>` (tài liệu LGPO ghi *valid local account*, chưa kiểm với tài khoản Entra ID).
- Kiểm tra: `LGPO.exe /parse /u "C:\Windows\System32\GroupPolicyUsers\S-1-5-32-545\User\Registry.pol"` rồi tìm `Zalo`.
- Gỡ ngoại lệ (không đụng rule khác): lưu đoạn dưới thành file `.txt` và chạy `LGPO.exe /t <file>`, hoặc áp lại `SRP-NonAdmin-lgpo.txt`.

```
User:Non-Administrators
Software\Policies\Microsoft\Windows\Safer\CodeIdentifiers\262144\Paths
{f035fa75-26bf-56ad-9445-1bc366adcb43};{2a850ea9-1931-56aa-b5d8-5bb19afde013}
DELETEKEYS
```
