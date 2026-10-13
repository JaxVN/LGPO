# Script Map

Bảng chi tiết: [`Script-Map.csv`](Script-Map.csv) (cột `Repo | Action 1 | Usage | Note`, mở bằng Excel).

```mermaid
flowchart LR
  subgraph Mau["Laptop mẫu"]
    P0["C_Deloy_Policy_P0 -> Grok/S000 (ADMX)"] --> CFG["Cấu hình tay gpedit/secpol"]
    KFMB["Command/KFM-TEN.bat (tay)"] --> CFG
    CFG --> T1["L1 -> T1 (T1a+T1b+T1c)"]
    T1 --> ZIP["GPO-Template.zip + .sha256"]
    ZIP --> T2["T2 (tay, PAT)"]
  end
  T2 --> TPL["Templates/Win10 | Win11"]
  TPL --> T3["L3 -> T3 (máy đích)"]
  T3 --> L8["L8_KFM_TEN -> T8 (KFM theo tenant)"]
  L8 --> TXT["Policies/OneDrive-KFM-lgpo.txt"]
  T3 -. sự cố .-> T4["L4 -> T4 rollback"]
  LG["LGPO.zip"] -.-> T3
  LG -.-> L8
  D["Máy domain: L6 -> T6"] -.-> TD["Templates/Domain (đối chiếu)"]
```

Thứ tự trên máy đích: **T3 trước, L8 sau** (T3 xóa `Registry.pol` cũ nên sẽ xóa KFM nếu L8 chạy trước).
