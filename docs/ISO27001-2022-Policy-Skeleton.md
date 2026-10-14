# ISO/IEC 27001:2022 – Bộ khung chính sách song ngữ (Bilingual Policy Skeleton)

| | |
|---|---|
| **Mục đích** | Khung chính sách song ngữ Anh – Việt làm căn cứ cho các thay đổi Local Group Policies lần này |
| **Chuẩn tham chiếu** | ISO/IEC 27001:2022, Annex A (đối chiếu số hiệu với bản 2013 ở bảng dưới) |
| **Tài liệu thực thi** | [`Update-Local-Group-Policies.md`](Update-Local-Group-Policies.md) |
| **Tài liệu đối chiếu kỹ thuật** | [`ACSC-ASD-Reference.md`](ACSC-ASD-Reference.md) |
| **Trạng thái** | Bản nháp khung, cần lãnh đạo phê duyệt |

> **Lưu ý khi dùng:** nội dung các yêu cầu dưới đây là **khung soạn thảo do CNTT viết**, diễn đạt lại ý của từng kiểm soát, không phải trích nguyên văn tiêu chuẩn. Số hiệu và tên kiểm soát theo ISO/IEC 27001:2022 Annex A theo hiểu biết của người soạn; cần đối chiếu với bản tiêu chuẩn chính thức của công ty trước khi đưa vào hồ sơ chứng nhận. Mỗi khung cần được điều chỉnh theo thực tế công ty, gán người chịu trách nhiệm và phê duyệt trước khi ban hành.

## 1. Bảng đối chiếu: thay đổi lần này và kiểm soát ISO 27001:2022

| Kiểm soát 2022 | Tên (English / Tiếng Việt) | Bản 2013 tương ứng | Thay đổi liên quan trong đợt này |
|---|---|---|---|
| **5.1** | Policies for information security / Chính sách bảo mật thông tin | A5.1.1, A5.1.2 | Mục 10 Phê duyệt; mục 6 Kế hoạch |
| **5.10** | Acceptable use of information and other associated assets / Sử dụng chấp nhận được thông tin và tài sản liên quan | A8.1.3 | Mục 3.1B; yêu cầu Hide C: |
| **5.14** | Information transfer / Chuyển tải thông tin | A13.2.1 | Mục 3.1A, 3.2 |
| **5.15** | Access control / Kiểm soát truy cập | A9.1.1 | Mục 1, 3.1 |
| **5.18** | Access rights / Quyền truy cập | A9.2.2, A9.2.5, A9.2.6 | Mục TenantAutoMount (T7, runbook mục 3) |
| **5.23** | Information security for use of cloud services / Bảo mật thông tin khi sử dụng dịch vụ đám mây | A15.1.1, A15.1.2 (một phần) | Mục 3.1A, 3.2; runbook |
| **5.36** | Compliance with policies, rules and standards for information security / Tuân thủ chính sách, quy tắc và tiêu chuẩn bảo mật thông tin | A18.2.2, A18.2.3 | Mục 7, 5 bước 9 |
| **5.37** | Documented operating procedures / Thủ tục vận hành được ghi lại | A12.1.1 | Runbook; mục 5, 9 |
| **7.10** | Storage media / Phương tiện lưu trữ | A8.3.1 | Mục 3.1B |
| **8.1** | User endpoint devices / Thiết bị đầu cuối của người dùng | A6.2.1, A11.2.x (một phần) | Mục 1, 5 |
| **8.2** | Privileged access rights / Quyền truy cập đặc quyền | A9.2.3, A9.4.4 | Mục 3.1B, 3.3 |
| **8.3** | Information access restriction / Hạn chế truy cập thông tin | A9.4.1 | Mục 3.1B, 8 |
| **8.7** | Protection against malware / Bảo vệ chống phần mềm độc hại | A12.2.1 | Mục 3.3 |
| **8.9** | Configuration management / Quản lý cấu hình | A12.1.2, A12.5.1 (một phần) | T1 đến T4; file ACSC-ASD-Reference.md |
| **8.12** | Data leakage prevention / Ngăn ngừa rò rỉ dữ liệu | A8.3.1, A13.2.1 (một phần) | Mục 3.1 |
| **8.13** | Information backup / Sao lưu thông tin | A12.3.1 | Task mục 2 (KFM); runbook |
| **8.15** | Logging / Ghi nhật ký | A12.4.1 | Mục 3.1A, 9 |
| **8.19** | Installation of software on operational systems / Cài đặt phần mềm trên hệ thống vận hành | A12.5.1, A12.6.2 | Mục 3.3 |
| **8.32** | Change management / Quản lý thay đổi | A12.1.2, A14.2.2 | Mục 5, 6, 8 |

**Nhóm theo chủ đề của Annex A 2022:**

