Thu muc chua nguon tham khao tu MS


## Nguồn tham khảo cho Windows (Microsoft công bố)

File `office2016grouppolicyandoctsettings.xlsx` ở đây là bảng tham chiếu **ADMX của Office 2016** (cột: File Name, Policy Setting Name, Scope, Policy Path, Registry Information, Default Setting, Supported On, Help Text). Microsoft công bố bảng tương tự cho **Windows**:

| Nguồn | Nội dung | Tải |
|---|---|---|
| Group Policy Settings Reference Spreadsheet – **Windows 11 26H2** | Toàn bộ policy Administrative Templates (Computer/User) của Win11, có Registry key/value, Supported On | https://www.microsoft.com/en-us/download/details.aspx?id=108849 |
| …Windows 11 25H2 / 24H2 | Bản trước của Win11 | https://www.microsoft.com/en-us/download/details.aspx?id=108395 / https://www.microsoft.com/en-us/download/details.aspx?id=106255 |
| …Windows 10 21H2 | Bản Win10 mới nhất có spreadsheet riêng (22H2 dùng chung bộ ADMX) | https://www.microsoft.com/en-us/download/details.aspx?id=103668 |
| Administrative Templates (.admx) Windows 11 25H2 | File ADMX/ADML đi kèm bảng trên (dùng cho gpedit/Central Store) | https://www.microsoft.com/en-us/download/details.aspx?id=108394 |
| Group Policy Settings Reference for Windows and Windows Server (bản cũ) | Tham chiếu chung cho Win/Server thế hệ cũ | https://www.microsoft.com/en-us/download/details.aspx?id=25250 |
| **Security Baseline** (đã có trong repo, thư mục gốc `*Security Baseline.zip`) | `Documentation\MS Security Baseline ... .xlsx` (giá trị khuyến nghị của MS cho Security Options, User Rights, Audit, Account Policy), `*.PolicyRules` (mở bằng Policy Analyzer), `Delta.xlsx` (khác biệt giữa các bản) | có sẵn trong repo; mới nhất: https://learn.microsoft.com/windows/security/operating-system-security/device-management/windows-security-configuration-framework/windows-security-baselines |
| Security policy settings reference (Learn) | **Account Policy, Local Policy, User Rights Assignment, Security Options, Audit** — phần *không* nằm trong ADMX nên không có trong spreadsheet ở trên (đây là nội dung của `GptTmpl.inf`/`audit.csv` trong template) | https://learn.microsoft.com/previous-versions/windows/it-pro/windows-10/security/threat-protection/security-policy-settings/security-policy-settings |

Phân công nguồn cho template: **registry.pol** (Administrative Templates) ↔ spreadsheet Windows 11/10; **GptTmpl.inf + audit.csv** (Security Settings, Audit) ↔ Security Baseline xlsx + trang Learn; **Office** ↔ file xlsx hiện có. `Templates/Template-Compare.csv` là phần nhỏ trích từ template của bạn để đối chiếu với các nguồn này.
