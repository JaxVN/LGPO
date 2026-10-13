# Script Map: vòng đời phát triển và deploy LGPO template (kiểu CI/CD)

Bảng chi tiết từng script (cột `Repo | Action 1 | Usage | Note`): [`Script-Map.csv`](Script-Map.csv).

Bốn cột (lane) của quy trình:

| Cột | Vai trò | Tương đương DevOps |
|---|---|---|
| **A. Máy mẫu** | Laptop 655: cấu hình tay, test, đóng gói | Dev + Build agent |
| **B. Repo** | GitHub `JaxVN/LGPO`: script, file mẫu, ZIP template, LGPO.zip | Source control + Artifact registry |
| **C. Action1** | Điều phối: automation, nhóm máy (Test / Prod), nhận exit code | Release pipeline / orchestrator |
| **D. Clients** | Máy người dùng (Workgroup hoặc Entra ID joined), SYSTEM | Môi trường Staging / Production |

## Vòng đời

```mermaid
sequenceDiagram
    autonumber
    participant A as A. Máy mẫu
    participant B as B. Repo (GitHub)
    participant C as C. Action1
    participant D as D. Clients

    rect rgb(235, 245, 255)
    Note over A,D: 0. BOOTSTRAP (một lần)
    A->>B: tải LGPO.zip (C_Deloy LGPO Part1)
    A->>B: C_Deloy_Policy_P0 gọi Grok/S000 cài ADMX Office và OneDrive
    end

    rect rgb(240, 255, 240)
    Note over A,B: 1. PLAN + CODE (phát triển)
    A->>A: cấu hình tay gpedit/secpol, test (Command/KFM-TEN.bat nếu cần thử KFM)
    A->>A: T7 xuất thư viện SharePoint thành LGPO text (TenantAutoMount)
    A->>B: sửa script và Policies/*.txt, commit, Pull Request, review, merge vào main
    end

    rect rgb(255, 250, 230)
    Note over A,B: 2. BUILD (đóng gói)
    C->>B: L1 tải T1 từ raw.githubusercontent
    C->>A: chạy T1 (T1a LGPO /b, T1b Admin/Non-Admin, T1c zip + SHA256)
    A-->>C: exit code, GPO-Template.zip và .sha256 ở C:\Soft\GPO-Zip
    end

    rect rgb(255, 245, 235)
    Note over A,B: 3. PUBLISH (đẩy artifact)
    A->>B: T2 (chạy tay, PAT) đẩy zip + sha256 lên Templates/Win10 hoặc Win11
    Note right of B: ZIP chứa toàn bộ Local GPO của máy mẫu (không gồm KFM theo tenant)
    end

    rect rgb(245, 240, 255)
    Note over C,D: 4. CANARY (nhóm Test, 1-2 máy)
    C->>D: L3 chạy trên nhóm Test
    D->>B: T3 tải zip + .sha256, kiểm SHA256, cài LGPO nếu thiếu
    D->>D: backup PreDeploy, xóa Registry.pol cũ, LGPO /g /un /ua, gpupdate
    C->>D: L8_KFM_TEN chạy sau T3 (ghi KFM theo tenant)
    D->>B: T8 tải Policies/OneDrive-KFM-lgpo.txt, thay Tenant ID, LGPO /t
    D-->>C: exit code, log deploy.log và kfm.log
    end

    alt Canary OK
        rect rgb(230, 250, 250)
        Note over C,D: 5. RELEASE (Prod, theo từng tenant)
        C->>D: L3 trên toàn bộ nhóm máy (ZIP không đổi thì T3 tự bỏ qua)
        C->>D: L8_KFM_SNP, KIA, KSL, LAV, CIT, DTC cho đúng nhóm máy từng công ty
        Note over D: launcher sai tenant trên máy Entra joined thì T8 dừng, exit 1
        D-->>C: báo cáo kết quả theo máy
        end
    else Canary lỗi
        rect rgb(255, 235, 235)
        Note over C,D: ROLLBACK
        C->>D: L4 chạy T4, khôi phục PreDeploy mới nhất
        D-->>C: exit code
        C-->>A: đọc log, quay lại bước 1 để sửa
        end
    end

    rect rgb(245, 245, 245)
    Note over A,D: 6. OPERATE + FEEDBACK
    D-->>C: Action1 theo dõi exit code và log
    C-->>A: có thay đổi thì lặp lại từ bước 1
    A->>B: máy domain chạy L6 và T6, đối chiếu qua Templates/Domain (không deploy)
    end
```

## Vòng lặp tóm tắt

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

## Quy tắc quan trọng
- **T3 trước, L8 sau**: T3 xóa `Registry.pol` cũ nên sẽ xóa KFM nếu L8 chạy trước.
- Mỗi lần đổi `Policies/*.txt` hoặc script là qua **PR vào `main`**, vì launcher và `.bat` đều tải từ `main`.
- **Luôn thử nhóm Test** (1-2 máy, gồm một máy Entra joined và một máy Workgroup) trước khi áp cho cả công ty.
- Template là artifact có SHA256 (`.sha256`): T3 từ chối ZIP sai hash.