| Nhóm 2022 | Kiểm soát trong tài liệu này |
|---|---|
| 5. Tổ chức (Organizational) | 5.1, 5.10, 5.14, 5.15, 5.18, 5.23, 5.36, 5.37 |
| 7. Vật lý (Physical) | 7.10 |
| 8. Công nghệ (Technological) | 8.1, 8.2, 8.3, 8.7, 8.9, 8.12, 8.13, 8.15, 8.19, 8.32 |

> Annex A 2022 không có nhóm Con người (6) liên quan đến thay đổi này, nên không đưa vào. Việc phổ biến và đào tạo người dùng được nêu trong các khung 5.1, 5.10 và 8.32.

**Mục tài liệu không có kiểm soát tương ứng:** ghim OneDrive/SharePoint lên Quick Access là cải thiện trải nghiệm người dùng, không phải kiểm soát an ninh.

## 2. Các khung chính sách

### 5.1 – Policies for information security / Chính sách bảo mật thông tin

| | English | Tiếng Việt |
|---|---|---|
| **Mục tiêu** | Information security policy and topic-specific policies are defined, approved by management, published, communicated and reviewed. | Chính sách bảo mật thông tin và các chính sách theo chủ đề được xác định, phê duyệt bởi lãnh đạo, công bố, truyền đạt và rà soát. |
| 1 | An overarching information security policy is approved by top management and communicated to all personnel. | Chính sách bảo mật thông tin tổng thể được lãnh đạo cao nhất phê duyệt và truyền đạt tới toàn bộ nhân sự. |
| 2 | Topic-specific policies (access control, removable media, cloud services, software installation, backup, change management) are derived from it. | Các chính sách theo chủ đề (kiểm soát truy cập, phương tiện lưu trữ, dịch vụ đám mây, cài đặt phần mềm, sao lưu, quản lý thay đổi) được xây dựng từ chính sách tổng thể. |
| 3 | Each policy has an owner, a version, an approval record and a review date. | Mỗi chính sách có người chịu trách nhiệm, phiên bản, hồ sơ phê duyệt và ngày rà soát. |
| 4 | Policies are reviewed at planned intervals and after significant changes. | Chính sách được rà soát định kỳ và sau các thay đổi đáng kể. |
| 5 | Personnel acknowledge the policies relevant to their role. | Nhân sự xác nhận đã nhận và hiểu các chính sách liên quan đến vai trò của mình. |
| **Thực thi** | | Tài liệu "Cập nhật cấu hình Local Group Policies" là biện pháp thực thi, cần có chính sách cấp cao ở trên làm căn cứ và mục Phê duyệt (mục 10) được điền đủ. |

*Tham chiếu: bản 2013 A5.1.1, A5.1.2; tài liệu cập nhật: Mục 10 Phê duyệt; mục 6 Kế hoạch.*

### 5.10 – Acceptable use of information and other associated assets / Sử dụng chấp nhận được thông tin và tài sản liên quan

| | English | Tiếng Việt |
|---|---|---|
| **Mục tiêu** | Rules for acceptable use and handling of information and assets are identified, documented and implemented. | Quy tắc sử dụng chấp nhận được và xử lý thông tin, tài sản được xác định, ghi lại và thực thi. |
| 1 | An acceptable use policy defines permitted and prohibited use of company devices, accounts and data. | Chính sách sử dụng chấp nhận được quy định việc sử dụng được phép và bị cấm đối với thiết bị, tài khoản và dữ liệu của công ty. |
| 2 | Company documents are saved in company-managed cloud locations, not on local disks or personal storage. | Tài liệu công ty được lưu ở vị trí đám mây do công ty quản lý, không lưu trên ổ cục bộ hoặc nơi lưu trữ cá nhân. |
| 3 | Personnel read and acknowledge the policy on joining and at least annually. | Nhân sự đọc và xác nhận chính sách khi vào làm và ít nhất mỗi năm một lần. |
| 4 | Technical controls enforce the rules where feasible; exceptions are approved and recorded. | Biện pháp kỹ thuật được dùng để thực thi quy tắc khi khả thi; ngoại lệ phải được phê duyệt và ghi lại. |
| 5 | Violations are handled through the disciplinary process. | Vi phạm được xử lý theo quy trình kỷ luật. |
| **Thực thi** | | Thực thi bằng: Restrict saving on non-Cloud locations (Office), ẩn ổ C: (`NoDrives`). Ẩn ổ chỉ che hiển thị, muốn cấm thật cần thêm `NoViewOnDrive` hoặc chặn quyền ghi. |

*Tham chiếu: bản 2013 A8.1.3; tài liệu cập nhật: Mục 3.1B; yêu cầu Hide C:.*

### 5.14 – Information transfer / Chuyển tải thông tin

