# Runbook Helpdesk: deploy GPO mẫu cho 6 tenant

Dành cho Helpdesk. Tài liệu này nói rõ **việc nào Action1 làm tự động** và **việc nào phải làm tay cho từng tenant phụ**.
Sơ đồ tổng quan: [`Script-Map.md`](Script-Map.md). Danh sách script: [`Script-Map.csv`](Script-Map.csv).

| Tenant | Vai trò | Tenant ID | Launcher KFM (Action1) |
|---|---|---|---|
| **KIA** | Tenant chính (template mẫu được dựng từ tenant này) | `6fcf7bf2-2eb6-4b21-b92a-914d27ce33a8` | `A/L8_KFM_KIA.ps1` |
| SNP | Tenant phụ | `4be02620-368a-4c1c-81da-d298040b2d92` | `A/L8_KFM_SNP.ps1` |
| KSL | Tenant phụ | `692eb525-c279-4d74-a010-638ac401a7d9` | `A/L8_KFM_KSL.ps1` |
| LAV | Tenant phụ | `fa0fc2b5-6ddc-40aa-8f77-838d08c1e9e7` | `A/L8_KFM_LAV.ps1` |
| CIT | Tenant phụ | `e9e8ce93-6c8e-48c7-81ec-20fc1841b63c` | `A/L8_KFM_CIT.ps1` |
| DTC | Tenant phụ | `02cc35ba-57a1-438b-8ae4-f68de204fe24` | `A/L8_KFM_DTC.ps1` |

## 1. Template mẫu mang gì, và vì sao tenant phụ cần làm thêm

Template (`Templates/Win11/GPO-Template.zip`) được dựng trên máy của **tenant KIA**, nên có sẵn các giá trị của KIA:

| Policy trong template | Dùng được cho mọi tenant? | Việc cần làm cho tenant phụ |
|---|---|---|
| `AllowTenantList` (6 tenant) | **Có** | Không |
| `EnableSyncAdminReports`, `SilentAccountConfig`, `FilesOnDemandEnabled`, `KFMBlockOptOut` | **Có** | Không |
| **`KFMSilentOptIn`** (Tenant ID) | **Không**: đang là tenant KIA | **Chạy `L8_KFM_<TEN>`** để ghi đè bằng Tenant ID đúng |
| **`TenantAutoMount`** (14 thư viện SharePoint) | **Không**: toàn thư viện của KIA | **Làm tay** theo mục 3: xuất thư viện của tenant đó rồi áp |
| SRP Non-Admin (whitelist ứng dụng) | Có | Không |

## 2. Việc chạy trên Action1 (mỗi lần có template mới)

Thứ tự cố định: **T3 → L8**. Mỗi lần T3 thực sự deploy (SHA256 template đổi), nó **xóa `Registry.pol` cũ** nên KFM đúng tenant và TenantAutoMount của tenant phụ **mất**, phải áp lại.

| Bước | Việc | Chạy ở đâu | Cách |
|---|---|---|---|
| 1 | Deploy template | Mọi máy | Action1 chạy `A/L3_Run_T3.ps1` (nhóm Test trước) |
| 2 | **KFM đúng tenant** | Mọi máy | Action1 chạy `A/L8_KFM_<TEN>.ps1` cho **nhóm máy của công ty đó**. **KIA cũng chạy** để có log và kiểm tra |
| 3 | **TenantAutoMount của tenant phụ** | Máy tenant phụ | **Làm tay**, xem mục 3 |
| 4 | Người dùng đăng xuất/đăng nhập lại (hoặc khởi động lại OneDrive). Máy có SRP mới thì khởi động lại máy | Mọi máy | Báo người dùng |

Nếu T3 báo `Template khong doi ... bo qua` thì **không cần** chạy lại bước 2 và 3.

## 3. Việc làm tay cho từng tenant phụ: TenantAutoMount (SNP, KSL, LAV, CIT, DTC)

Hiện chưa có launcher Action1 cho phần này, vì danh sách thư viện của mỗi tenant phải lấy từ máy đã đăng nhập. Làm **một lần cho mỗi tenant**, sau đó áp lại sau mỗi lần T3 deploy.

