# Command

File `.bat` **tải về chạy tay** (không qua Action1) trên máy mẫu hoặc máy đơn lẻ. Mỗi file tự cài LGPO nếu thiếu, tải file mẫu `Policies/OneDrive-KFM-lgpo.txt`, thay Tenant ID rồi áp vào **Local GPO** bằng `LGPO /t` (máy Workgroup hoặc Entra ID joined).

| File | Tenant | Tenant ID |
|---|---|---|
| `KFM-SNP.bat` | SNP | `4be02620-368a-4c1c-81da-d298040b2d92` |
| `KFM-KIA.bat` | KIA | `6fcf7bf2-2eb6-4b21-b92a-914d27ce33a8` |
| `KFM-KSL.bat` | KSL | `692eb525-c279-4d74-a010-638ac401a7d9` |
| `KFM-LAV.bat` | LAV | `fa0fc2b5-6ddc-40aa-8f77-838d08c1e9e7` |
| `KFM-CIT.bat` | CIT | `e9e8ce93-6c8e-48c7-81ec-20fc1841b63c` |
| `KFM-DTC.bat` | DTC | `02cc35ba-57a1-438b-8ae4-f68de204fe24` |

## Tải và chạy (CMD Administrator)

```bat
curl -L -o "%TEMP%\KFM-KIA.bat" "https://raw.githubusercontent.com/JaxVN/LGPO/main/Command/KFM-KIA.bat"
"%TEMP%\KFM-KIA.bat"
```
Đổi `KIA` thành tenant cần dùng. Hoặc tải file về, chuột phải → *Run as administrator*.

## Lưu ý
- Các file tải từ nhánh `main` (biến `BRANCH` ở đầu file). Chưa merge vào `main` thì đổi `BRANCH` sang tên nhánh đang dùng.
- Cần Administrator. File thoát nếu chạy không đủ quyền.
- Máy Entra joined thuộc tenant khác với file `.bat` đang chạy: file cảnh báo và hỏi có tiếp tục không.
- Máy Workgroup: `SilentAccountConfig` không có tác dụng; người dùng đăng nhập OneDrive bằng tay một lần với đúng tenant, sau đó KFM tự chuyển.
- Chỉ ghi các giá trị KFM/`SilentAccountConfig`, không đụng `AllowTenantList`/`TenantAutoMount`.
- Kiểm tra: `reg query "HKLM\SOFTWARE\Policies\Microsoft\OneDrive" /v KFMSilentOptIn`.
- Deploy hàng loạt qua Action1: dùng `A/L8_KFM_<TEN>.ps1` (xem `A/readme.md`).