| | English | Tiếng Việt |
|---|---|---|
| **Mục tiêu** | Information transfer rules, procedures or agreements are in place for all types of transfer facilities. | Có quy tắc, thủ tục hoặc thỏa thuận chuyển tải thông tin cho mọi loại phương tiện chuyển tải. |
| 1 | The channels approved for transferring company information are defined (corporate OneDrive/SharePoint, corporate email). | Các kênh được phê duyệt để chuyển tải thông tin công ty được xác định (OneDrive/SharePoint, email của công ty). |
| 2 | Synchronisation of company data to non-approved organisations or personal accounts is blocked. | Việc đồng bộ dữ liệu công ty tới tổ chức không được phê duyệt hoặc tài khoản cá nhân bị chặn. |
| 3 | Transfer to external parties is subject to contractual and sharing controls. | Việc chia sẻ với bên ngoài chịu các kiểm soát về hợp đồng và quyền chia sẻ. |
| 4 | Sensitive information is protected in transit using approved methods. | Thông tin nhạy cảm được bảo vệ khi truyền bằng các phương pháp được phê duyệt. |
| 5 | Personnel are trained on safe transfer practices. | Nhân sự được đào tạo về cách chuyển tải thông tin an toàn. |
| **Thực thi** | | Thực thi bằng: Allow syncing OneDrive accounts for only specific organizations (`AllowTenantList`, 6 Tenant ID). Cần kiểm tra Tenant ID khớp danh sách chuẩn (KIA `6fcf7bf2-…`, LAV `fa0fc2b5-6ddc-…`). |

*Tham chiếu: bản 2013 A13.2.1; tài liệu cập nhật: Mục 3.1A, 3.2.*

### 5.15 – Access control / Kiểm soát truy cập

| | English | Tiếng Việt |
|---|---|---|
| **Mục tiêu** | Rules to control physical and logical access to information and assets are established and implemented based on business and security requirements. | Quy tắc kiểm soát truy cập vật lý và logic tới thông tin và tài sản được thiết lập và thực thi theo yêu cầu kinh doanh và bảo mật. |
| 1 | Access is granted on a need-to-know and least-privilege basis. | Quyền truy cập được cấp theo nguyên tắc cần biết và đặc quyền tối thiểu. |
| 2 | Policy scope distinguishes administrators from standard users and states which controls apply to each group. | Chính sách phân biệt quản trị viên với người dùng thường và nêu rõ biện pháp nào áp dụng cho nhóm nào. |
| 3 | Access rules are aligned with the information classification scheme. | Quy tắc truy cập phù hợp với sơ đồ phân loại thông tin. |
| 4 | Exceptions to the policy are formally approved and documented. | Ngoại lệ so với chính sách phải được phê duyệt chính thức và ghi lại. |
| 5 | The policy is reviewed at least annually. | Chính sách được rà soát ít nhất mỗi năm một lần. |
| **Thực thi** | | Local GPO chia hai nhánh: Computer Configuration – All Users và User Configuration – Non-Administrators. Cần ghi rõ lý do admin không bị áp các hạn chế USB, SRP. |

*Tham chiếu: bản 2013 A9.1.1; tài liệu cập nhật: Mục 1, 3.1.*

### 5.18 – Access rights / Quyền truy cập

| | English | Tiếng Việt |
|---|---|---|
| **Mục tiêu** | Access rights to information and assets are provisioned, reviewed, modified and removed in accordance with the access control policy. | Quyền truy cập thông tin và tài sản được cấp phát, rà soát, điều chỉnh và thu hồi theo chính sách kiểm soát truy cập. |
| 1 | Access to shared libraries and sites is requested and approved by the data owner. | Quyền truy cập thư viện, site dùng chung được yêu cầu và phê duyệt bởi chủ sở hữu dữ liệu. |
| 2 | Automatic mounting or syncing of a library does not replace permission control at the source. | Việc tự động mount hoặc đồng bộ thư viện không thay thế việc kiểm soát quyền tại nguồn. |
| 3 | Access rights are reviewed periodically and revoked when roles change or personnel leave. | Quyền truy cập được rà soát định kỳ và thu hồi khi đổi vai trò hoặc nghỉ việc. |
| 4 | Provisioning and removal are recorded. | Việc cấp phát và thu hồi được ghi nhận. |
| 5 | Guest or cross-tenant accounts are approved individually. | Tài khoản khách hoặc liên tenant được phê duyệt từng trường hợp. |
| **Thực thi** | | Thực thi bằng: `TenantAutoMount` (14 thư viện KIA) chỉ tự đồng bộ thư viện; người dùng chỉ thấy dữ liệu khi SharePoint đã cấp quyền. Máy thuộc tenant phụ cần bộ thư viện riêng. |

