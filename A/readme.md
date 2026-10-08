# A/ - Script chạy trên Action1

Mục tiêu: cấu hình **một laptop mẫu (655) bằng tay**, test xong thì **backup → đóng gói 1 file ZIP → đẩy lên repo**.
Các máy khác dùng Action1 **tải ZIP mẫu đó về và deploy** bằng LGPO. Có sẵn rollback.

```
 LAPTOP MẪU 655                       GITHUB (JaxVN/LGPO)                  MÁY ĐÍCH (Action1, SYSTEM)
 ───────────────                      ───────────────────                  ────────────────────────────
 cấu hình tay (gpedit, secpol…)
 test tay
      │
      ▼
 T1_Backup_Template.ps1  ──zip──►  (C:\Soft\GPO-Zip\GPO-Template.zip)
      │
      ▼
 T2_Upload_Template.ps1  ───────►  Templates/Win11/GPO-Template.zip
                                   Templates/Win11/GPO-Template.zip.sha256 ──►  T3_Deploy_Template.ps1
                                                                           (tải, kiểm SHA256, backup hiện trạng,
                                                                            xoá policy cũ, LGPO /g, gpupdate)
                                                                          T4_Rollback_PreDeploy.ps1 (nếu cần)
```

## Các script

### Quy trình mới (khuyến nghị)

| Script | Chạy ở đâu | Làm gì |
|---|---|---|
| `T1_Backup_Template.ps1` | Laptop mẫu 655 (Admin) | `LGPO /b` Local Policy + copy GPO riêng *Non-Administrators / Administrators* + `manifest.json` → nén `C:\Soft\GPO-Zip\GPO-Template.zip` và `.sha256` |
| `T1a_Backup_LGPO.ps1` → `T1b_Extra_Manifest.ps1` → `T1c_Zip_Template.ps1` | Laptop mẫu 655 | **T1 tách làm 3 bước để debug** (chạy lần lượt): T1a = `LGPO /b`; T1b = copy GPO Non-Admin/Admin + `manifest.json`; T1c = nén zip bằng .NET `ZipFile` + SHA256 và liệt kê nội dung zip. Mỗi script in rõ bước, dòng lỗi và stack trace |
| `L1_Run_T1.ps1` | Action1 (laptop mẫu) | Launcher chạy cả `T1_Backup_Template.ps1` (3 bước trong 1 lần). Lỗi thì chạy riêng L1a/L1b/L1c |
| `L1a_Run_T1a.ps1`, `L1b_Run_T1b.ps1`, `L1c_Run_T1c.ps1` | Action1 (laptop mẫu) | **Launcher mỏng**: mỗi file tải `T1a`/`T1b`/`T1c` từ GitHub (`raw.githubusercontent.com`, có `?t=` tránh cache) rồi chạy, exit code chuyển thẳng cho Action1. Dán 3 file này vào Action1 thay vì dán nguyên T1x; sửa script trên repo là Action1 tự dùng bản mới. **Mặc định `$Branch = "main"`** |
| `L3_Run_T3.ps1`, `L4_Run_T4.ps1` | Action1 (máy đích) | Launcher cho `T3` (deploy mẫu) và `T4` (rollback), cùng khuôn L1a/b/c. **Test 1–2 máy trước** khi áp cho cả đội |
| `T6_Collect_Domain_Effective.ps1` (+ launcher `L6_Run_T6.ps1`) | **Máy domain**, Action1 | Thu chính sách **đang có hiệu lực** (gồm GPO từ domain) để đối chiếu khi làm GPO cho nhóm WorkGroup: `gpresult` Computer/User (.xml + .html), `reg export` của `HKLM\SOFTWARE\Policies`, `HKLM\…\CurrentVersion\Policies` và (nếu có user đăng nhập) `HKCU` tương ứng → `C:\Soft\GPO-Zip\Domain-Effective.zip`. Bù phần Administrative Templates của GPO domain mà `LGPO /b` (T1) không lấy. **Không dùng để deploy**. Đưa lên repo: trên máy đó chạy `$env:LGPO_ZIP="Domain-Effective.zip"; $env:LGPO_FOLDER="Domain"; .\T2_Upload_Template.ps1` → `Templates/Domain/` |
| `T2_Upload_Template.ps1` | Laptop mẫu 655, **chạy tay** | Đẩy ZIP + SHA256 lên `Templates/Win10/` hoặc `Templates/Win11/` (tự nhận theo build Windows của máy mẫu: build ≥ 22000 = Win11) qua GitHub API. Cần PAT (Contents: Read & write) – nhập khi được hỏi hoặc đặt `$env:GITHUB_TOKEN`. Không chạy qua Action1 |
| `T3_Deploy_Template.ps1` | Máy đích, Action1 | Cài LGPO nếu thiếu → tải ZIP đúng bản OS (`Templates/Win10` hoặc `Win11`, tự nhận theo build; đặt `$OsFolder` để ép) + **kiểm SHA256** → backup hiện trạng `PreDeploy-*` → xoá `Registry.pol` cũ → `LGPO /g` + `/un` + `/ua` → `gpupdate`. ZIP không đổi so với lần trước thì bỏ qua |
| `T4_Rollback_PreDeploy.ps1` | Máy đích, Action1 | Khôi phục về bản `PreDeploy-*` mới nhất (trước lần T3 gần nhất) |