### 3.1 Chuẩn bị file thư viện của tenant (một lần)
1. Chọn **một máy của người dùng thuộc tenant đó** (đã đăng nhập OneDrive bằng tài khoản tenant này).
2. Trên máy đó, người dùng **đồng bộ (Sync) tất cả thư viện SharePoint** cần tự mount cho cả công ty.
3. Mở PowerShell **bằng chính người dùng đó, không chạy bằng quyền SYSTEM**, chạy `A/T7_Export_OneDrive_Libraries.ps1` (tải từ repo hoặc từ `raw.githubusercontent.com/JaxVN/LGPO/main/A/T7_Export_OneDrive_Libraries.ps1`):
   ```powershell
   .\T7_Export_OneDrive_Libraries.ps1
   ```
   Kết quả nằm ở `C:\Soft\OneDrive-Libraries\`:
   - `OneDrive-TenantAutoMount-lgpo.txt`: file để áp bằng LGPO.
   - `OneDrive-Libraries.csv`: cột `Name`, `Value`, `Source`, `Status`. Sửa cột `Name` nếu muốn đặt lại tên thư viện rồi chạy lại với `-FromCsv`.
4. Kiểm tra file `.txt`: mỗi thư viện là một khối 4 dòng (`Computer` / key / tên / `SZ:tenantId=...`), `tenantId` phải **đúng tenant đang làm**.
5. Lưu file lên repo qua **Pull Request** với tên theo mẫu `Policies/OneDrive-AutoMount-<TEN>-lgpo.txt` (ví dụ `OneDrive-AutoMount-SNP-lgpo.txt`).

### 3.2 Áp lên máy của tenant đó (sau mỗi lần T3 deploy)
Trên máy đích, CMD **Administrator**:
```bat
curl -L -o "C:\Soft\SCT\OneDrive-AutoMount-SNP-lgpo.txt" "https://raw.githubusercontent.com/JaxVN/LGPO/main/Policies/OneDrive-AutoMount-SNP-lgpo.txt"
C:\Soft\SCT\LGPO_30\LGPO.exe /t "C:\Soft\SCT\OneDrive-AutoMount-SNP-lgpo.txt"
gpupdate /force
```
Đổi `SNP` theo tenant. Sau đó đăng xuất/đăng nhập lại hoặc khởi động lại OneDrive.

- File do T7 sinh ra có khối `DELETEALLVALUES` ở đầu: nó **xóa 14 thư viện KIA** có sẵn từ template rồi ghi thư viện của tenant này. Đó là điều cần làm cho tenant phụ.
- Chỉ muốn **thêm** thư viện, không xóa cái có sẵn: chạy T7 với `-NoClear`.
- Kiểm tra: `reg query "HKLM\SOFTWARE\Policies\Microsoft\OneDrive\TenantAutoMount"`.
- Chưa có launcher Action1 (`L9`) cho bước này; khi cần tự động có thể bổ sung, giống `L8`.

## 4. Việc khác cần làm tay tại máy
| Tình huống | Việc cần làm |
|---|---|
| **Máy Workgroup** (không join Entra ID) | `SilentAccountConfig` không có tác dụng. Người dùng **đăng nhập OneDrive bằng tay một lần** với đúng tenant; sau đó KFM tự chuyển. Launcher L8 vẫn chạy được (dùng tenant do launcher chỉ định) |
| Máy còn **Folder Redirection** từ GPO domain cũ | Bỏ redirect trước, nếu không KFM không chuyển được |
| Người dùng thuộc **nhiều tenant** (tài khoản Guest) | KFM im lặng chỉ nhận **một** Tenant ID; chọn tenant chính của máy |
| Máy đổi sang tenant khác | Chạy lại `L8_KFM_<TEN mới>`; nếu máy Entra joined thuộc tenant cũ thì T8 dừng, đặt `KFM_FORCE=1` để ép |

## 5. Lỗi thường gặp (xem log trên máy)

Log: `C:\Soft\GPO-Template\deploy.log` (T3), `C:\Soft\OneDrive-KFM\kfm.log` (T8).

| Thông báo | Nguyên nhân | Xử lý |
|---|---|---|
| `SHA256 khong khop` (T3) | Zip và `.sha256` trên repo không đi cùng nhau | Chạy lại T2 trên máy mẫu để upload lại cả hai file |
| `Template khong doi ... bo qua` (T3) | Zip không đổi từ lần deploy trước | Bình thường; không cần chạy lại L8 |
| `Launcher X ... nhung may thuoc tenant Y` (T8) | Chạy nhầm launcher cho nhóm máy | Dùng đúng `L8_KFM_<TEN>`; hoặc `KFM_FORCE=1` nếu cố ý |
| `May Workgroup, khong tu nhan duoc tenant` (T8) | Chạy T8 trực tiếp không qua launcher | Dùng `L8_KFM_<TEN>` |
| `KFM_TENANT '...' khong hop le` (T8) | Tên tenant sai | Chỉ dùng SNP, KIA, KSL, LAV, CIT, DTC hoặc Tenant ID dạng GUID |
| `Kiem tra registry that bai` (T8) | LGPO ghi nhưng giá trị không khớp | Chạy lại, gửi `kfm.log` cho người phụ trách |
| Máy không chuyển Desktop/Documents/Pictures | Chưa đăng nhập OneDrive đúng tenant, hoặc chưa đăng xuất/đăng nhập lại | Kiểm tra mục 4 |
| Sự cố sau T3 | — | Action1 chạy `A/L4_Run_T4.ps1` để quay về bản `PreDeploy-*` |

## 6. Checklist rollout cho một tenant phụ (ví dụ SNP)
- [ ] Máy mẫu đã upload template mới (T2), đã kiểm SHA256.
- [ ] Nhóm Test (1-2 máy SNP, gồm máy Entra joined và máy Workgroup): `L3` rồi `L8_KFM_SNP`.
- [ ] `reg query ... /v KFMSilentOptIn` ra Tenant ID của SNP.
- [ ] Đã có `Policies/OneDrive-AutoMount-SNP-lgpo.txt` trong repo (mục 3.1) và đã áp lên máy Test (mục 3.2).
- [ ] Người dùng thử: Desktop/Documents/Pictures chuyển lên OneDrive, thư viện SharePoint tự hiện.
- [ ] Nếu OK: áp cho cả nhóm SNP (T3, rồi L8_KFM_SNP, rồi áp AutoMount).