*Tham chiếu: bản 2013 A9.2.2, A9.2.5, A9.2.6; tài liệu cập nhật: Mục TenantAutoMount (T7, runbook mục 3).*

### 5.23 – Information security for use of cloud services / Bảo mật thông tin khi sử dụng dịch vụ đám mây

| | English | Tiếng Việt |
|---|---|---|
| **Mục tiêu** | Processes for acquisition, use, management and exit from cloud services are established in line with security requirements. | Quy trình mua sắm, sử dụng, quản lý và chấm dứt dịch vụ đám mây được thiết lập theo yêu cầu bảo mật. |
| 1 | Approved cloud services and their tenants are listed; use of other services for company data is prohibited. | Các dịch vụ đám mây và tenant được phê duyệt được liệt kê; cấm dùng dịch vụ khác cho dữ liệu công ty. |
| 2 | Responsibilities between the company and the provider (retention, backup, recovery) are defined. | Trách nhiệm giữa công ty và nhà cung cấp (lưu giữ, sao lưu, khôi phục) được xác định. |
| 3 | Cloud configuration (sync, sharing, known folder move) is standardised and monitored. | Cấu hình dịch vụ đám mây (đồng bộ, chia sẻ, chuyển thư mục hệ thống) được chuẩn hóa và giám sát. |
| 4 | Each member company's tenant is documented, with an owner. | Tenant của từng công ty thành viên được ghi lại, có người chịu trách nhiệm. |
| 5 | Exit and data-return procedures are defined. | Quy trình chấm dứt dịch vụ và trả dữ liệu được xác định. |
| **Thực thi** | | Thực thi bằng: `AllowTenantList`, KFM theo tenant (`T8`, `L8_KFM_<TEN>`), `SilentAccountConfig`. Lưu ý ACSC khuyến nghị cấm hẳn OneDrive; công ty dùng có kiểm soát, đây là lệch có chủ đích cần ghi lý do. |

*Tham chiếu: bản 2013 A15.1.1, A15.1.2 (một phần); tài liệu cập nhật: Mục 3.1A, 3.2; runbook.*

### 5.36 – Compliance with policies, rules and standards for information security / Tuân thủ chính sách, quy tắc và tiêu chuẩn bảo mật thông tin

| | English | Tiếng Việt |
|---|---|---|
| **Mục tiêu** | Compliance with the organisation's policies, rules and standards is regularly reviewed. | Việc tuân thủ chính sách, quy tắc và tiêu chuẩn của tổ chức được rà soát thường xuyên. |
| 1 | Technical compliance checks are performed at defined intervals using approved tools. | Kiểm tra tuân thủ kỹ thuật được thực hiện định kỳ bằng công cụ được phê duyệt. |
| 2 | Results are recorded per device: compliant, failed, with remediation. | Kết quả được ghi theo từng máy: đạt, lỗi, kèm hướng xử lý. |
| 3 | Deviations from the baseline are approved exceptions or are remediated within defined timeframes. | Sai lệch so với chuẩn là ngoại lệ được duyệt hoặc được khắc phục trong thời hạn quy định. |
| 4 | Reviews are done by personnel independent of the configuration owner where practical. | Rà soát do người độc lập với người quản lý cấu hình thực hiện khi có thể. |
| 5 | Findings are reported to management. | Kết quả được báo cáo cho lãnh đạo. |
| **Thực thi** | | Thực thi bằng: kiểm tra registry sau khi áp (`reg query …KFMSilentOptIn`, `…TenantAutoMount`), log `deploy.log`, `kfm.log`, danh sách máy thành công/lỗi (mục 7 nghiệm thu). |

*Tham chiếu: bản 2013 A18.2.2, A18.2.3; tài liệu cập nhật: Mục 7, 5 bước 9.*

### 5.37 – Documented operating procedures / Thủ tục vận hành được ghi lại

| | English | Tiếng Việt |
|---|---|---|
| **Mục tiêu** | Operating procedures for information processing facilities are documented and made available to personnel who need them. | Thủ tục vận hành cho các cơ sở xử lý thông tin được ghi lại và cung cấp cho nhân sự cần dùng. |
| 1 | Procedures exist for deployment, verification, rollback and troubleshooting of endpoint policies. | Có thủ tục cho triển khai, kiểm tra, quay lui và xử lý sự cố chính sách trên máy trạm. |
| 2 | Procedures state prerequisites, order of steps and expected results. | Thủ tục nêu điều kiện tiên quyết, thứ tự các bước và kết quả mong đợi. |
| 3 | Procedures are kept current and stored where support staff can find them. | Thủ tục được cập nhật và lưu ở nơi nhân viên hỗ trợ dễ tìm. |
| 4 | Changes to procedures are approved and communicated. | Thay đổi thủ tục được phê duyệt và thông báo. |
| 5 | Procedures include fault handling and escalation. | Thủ tục gồm xử lý lỗi và chuyển cấp. |
| **Thực thi** | | Tài liệu hiện có: `A/readme.md`, `docs/Helpdesk-Runbook.md`, mục 9 Giải quyết sự cố SRP, bảng lỗi thường gặp. Thứ tự cố định: T3, rồi L8, rồi TenantAutoMount. |

