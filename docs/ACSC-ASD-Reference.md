# Cấu hình chuẩn ACSC/ASD (tham chiếu)

Nguồn: *Hardening Microsoft Windows 11 workstations* (ACSC, 09/2025) và *Hardening Microsoft 365, Office 2021, Office 2019 and Office 2016* (ACSC, 07/2023). Tài liệu này chỉ để **đối chiếu**, không thuộc phạm vi phê duyệt của [`Update-Local-Group-Policies.md`](Update-Local-Group-Policies.md): cột *Tình trạng* cho biết mục đó đã nằm trong tài liệu đó hay chưa. Các mục "Chưa có trong tài liệu" là đề xuất cho giai đoạn sau, cần thử trên máy mẫu trước vì có thể ảnh hưởng quy trình nghiệp vụ (ví dụ chặn liên kết ngoài và DDE có thể làm hỏng file Excel nội bộ dùng liên kết giữa các workbook).

**Chú giải tình trạng:** ✅ Đã có trong tài liệu · ⚠️ Có nhưng khác ACSC · ⛔ Lệch có chủ đích · ➕ Chưa có trong tài liệu.

## A. Windows 11 workstations

| Chính sách | Khuyến nghị ACSC | Tình trạng |
|---|---|---|
| **Computer Configuration\Administrative Templates\System\Removable Storage Access** | | |
| CD and DVD / Removable Disks / Tape Drives: Deny write access | Enabled | ⚠️ Có (mục 3.1B của tài liệu cập nhật), nhưng đặt ở User Non-Administrators, ACSC đặt ở Computer |
| WPD Devices: Deny write access | Enabled | ⚠️ Như trên |
| CD and DVD / Removable Disks / Tape Drives: Deny execute access | Enabled | ➕ |
| CD and DVD / Removable Disks / Tape Drives / WPD Devices: Deny read access | Disabled | ➕ (mặc định vẫn cho đọc) |
| All Removable Storage classes: Deny all access | Enabled (phương án chặn hoàn toàn) | ➕ |
| **Computer Configuration\Administrative Templates\Windows Components\AutoPlay Policies** | | |
| Disallow Autoplay for non-volume devices | Enabled | ➕ |
| Set the default behavior for AutoRun | Enabled: Do not execute any autorun commands | ➕ |
| Turn off Autoplay | Enabled: All drives | ➕ |
| **User Configuration\Administrative Templates\Windows Components\Attachment Manager** | | |
| Do not preserve zone information in file attachments | Disabled | ➕ |
| Hide mechanisms to remove zone information | Enabled | ➕ |
| **Computer Configuration\Administrative Templates\Windows Components\OneDrive** | | |
| Prevent the usage of OneDrive for file storage | Enabled | ⛔ Công ty dùng OneDrive (KFM, thư viện SharePoint) và giới hạn theo `AllowTenantList` thay vì cấm hẳn |
| **Computer Configuration\Administrative Templates\Windows Components\Microsoft account** | | |
| Block all consumer Microsoft account user authentication | Enabled | ➕ (chỉ chặn tài khoản cá nhân, không ảnh hưởng tài khoản công ty) |
| **Computer Configuration\Administrative Templates\Windows Components\App runtime** | | |
| Allow Microsoft accounts to be optional | Enabled | ➕ |
| **Application control** | Xây ruleset từ đầu, không dựa trên danh sách file đang có trên máy; rà soát định kỳ | ⚠️ Công ty dùng SRP gộp từ 11 GPO (mục 3.3 của tài liệu cập nhật), cần rà lại các rule gắn domain cũ, tên người dùng và rule quá rộng |

## B. Microsoft Office, nhóm ưu tiên cao (High)

