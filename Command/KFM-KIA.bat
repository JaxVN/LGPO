@echo off
setlocal
rem KFM-KIA.bat - OneDrive silent sign-in + Known Folder Move (Desktop/Documents/Pictures) cho tenant KIA
rem Local GPO (may Workgroup hoac Entra ID joined), ap bang LGPO /t. Chay bang quyen Administrator (chuot phai - Run as administrator).
rem Chi them/ghi de cac gia tri KFM/SilentAccountConfig, khong dung toi AllowTenantList/TenantAutoMount.

set "NAME=KIA"
set "TENANT=6fcf7bf2-2eb6-4b21-b92a-914d27ce33a8"
set "BRANCH=main"
set "D=C:\Soft\SCT"
set "LGPO=%D%\LGPO_30\LGPO.exe"
set "RAW=https://raw.githubusercontent.com/JaxVN/LGPO/%BRANCH%"

net session >nul 2>&1
if errorlevel 1 (
  echo [LOI] Can chay bang quyen Administrator.
  pause
  exit /b 1
)

echo === KFM %NAME% - tenant %TENANT% ===
if not exist "%D%" mkdir "%D%"

rem 1. LGPO.exe
if not exist "%LGPO%" (
  echo Cai LGPO.exe...
  curl -L -f -o "%D%\LGPO.zip" "https://github.com/JaxVN/LGPO/raw/%BRANCH%/LGPO.zip" || goto :err
  powershell -NoProfile -Command "Expand-Archive -Path '%D%\LGPO.zip' -DestinationPath '%D%' -Force" || goto :err
  if not exist "%LGPO%" goto :err
)

rem 2. Canh bao neu may Entra joined thuoc tenant khac
for /f "tokens=2 delims=: " %%a in ('dsregcmd /status ^| findstr /r /c:"^ *TenantId *:"') do set "DETECTED=%%a"
if defined DETECTED if /i not "%DETECTED%"=="%TENANT%" (
  echo [CANH BAO] May thuoc tenant %DETECTED%, khac tenant %NAME% %TENANT%. Dung file .bat sai?
  choice /c YN /m "Van tiep tuc"
  if errorlevel 2 exit /b 1
)

rem 3. Tai file mau, thay Tenant ID
curl -L -f -o "%D%\OneDrive-KFM-lgpo.txt" "%RAW%/Policies/OneDrive-KFM-lgpo.txt" || goto :err
powershell -NoProfile -Command "(Get-Content '%D%\OneDrive-KFM-lgpo.txt') -replace 'YOUR-TENANT-ID-HERE','%TENANT%' | Set-Content '%D%\OneDrive-KFM-%NAME%.txt' -Encoding ASCII" || goto :err

rem 4. Ap vao Local GPO
"%LGPO%" /t "%D%\OneDrive-KFM-%NAME%.txt" || goto :err
gpupdate /target:computer /force

rem 5. Kiem tra
reg query "HKLM\SOFTWARE\Policies\Microsoft\OneDrive" /v KFMSilentOptIn
reg query "HKLM\SOFTWARE\Policies\Microsoft\OneDrive" /v SilentAccountConfig
echo.
echo Xong. Dang xuat/dang nhap lai (hoac khoi dong lai OneDrive) de ap dung.
pause
exit /b 0

:err
echo [LOI] Buoc tren that bai, xem thong bao phia tren.
pause
exit /b 1