*Tham chiếu: bản 2013 A12.1.1; tài liệu cập nhật: Runbook; mục 5, 9.*

### 7.10 – Storage media / Phương tiện lưu trữ

| | English | Tiếng Việt |
|---|---|---|
| **Mục tiêu** | Storage media are managed through their lifecycle of acquisition, use, transportation and disposal in line with the classification scheme. | Phương tiện lưu trữ được quản lý trong suốt vòng đời mua sắm, sử dụng, vận chuyển và hủy bỏ theo sơ đồ phân loại. |
| 1 | Permitted types of removable media are defined; personal removable media on company devices is restricted. | Các loại phương tiện lưu trữ rời được phép được xác định; hạn chế phương tiện cá nhân trên thiết bị công ty. |
| 2 | Writing company data to USB, optical, tape and portable devices is blocked for standard users unless approved. | Ghi dữ liệu công ty ra USB, đĩa quang, băng từ và thiết bị di động bị chặn với người dùng thường trừ khi được phê duyệt. |
| 3 | Approved exceptions are recorded with owner and expiry. | Ngoại lệ được duyệt được ghi lại kèm người chịu trách nhiệm và thời hạn. |
| 4 | Removable media with sensitive data is encrypted and inventoried. | Phương tiện rời chứa dữ liệu nhạy cảm được mã hóa và kiểm kê. |
| 5 | Media is scanned for malware before use. | Phương tiện được quét mã độc trước khi sử dụng. |
| **Thực thi** | | Thực thi bằng: Deny write access cho Removable Disks, CD/DVD, Tape Drives, WPD Devices (Non-Administrators). Theo ACSC nên thêm Deny execute và Autoplay/AutoRun tắt (xem `ACSC-ASD-Reference.md`). |

*Tham chiếu: bản 2013 A8.3.1; tài liệu cập nhật: Mục 3.1B.*

### 8.1 – User endpoint devices / Thiết bị đầu cuối của người dùng

| | English | Tiếng Việt |
|---|---|---|
| **Mục tiêu** | Information stored on, processed by or accessible via user endpoint devices is protected. | Thông tin lưu trên, xử lý bởi hoặc truy cập qua thiết bị đầu cuối của người dùng được bảo vệ. |
| 1 | A security baseline is defined for company endpoints and applied consistently. | Cấu hình bảo mật chuẩn được xác định cho máy trạm công ty và áp dụng nhất quán. |
| 2 | Standard users do not hold local administrator rights. | Người dùng thường không có quyền quản trị cục bộ. |
| 3 | The baseline applies to domain, Entra-joined and workgroup devices alike. | Cấu hình chuẩn áp dụng như nhau cho máy domain, Entra joined và Workgroup. |
| 4 | Device configuration is restored after domain exit, re-imaging or policy loss. | Cấu hình máy được khôi phục sau khi thoát domain, cài lại hoặc mất policy. |
| 5 | Lost or stolen devices are reported and handled per incident procedure. | Thiết bị mất hoặc bị đánh cắp được báo cáo và xử lý theo quy trình sự cố. |
| **Thực thi** | | Thực thi bằng: Local GPO template (`T3`) triển khai qua Action1; thoát domain thì chạy lại T3, rồi L8, rồi TenantAutoMount (xem phần trả lời trước và runbook). |

*Tham chiếu: bản 2013 A6.2.1, A11.2.x (một phần); tài liệu cập nhật: Mục 1, 5.*

### 8.2 – Privileged access rights / Quyền truy cập đặc quyền

| | English | Tiếng Việt |
|---|---|---|
| **Mục tiêu** | The allocation and use of privileged access rights is restricted and managed. | Việc cấp phát và sử dụng quyền truy cập đặc quyền được hạn chế và quản lý. |
| 1 | Privileged accounts are separate from daily-use accounts. | Tài khoản đặc quyền tách biệt với tài khoản dùng hằng ngày. |
| 2 | Privileged rights are granted by approval and reviewed periodically. | Quyền đặc quyền được cấp khi có phê duyệt và rà soát định kỳ. |
| 3 | Controls aimed at standard users are not silently bypassed by administrators. | Các biện pháp áp cho người dùng thường không bị quản trị viên vô tình bỏ qua. |
| 4 | Use of privileged accounts is logged. | Việc sử dụng tài khoản đặc quyền được ghi nhật ký. |
| 5 | Exceptions where administrators are exempt are documented. | Các trường hợp quản trị viên được miễn áp dụng phải được ghi lại. |
| **Thực thi** | | Nhánh Non-Administrators nghĩa là admin không bị SRP, chặn USB, ẩn ổ C:. Cần ghi nhận đây là chủ ý và kiểm soát việc cấp quyền admin ở nơi khác. |

