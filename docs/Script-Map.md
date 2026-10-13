# Script Map: vòng đời phát triển và deploy LGPO template (kiểu CI/CD)

Bảng chi tiết từng script (cột `Repo | Action 1 | Usage | Note`): [`Script-Map.csv`](Script-Map.csv).
Hướng dẫn thao tác cho Helpdesk (cấu hình chung tự động và cấu hình đặc thù của từng công ty thành viên, tenant phụ): [`Helpdesk-Runbook.md`](Helpdesk-Runbook.md).

Bốn cột (lane) của quy trình:

| Cột | Vai trò | Tương đương DevOps |
|---|---|---|
| **A. Máy mẫu** | Laptop 655: cấu hình tay, test, đóng gói | Dev + Build agent |
| **B. Repo** | GitHub `JaxVN/LGPO`: script, file mẫu, ZIP template, LGPO.zip | Source control + Artifact registry |
| **C. Action1** | Điều phối: automation, nhóm máy (Test / Prod), nhận exit code | Release pipeline / orchestrator |
| **D. Clients** | Máy người dùng (Workgroup hoặc Entra ID joined), SYSTEM | Môi trường Staging / Production |

## 1. Vòng đời tổng quát (Build → Publish → Canary → Release)

```mermaid
flowchart LR
    Plan["Plan / Code<br/>máy mẫu + PR vào main"] --> Build["Build<br/>T1 trên máy mẫu"]
    Build --> Publish["Publish<br/>T2 lên Templates/Win10|Win11"]
    Publish --> Canary["Canary<br/>L3 + L8 nhóm Test"]
    Canary -->|OK| Release["Release<br/>L3 + L8 toàn bộ clients"]
    Canary -->|lỗi| Rollback["Rollback<br/>L4 chạy T4"]
    Release --> Operate["Operate<br/>log + exit code"]
    Operate --> Plan
    Rollback --> Plan
```

## 2. Deploy cho Clients: cần những script nào

Áp dụng cho cả Canary và Release. Hình thể hiện từng cột: **C Action1** gọi launcher, launcher tải script từ **B Repo**, script chạy trên **D Clients**.

```mermaid
flowchart TB
    subgraph C["C. Action1"]
        direction TB
        C1["Chọn nhóm máy<br/>Test hoặc Prod"]
        C2["L3_Run_T3.ps1<br/>(Win10 ép Win11: L3b_Run_T3_Win11.ps1)"]
        C3["L8_KFM_SNP|KSL|LAV|CIT|DTC.ps1<br/>chỉ nhóm máy tenant phụ<br/>(máy KIA: bỏ qua, template đã đúng)"]
        C4["L4_Run_T4.ps1<br/>Rollback"]
    end

    subgraph B["B. Repo (GitHub, nhánh main)"]
        direction TB
        B1["A/T3_Deploy_Template.ps1"]
        B2["LGPO.zip"]
        B3["Templates/Win10|Win11/<br/>GPO-Template.zip + .sha256"]
        B4["A/T8_Apply_OneDrive_KFM.ps1"]
        B5["Policies/OneDrive-KFM-lgpo.txt"]
        B6["A/T4_Rollback_PreDeploy.ps1"]
    end

    subgraph D["D. Clients (SYSTEM)"]
        direction TB
        D1["T3.1 cài LGPO.exe nếu thiếu<br/>C:\\Soft\\SCT\\LGPO_30"]
        D2["T3.2 kiểm SHA256<br/>sai hash: dừng, exit 1<br/>không đổi so với lần trước: bỏ qua"]
        D3["T3.3 backup hiện trạng<br/>C:\\Soft\\GPO-Backup\\PreDeploy-*"]
        D4["T3.4 xóa Registry.pol cũ<br/>LGPO /g, /un, /ua, gpupdate"]
        D5["T8.1 lấy Tenant ID<br/>KFM_TENANT hoặc dsregcmd<br/>sai tenant: dừng, exit 1"]
        D6["T8.2 thay Tenant ID<br/>LGPO /t, gpupdate<br/>kiểm registry KFMSilentOptIn"]
        D7["User đăng xuất/đăng nhập lại<br/>(SRP: khởi động lại máy)"]
        D8["T4: LGPO /g bản PreDeploy mới nhất"]
    end

    C1 --> C2
    C2 -->|tải T3| B1
    B1 --> D1
    B2 -.-> D1
    D1 --> D2
    B3 -.-> D2
    D2 --> D3 --> D4
    D4 -->|"exit 0 (sau T3 mới chạy L8)"| C3
    C3 -->|tải T8| B4
    B4 --> D5
    B5 -.-> D6
    D5 --> D6 --> D7
    D4 -.->|"exit 1"| C4
    D6 -.->|"exit 1"| C4
    C4 -->|tải T4| B6
    B6 --> D8
```

### Bảng script theo từng bước deploy

| Bước | Chạy ở | Script (Action1) | Script (Repo) | File / artifact dùng | Kết quả |
|---|---|---|---|---|---|
| 1. Deploy template | Clients | `A/L3_Run_T3.ps1` | `A/T3_Deploy_Template.ps1` | `LGPO.zip`, `Templates/<OS>/GPO-Template.zip` + `.sha256` | Local GPO giống máy mẫu, log `C:\Soft\GPO-Template\deploy.log` |
| 1b. Win10 dùng template Win11 | Clients | `A/L3b_Run_T3_Win11.ps1` | `A/T3_Deploy_Template.ps1` | như trên | ép `$OsFolder` |
| 2. KFM theo tenant | Clients | `A/L8_KFM_<TEN>.ps1` | `A/T8_Apply_OneDrive_KFM.ps1` | `Policies/OneDrive-KFM-lgpo.txt` | `KFMSilentOptIn` = Tenant ID đúng, log `C:\Soft\OneDrive-KFM\kfm.log` |
| 3. Rollback | Clients | `A/L4_Run_T4.ps1` | `A/T4_Rollback_PreDeploy.ps1` | `C:\Soft\GPO-Backup\PreDeploy-*` | khôi phục trạng thái trước T3 |

## Quy tắc quan trọng
- **T3 trước, L8 sau.** T3 xóa `Registry.pol` cũ nên mỗi lần T3 **thực sự deploy** (ZIP có SHA256 mới) thì phải chạy lại L8. Nếu T3 bỏ qua (ZIP không đổi) thì L8 giữ nguyên.
- Template mẫu hiện có `KFMSilentOptIn` = tenant KIA (`6fcf7bf2-...`). Máy của 5 tenant còn lại sẽ có giá trị này cho đến khi L8 ghi đè bằng đúng tenant của họ. Vì vậy **máy của KIA không cần chạy L8** (template đã đúng tenant). Chỉ **5 tenant phụ (SNP, KSL, LAV, CIT, DTC)** chạy `L8_KFM_<TEN>` cho đúng nhóm máy, sau khi deploy template cho toàn bộ clients.
- Mỗi lần đổi `Policies/*.txt` hoặc script là qua **PR vào `main`**, vì launcher và `.bat` đều tải từ `main`.
- **Luôn thử nhóm Test** (1-2 máy, gồm một máy Entra joined và một máy Workgroup) trước khi áp cho cả công ty.
- Template là artifact có SHA256 (`.sha256`): T3 từ chối ZIP sai hash.