Cả 4 script **độc lập** (dán thẳng vào Action1 hoặc chạy qua launcher), log tiếng Anh/không dấu để Action1 hiển thị ổn định.

### Script cũ (vẫn giữ)

| File | Ghi chú |
|---|---|
| `C_Deloy LGPO Part1` | Tải & giải nén `LGPO.zip` vào `C:\Soft\SCT`. T3 đã tự cài LGPO nên không bắt buộc |
| `C_Deloy_Policy_P0` | Launcher chạy `Grok/S000.ps1` (cài ADMX Office/OneDrive vào `C:\Windows\PolicyDefinitions`). **Chạy trên laptop mẫu trước khi cấu hình** để gpedit thấy template Office |
| `C_Deloy_Policy_P2` | Backup cũ. **Bị thay bởi T1** (bản này chưa xử lý stderr của LGPO nên Action1 dễ báo Error) |

### Debug T1

Nếu T1 báo lỗi, log in `FAILED at step [1/3 | 2/3 | 3/3]` kèm dòng gây lỗi. Chạy lại riêng `T1a` → `T1b` → `T1c` để xem step nào hỏng. Trạng thái lưu ở `C:\Soft\GPO-Template-Build\` (thư mục `Backup\{GUID}`, `Extra\`, `manifest.json`); T1b/T1c đọc lại thư mục này nên không phải backup lại. Lưu ý: T1a **xóa** thư mục build cũ trước khi backup.

## Quy trình thực hiện

1. **Laptop mẫu**: chạy `Part1` + `P0` (LGPO + ADMX), cấu hình tay bằng `gpedit.msc` / `secpol.msc` (và MMC cho Non-Administrators nếu cần ẩn ổ C), test kỹ. Riêng SRP xem mục [SRP](#srp-software-restriction-policies-cho-non-administrators).
2. Chạy `T1_Backup_Template.ps1` → kiểm tra `C:\Soft\GPO-Zip\GPO-Template.zip`.
3. Chạy `T2_Upload_Template.ps1` → ZIP lên `Templates/Win10/` hoặc `Templates/Win11/` (hoặc upload tay qua web rồi nhớ upload cả `.sha256`).
4. **Thử 1–2 máy** bằng `T3` trước, kiểm tra, rồi mới tạo Action1 policy/automation cho cả đội. Tách Endpoint Group Member / Guest nếu cần.
5. Có sự cố → `T4` trên máy đó.

Chạy bằng Action1: dán nội dung `T3` vào Script Library (PowerShell), hoặc dùng launcher:

```powershell
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$u = "https://raw.githubusercontent.com/JaxVN/LGPO/main/A/T3_Deploy_Template.ps1"
Invoke-Expression (Invoke-WebRequest -Uri $u -UseBasicParsing).Content
```

> Launcher chạy mã từ nhánh `main` bằng SYSTEM → chỉ cho người có quyền ghi repo; cân nhắc ghim commit SHA thay cho `main`.

## SRP (Software Restriction Policies) cho Non-Administrators

**Không dùng `Grok/SRP.ps1` để deploy.** Script đó ghi thẳng registry (HKLM) nên không vào được backup/ZIP, không idempotent (mỗi lần chạy thêm GUID rule trùng) và đang đặt `DefaultLevel = 262144` (Unrestricted) nên các rule "cho phép" không có tác dụng. Giữ lại chỉ như **danh sách rule tham khảo** để nhập tay.

Cấu hình bằng MMC (đã xác nhận có mục này trong Non-Administrators Policy trên Windows 11):

1. `mmc` → File → Add/Remove Snap-in → **Group Policy Object Editor** → Browse → tab **Users** → **Non-Administrators**.
2. `User Configuration → Windows Settings → Security Settings → Software Restriction Policies` → chuột phải → **New Software Restriction Policies**.
3. **Security Levels**: chọn **Disallowed** → *Set as Default* nếu muốn whitelist; để **Unrestricted** nếu chỉ chặn vài thứ.
4. **Additional Rules**: nhập các path rule (Unrestricted) và rule chặn MS Store `%programfiles%\WindowsApps\Microsoft.WindowsStore*` (Disallowed) lấy từ `Grok/SRP.ps1`. Nên rà lại các rule quá rộng: `%UserProfile%\Desktop`, `C:\Users\*\AppData\Local\Microsoft\*\*\*.exe`, `F:\*\*\*\*`.
5. **Reboot** laptop mẫu (SRP tạo lần đầu cần reboot mới có hiệu lực), test bằng tài khoản user thường.
6. Chạy `T1`; kiểm tra `Extra\NonAdmin-Registry.pol` trong ZIP có key `Software\Policies\Microsoft\Windows\Safer\CodeIdentifiers`.

Trên máy đích: `T3` áp lại qua `LGPO /un`; **cần reboot (hoặc user đăng nhập lại) lần đầu** để SRP có hiệu lực. Không chạy `SRP.ps1` song song; nếu HKLM và HKCU cùng định nghĩa SRP, tôi nhớ machine-level được ưu tiên (chưa kiểm chứng) – nên chỉ giữ một nguồn.

## So sánh nội dung template (CSV)

`Templates/Template-Compare.csv` liệt kê toàn bộ file và từng setting trong ZIP mẫu (Win11, Win10 và Domain) (registry của Non-Administrators, SRP path rule, Security Settings, Advanced Audit, manifest). Các cột: `Item type | Path in zip | Section / Registry key | Name | Type | Win 11 | Win10 | Domain | Note 1 | Note 2`. Cột `Win 11` / `Win10` / `Domain` là giá trị trong ZIP tương ứng (`Templates/Win11`, `Win10`, `Domain`) (trống = không có), `Note 1/2` để bạn ghi chú. Mở bằng Excel (UTF-8 có BOM).

Cột `Domain` đọc cả `Templates/Domain/GPO-Template.zip` (T1, Security Settings) và `Templates/Domain/Domain-Effective.zip` (T6: GPO đã ap, registry policy domain; item type `Domain GPO applied` / `Registry policy`; token/tài khoản đăng nhập trong `.reg` được thay bằng `(redacted)`). Mọi registry policy (từ `.pol` của template và `.reg` của máy domain) dùng chung item type `Registry policy`, Section có tiền tố hive `HKLM\` / `HKCU\`; rule SRP gom chung item type `SRP path rule` để so sánh giữa các nguồn. Cập nhật sau khi upload ZIP mới (Win10, Win11 hoặc Domain): `python3 Templates/build_compare_csv.py` — **giữ nguyên Note đã nhập**.

## Đường dẫn trên máy

| Mục | Đường dẫn |
|---|---|
| LGPO.exe | `C:\Soft\SCT\LGPO_30\LGPO.exe` |
| Build + ZIP mẫu (laptop mẫu) | `C:\Soft\GPO-Template-Build\`, `C:\Soft\GPO-Zip\` |
| ZIP tải về, log, hash đã deploy (máy đích) | `C:\Soft\GPO-Template\` (`deploy.log`, `deployed.sha256`) |
| Backup trước deploy | `C:\Soft\GPO-Backup\PreDeploy-yyyyMMdd-HHmmss\` |

## Lưu ý quan trọng

- **Chỉ policy đi qua Local Group Policy mới được backup.** `LGPO /b` lấy `Registry.pol`, Security Settings, Audit. Giá trị ghi thẳng registry bằng `Set-ItemProperty` (như `Grok/S001/S002/SRP.ps1`) **không** có trong ZIP. Hãy cấu hình bằng gpedit/secpol (hoặc import `.pol`) trên laptop mẫu.
- `LGPO /b` **không** gồm GPO riêng cho Administrators / Non-Administrators → T1 copy `GroupPolicyUsers\S-1-5-32-545|544\User\Registry.pol` vào `Extra\`, T3 áp lại bằng `/un` `/ua`.
- `CleanBeforeApply = $true` (T3) xoá `Registry.pol` của máy đích trước khi import để máy đích giống máy mẫu; policy do GPO domain/MDM không bị ảnh hưởng. Đặt `$false` nếu chỉ muốn merge.
- Registry **HKCU** (ví dụ `Grok/S002.ps1`, cấu hình Office) không được SYSTEM áp cho user – cần cấu hình qua User policy trên máy mẫu để vào ZIP.
- **ZIP chứa toàn bộ policy của máy mẫu**, kể cả tên máy/đường dẫn nội bộ (SRP…). Nếu repo public, cân nhắc chuyển repo private và điền `$Token` trong T3 (PAT chỉ Contents: Read).
- SHA256 trong `.sha256` chặn được tải hỏng/ghi lỗi, nhưng không chặn kẻ có quyền ghi repo (họ ghi được cả hai file). Muốn chặt hơn, đặt hash mong đợi cố định trong Action1.
- Bản này **chưa test trên Windows** (môi trường dựng script là Linux). Hãy thử trên 1 VM/máy test trước: kiểm `LGPO /b` tạo `{GUID}`, `/g` áp lại đúng, rollback hoạt động.
- `Policies/NonAdmin-Registry.pol` hiện trong repo mới có `NoDrives` + vài key certificate, **chưa có SRP**; ZIP mới từ T1 sẽ chứa cả hai sau khi cấu hình xong.
- Còn lại chưa làm: upload backup định kỳ lên SharePoint và restore từ SharePoint (`Grok/S02`, `Grok/S03`).

## Cấu hình bằng file `.reg`

Thư mục [`Regedit/`](../Regedit/README.md) chứa các file `.reg` nhập trực tiếp vào registry (không qua PowerShell/Local GPO): OneDrive `AllowTenantList` (6 tenant) và `TenantAutoMount` (14 thư viện), kèm file gỡ.

## Policy OneDrive bằng LGPO text

[`Policies/OneDrive-Machine-lgpo.txt`](../Policies/README.md): `AllowTenantList` (6 tenant) + `TenantAutoMount` (14 thư viện) + `EnableSyncAdminReports`. Áp bằng `LGPO.exe /t` lên máy mẫu để vào Local GPO (T1 backup được), thay cho file `.reg` ghi thẳng registry.

## Việc cần làm sau (backlog)

- [ ] **Chuyển repo sang private** (hiện đang public để develop). Trước khi chuyển: `T3`/launcher cần `$Token` (PAT fine-grained, Contents: Read-only) hoặc tách `Templates/` sang repo private riêng. Lưu ý các file nhạy cảm đã nằm trong lịch sử git (`Templates/Domain/*` có tên máy/GPO/OU/IP nội bộ, `gpresult-*.html`, `HKLM-Policies.reg`).
- [ ] Báo cáo GPO dạng web: xuất `Get-GPOReport` (XML/HTML) từ DC → script chuyển sang Markdown có mục thu gọn, gom thành `docs/`.
- [ ] Cột baseline Microsoft (Security Baseline xlsx) trong `Template-Compare.csv`.
- [ ] Cập nhật Edge baseline (hiện v139) và các baseline mới của Security Compliance Toolkit.
- [ ] Dựng SRP cho workgroup từ danh sách rule domain (lọc các path rộng, rule gắn tên người, file tạm).