*Tham chiếu: bản 2013 A9.2.3, A9.4.4; tài liệu cập nhật: Mục 3.1B, 3.3.*

### 8.3 – Information access restriction / Hạn chế truy cập thông tin

| | English | Tiếng Việt |
|---|---|---|
| **Mục tiêu** | Access to information and other associated assets is restricted in accordance with the access control policy. | Quyền truy cập thông tin và tài sản liên quan được hạn chế theo chính sách kiểm soát truy cập. |
| 1 | Access to data and functions is limited by role and least privilege. | Quyền truy cập dữ liệu và chức năng được giới hạn theo vai trò và đặc quyền tối thiểu. |
| 2 | Users cannot reach data or functions beyond their authorised scope. | Người dùng không thể truy cập dữ liệu hoặc chức năng ngoài phạm vi được phép. |
| 3 | Local storage locations are restricted where company data must remain in managed cloud storage. | Nơi lưu cục bộ bị hạn chế khi dữ liệu công ty phải nằm trong kho đám mây được quản lý. |
| 4 | Role definitions are reviewed when business processes change. | Định nghĩa vai trò được rà soát khi quy trình kinh doanh thay đổi. |
| 5 | Restrictions are tested before wide deployment. | Các hạn chế được thử nghiệm trước khi triển khai diện rộng. |
| **Thực thi** | | Thực thi bằng: Restrict saving on non-Cloud locations; ẩn ổ C:. Thử trước trên nhóm máy mẫu vì có thể ảnh hưởng thói quen lưu file (mục 8 rủi ro). |

*Tham chiếu: bản 2013 A9.4.1; tài liệu cập nhật: Mục 3.1B, 8.*

### 8.7 – Protection against malware / Bảo vệ chống phần mềm độc hại

| | English | Tiếng Việt |
|---|---|---|
| **Mục tiêu** | Protection against malware is implemented and supported by appropriate user awareness. | Biện pháp bảo vệ chống mã độc được triển khai và hỗ trợ bởi nhận thức phù hợp của người dùng. |
| 1 | Anti-malware and application control are deployed on all endpoints where feasible. | Phần mềm chống mã độc và kiểm soát ứng dụng được triển khai trên mọi máy trạm khi khả thi. |
| 2 | Only approved applications run for standard users; blocked execution is logged. | Chỉ ứng dụng được phê duyệt chạy với người dùng thường; việc chặn thực thi được ghi nhật ký. |
| 3 | Removable media and AutoRun are controlled. | Phương tiện lưu trữ rời và AutoRun được kiểm soát. |
| 4 | Office features that run external or embedded code (macros, DDE, OLE) are restricted. | Các tính năng Office chạy mã ngoài hoặc mã nhúng (macro, DDE, OLE) bị hạn chế. |
| 5 | Personnel are trained to recognise and report suspicious files. | Nhân sự được đào tạo nhận biết và báo cáo tệp đáng ngờ. |
| **Thực thi** | | Thực thi bằng: SRP (mục 3.3). Các biện pháp Office (DDE, macro, OLE) và Autoplay chưa triển khai, đang nằm trong `ACSC-ASD-Reference.md` để cân nhắc giai đoạn sau. |

*Tham chiếu: bản 2013 A12.2.1; tài liệu cập nhật: Mục 3.3.*

### 8.9 – Configuration management / Quản lý cấu hình

| | English | Tiếng Việt |
|---|---|---|
| **Mục tiêu** | Configurations, including security configurations, of hardware, software, services and networks are established, documented, implemented, monitored and reviewed. | Cấu hình, gồm cấu hình bảo mật, của phần cứng, phần mềm, dịch vụ và mạng được thiết lập, ghi lại, triển khai, giám sát và rà soát. |
| 1 | A baseline configuration (policy template) is defined, versioned and stored in a controlled repository. | Cấu hình chuẩn (template policy) được xác định, có phiên bản và lưu ở kho được kiểm soát. |
| 2 | The template's integrity is verified before deployment (hash check). | Tính toàn vẹn của template được kiểm tra trước khi triển khai (kiểm hash). |
| 3 | The current state of each device is backed up before a change so it can be restored. | Hiện trạng từng máy được sao lưu trước khi thay đổi để có thể khôi phục. |
| 4 | Deviations per company or tenant are documented and limited to defined items. | Khác biệt theo công ty hoặc tenant được ghi lại và giới hạn ở các mục xác định. |
| 5 | Baselines are reviewed at least annually and against external guidance. | Cấu hình chuẩn được rà soát ít nhất mỗi năm và đối chiếu với hướng dẫn bên ngoài. |
| **Thực thi** | | Thực thi bằng: `T1` backup template, `T2` upload kèm `.sha256`, `T3` kiểm SHA256 và backup `PreDeploy-*`. Đối chiếu ngoài: ACSC/ASD (`ACSC-ASD-Reference.md`), Microsoft Security Baseline có trong repo. |