| Chính sách / Registry | Khuyến nghị ACSC | Tình trạng |
|---|---|---|
| **HKCU\Software\Microsoft\Office\16.0\Excel\Security** | | |
| `DataConnectionWarnings` | REG_DWORD 2 | ➕ |
| `RichDataConnectionWarnings` | REG_DWORD 2 | ➕ |
| `WorkbookLinkWarnings` | REG_DWORD 2 | ➕ |
| `PackagerPrompt` (chặn kích hoạt OLE package) | REG_DWORD 2 | ➕ |
| **HKCU\Software\Microsoft\Office\16.0\Word\Security** | | |
| `AllowDDE` | REG_DWORD 0 | ➕ |
| `PackagerPrompt` | REG_DWORD 2 | ➕ |
| **HKCU\Software\Microsoft\Office\16.0\PowerPoint\Security** | | |
| `PackagerPrompt` | REG_DWORD 2 | ➕ |
| **User Configuration\Administrative Templates\Microsoft Excel 2016\Excel Options\Security\Trust Center\External Content** | | |
| Always prevent untrusted Microsoft Query files from opening | Enabled | ➕ |
| Don't allow Dynamic Data Exchange (DDE) server launch in Excel | Enabled | ➕ |
| Don't allow Dynamic Data Exchange (DDE) server lookup in Excel | Enabled | ➕ |
| **User Configuration\Administrative Templates\Microsoft Word 2016\Word Options\Advanced** | | |
| Update automatic links at Open | Disabled | ➕ |
| **Computer Configuration\Administrative Templates\MS Security Guide** | | |
| Block Flash activation in Office documents | Block all activation | ➕ (Flash đã hết hỗ trợ từ 2020, có thể bỏ qua) |
| **Computer Configuration\...\Microsoft Defender Exploit Guard\Attack Surface Reduction** | | |
| Configure Attack Surface Reduction rules (6 rule Office: `BE9BA2D9-…`, `D4F940AB-…`, `3B576869-…`, `75668C1F-…`, `92E97FA1-…`, `26190899-…`) | Enabled, mỗi rule trạng thái 1 | ➕ |
| **Macros** | ACSC dẫn sang ấn phẩm riêng *Restricting Microsoft Office macros*, không nêu giá trị trong tài liệu này | ➕ Cần tra thêm ấn phẩm đó |

> Các khóa registry ở bảng B ACSC viết là cấu hình bằng *Group Policy preferences*. Local GPO không có preferences; ghi bằng `LGPO /t` được nhưng các khóa nằm ngoài đường dẫn `Policies` có thể không tự gỡ khi bỏ policy. Cần thử trên máy mẫu trước khi đưa vào template.

## C. Microsoft Office, nhóm ưu tiên trung bình (Medium), tất cả ở User Configuration

| Chính sách | Khuyến nghị ACSC | Tình trạng |
|---|---|---|
| **...\Microsoft Office 2016\Security Settings** | | |
| Disable All ActiveX | Enabled | ➕ |
| **...\Excel / PowerPoint / Project / Visio / Word 2016\...\Security\Trust Center** (Add-ins) | | |
| Disable Trust Bar Notification for unsigned application add-ins and block them | Enabled | ➕ |
| Require that application add-ins are signed by Trusted Publishers | Enabled | ➕ |
| *Phương án thay thế:* Disable all application add-ins | Enabled | ➕ |
| **...\Microsoft Excel 2016\Excel Options\Security** | | |
| Force file extension to match file type | Enabled: Always match file type | ➕ |
| **...\Excel / PowerPoint / Visio / Word 2016\...\Trust Center\File Block Settings** | | |
| Chặn các định dạng cũ (Excel 2/3/4/95/97-2003, dBase, Dif/Sylk, PowerPoint 97-2003, Visio cũ, Word 2 đến 2007 binary…) và Set default file block behavior | Enabled: Blocked files are not opened | ➕ |
| **...\Excel / PowerPoint / Word 2016\...\Security** | | |
| Turn off file validation | Disabled | ➕ |
| **...\Excel / PowerPoint / Word 2016\...\Trust Center\Protected View** | | |
| Do not open files from the Internet zone in Protected View | Disabled | ➕ |
| Do not open files in unsafe locations in Protected View | Disabled | ➕ |
| Turn off Protected View for attachments opened from Outlook | Disabled | ➕ |
| Set document behaviour if file validation fails | Enabled: Block files | ➕ |
| Always open untrusted database files in Protected View (chỉ Excel) | Enabled | ➕ |
| **...\Excel / PowerPoint / Visio / Word 2016\...\Trust Center** (Trusted Documents) | | |
| Turn off trusted documents | Enabled | ➕ |
| Turn off Trusted Documents on the network | Enabled | ➕ |

## D. Microsoft Office, nhóm ưu tiên thấp (Low)

| Chính sách | Khuyến nghị ACSC | Tình trạng |
|---|---|---|
| **User Configuration\Administrative Templates\Microsoft PowerPoint 2016 / Word 2016\...\Security** | | |
| Make hidden markup visible | Enabled | ➕ |
| **User Configuration\Administrative Templates\Microsoft Office 2016\Privacy\Trust Center** | | |
| Allow including screenshot with Office Feedback, Send Office Feedback, Send personal information, Enable Customer Experience Improvement Program, Automatically receive small updates | Disabled | ➕ |
| Configure the level of client software diagnostic data | Enabled | ➕ |
| Disable Opt-in Wizard on first run | Enabled | ➕ |

> Bảng C và D rút gọn tên đường dẫn bằng `...`. Danh sách đầy đủ từng định dạng File Block và từng đường dẫn nằm trong tài liệu ACSC gốc.