*Tham chiếu: bản 2013 A12.1.2, A12.5.1 (một phần); tài liệu cập nhật: T1 đến T4; file ACSC-ASD-Reference.md.*

### 8.12 – Data leakage prevention / Ngăn ngừa rò rỉ dữ liệu

| | English | Tiếng Việt |
|---|---|---|
| **Mục tiêu** | Data leakage prevention measures are applied to systems, networks and devices that process, store or transmit sensitive information. | Biện pháp ngăn ngừa rò rỉ dữ liệu được áp dụng cho hệ thống, mạng và thiết bị xử lý, lưu trữ hoặc truyền thông tin nhạy cảm. |
| 1 | Channels through which data could leave the company are identified (USB, personal cloud, email, other tenants). | Các kênh có thể làm dữ liệu rời công ty được xác định (USB, đám mây cá nhân, email, tenant khác). |
| 2 | Technical controls block or restrict those channels for standard users. | Biện pháp kỹ thuật chặn hoặc hạn chế các kênh đó với người dùng thường. |
| 3 | Synchronisation is limited to approved tenants. | Đồng bộ chỉ giới hạn ở các tenant được phê duyệt. |
| 4 | Blocked attempts and policy health are monitored. | Các nỗ lực bị chặn và tình trạng policy được giám sát. |
| 5 | Users are informed of the rules and of how to request an exception. | Người dùng được thông báo về quy tắc và cách xin ngoại lệ. |
| **Thực thi** | | Thực thi bằng: Deny write (USB và thiết bị rời), `AllowTenantList`, Restrict saving on non-Cloud locations. |

*Tham chiếu: bản 2013 A8.3.1, A13.2.1 (một phần); tài liệu cập nhật: Mục 3.1.*

### 8.13 – Information backup / Sao lưu thông tin

| | English | Tiếng Việt |
|---|---|---|
| **Mục tiêu** | Backup copies of information, software and systems are maintained and regularly tested in accordance with the agreed backup policy. | Bản sao lưu thông tin, phần mềm và hệ thống được duy trì và kiểm tra định kỳ theo chính sách sao lưu đã thống nhất. |
| 1 | A backup policy defines what is backed up, how often and for how long. | Chính sách sao lưu xác định sao lưu gì, tần suất và thời gian lưu giữ. |
| 2 | User working folders (Desktop, Documents, Pictures) are redirected to company cloud storage. | Thư mục làm việc của người dùng (Desktop, Documents, Pictures) được chuyển lên kho đám mây công ty. |
| 3 | Cloud synchronisation is not treated as backup unless retention and restore are defined and tested. | Đồng bộ đám mây không được coi là sao lưu nếu chưa xác định và kiểm thử lưu giữ, khôi phục. |
| 4 | Restore tests are performed at planned intervals. | Kiểm thử khôi phục được thực hiện định kỳ. |
| 5 | Backup failures are monitored and followed up. | Lỗi sao lưu được giám sát và xử lý. |
| **Thực thi** | | Thực thi bằng: KFM (`KFMSilentOptIn`). Cần xác nhận cấu hình lưu giữ và khôi phục phiên bản của OneDrive/SharePoint, và máy còn Folder Redirection cũ phải gỡ trước. |

*Tham chiếu: bản 2013 A12.3.1; tài liệu cập nhật: Task mục 2 (KFM); runbook.*

### 8.15 – Logging / Ghi nhật ký

| | English | Tiếng Việt |
|---|---|---|
| **Mục tiêu** | Logs that record activities, exceptions, faults and other relevant events are produced, stored, protected and analysed. | Nhật ký ghi lại hoạt động, ngoại lệ, lỗi và sự kiện liên quan được tạo, lưu, bảo vệ và phân tích. |
| 1 | Security-relevant events are logged on endpoints and central services. | Sự kiện liên quan bảo mật được ghi nhật ký trên máy trạm và dịch vụ trung tâm. |
| 2 | Application-control blocks are logged and reviewed. | Việc chặn ứng dụng của application control được ghi nhật ký và rà soát. |
| 3 | Synchronisation health is reported to a central dashboard. | Tình trạng đồng bộ được báo cáo về dashboard tập trung. |
| 4 | Deployment actions are logged with time, device and result. | Hoạt động triển khai được ghi lại kèm thời gian, thiết bị và kết quả. |
| 5 | Logs are protected against alteration and retained per policy. | Nhật ký được bảo vệ chống sửa đổi và lưu giữ theo chính sách. |
| **Thực thi** | | Thực thi bằng: Enable sync health reporting for OneDrive, Event ID 865 của SRP (mục 9), `deploy.log`, `kfm.log`. |

*Tham chiếu: bản 2013 A12.4.1; tài liệu cập nhật: Mục 3.1A, 9.*

### 8.19 – Installation of software on operational systems / Cài đặt phần mềm trên hệ thống vận hành

| | English | Tiếng Việt |
|---|---|---|
| **Mục tiêu** | Procedures and measures are implemented to securely manage the installation of software on operational systems. | Quy trình và biện pháp được triển khai để quản lý an toàn việc cài đặt phần mềm trên hệ thống vận hành. |
| 1 | Only approved and licensed software is installed or run on company devices. | Chỉ phần mềm được phê duyệt và có bản quyền được cài hoặc chạy trên thiết bị công ty. |
| 2 | Standard users cannot install unauthorised software; the Microsoft Store is blocked where not required. | Người dùng thường không thể cài phần mềm trái phép; Microsoft Store bị chặn khi không cần. |
| 3 | Application whitelisting or software restriction policy is applied and maintained. | Danh sách trắng ứng dụng hoặc chính sách hạn chế phần mềm được áp dụng và duy trì. |
| 4 | New software requests are assessed for security risk before approval. | Yêu cầu phần mềm mới được đánh giá rủi ro bảo mật trước khi duyệt. |
| 5 | Rules tied to retired infrastructure, individual users or temporary files are removed. | Các rule gắn với hạ tầng đã bỏ, cá nhân cụ thể hoặc tệp tạm được loại bỏ. |
| **Thực thi** | | Thực thi bằng: SRP 51 Unrestricted, 1 Disallowed, 1 Hash Rule. Cần rà lại rule domain cũ (`kiena.local`, `%USERDNSDOMAIN%`), tên người dùng, `PSScriptPolicyTest`, `F:\*\*\*\*`. ACSC khuyên xây ruleset từ đầu. |

*Tham chiếu: bản 2013 A12.5.1, A12.6.2; tài liệu cập nhật: Mục 3.3.*

### 8.32 – Change management / Quản lý thay đổi

| | English | Tiếng Việt |
|---|---|---|
| **Mục tiêu** | Changes to information processing facilities and information systems are subject to change management procedures. | Thay đổi đối với cơ sở xử lý thông tin và hệ thống thông tin phải tuân theo quy trình quản lý thay đổi. |
| 1 | Each change is requested, assessed for security impact and approved before deployment. | Mỗi thay đổi được yêu cầu, đánh giá tác động bảo mật và phê duyệt trước khi triển khai. |
| 2 | Changes are piloted on a small test group before wide rollout. | Thay đổi được thử trên nhóm máy mẫu nhỏ trước khi triển khai rộng. |
| 3 | A rollback plan is prepared and tested. | Kế hoạch quay lui được chuẩn bị và kiểm thử. |
| 4 | Affected users are informed in advance. | Người dùng bị ảnh hưởng được thông báo trước. |
| 5 | Results, failed devices and follow-up are recorded. | Kết quả, máy lỗi và việc xử lý tiếp theo được ghi lại. |
| **Thực thi** | | Thực thi bằng: nhóm Test trước (L3 rồi L8), `T4` quay về `PreDeploy-*`, thông báo người dùng đăng xuất/đăng nhập lại, mục 6 Kế hoạch và mục 10 Phê duyệt. Việc thoát domain cũng là thay đổi lớn cần qua quy trình này. |

*Tham chiếu: bản 2013 A12.1.2, A14.2.2; tài liệu cập nhật: Mục 5, 6, 8.*

## 3. Việc cần làm để hoàn thiện hồ sơ

| # | Việc | Người phụ trách | Hạn |
|---|---|---|---|
| 1 | Đối chiếu số hiệu và tên kiểm soát với bản ISO/IEC 27001:2022 chính thức | *(điền)* | *(điền)* |
| 2 | Chọn khung cần ban hành thành chính sách chính thức (tối thiểu 5.1, 5.15, 7.10, 8.7/8.19, 8.32) | *(điền)* | *(điền)* |
| 3 | Gán người chịu trách nhiệm và chu kỳ rà soát cho từng chính sách | *(điền)* | *(điền)* |
| 4 | Ghi vào Statement of Applicability (SoA) lý do áp dụng, ngoại lệ (OneDrive dùng có kiểm soát, SRP thay vì WDAC/AppLocker) | *(điền)* | *(điền)* |
| 5 | Lãnh đạo phê duyệt, công bố và truyền đạt tới toàn bộ nhân sự | *(điền)* | *(điền)* |
