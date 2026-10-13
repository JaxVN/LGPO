<#
  Apply OneDrive silent sign-in + Known Folder Move to LOCAL policy via LGPO.exe /t
  - May join Entra ID: Tenant ID tu dong lay tu dsregcmd (khong can tham so).
  - May Workgroup: truyen -TenantId.
  Chay bang quyen Administrator. Can LGPO.exe trong PATH hoac cung thu muc.
  Vi du: .\Apply-KFM.ps1
         .\Apply-KFM.ps1 -TenantId 11111111-aaaa-bbbb-cccc-222222222222
#>
param([string]$TenantId)

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$template = Join-Path $here 'OneDrive-KFM.txt'

if (-not $TenantId) {
    $line = dsregcmd /status | Select-String '^\s*TenantId\s*:\s*(\S+)'
    if ($line) { $TenantId = $line.Matches[0].Groups[1].Value }
}
if (-not $TenantId) {
    Write-Error 'Khong tim thay Tenant ID (may Workgroup?). Hay chay lai voi -TenantId <GUID>.'
    exit 1
}

$lgpo = if (Test-Path (Join-Path $here 'LGPO.exe')) { Join-Path $here 'LGPO.exe' } else { 'LGPO.exe' }
$tmp = Join-Path $env:TEMP 'kfm.txt'
(Get-Content $template) -replace 'YOUR-TENANT-ID-HERE', $TenantId | Set-Content $tmp -Encoding ASCII
& $lgpo /t $tmp
Remove-Item $tmp -Force
gpupdate /force
Write-Host "Done. Tenant: $TenantId. Dang xuat/dang nhap lai de OneDrive ap dung."
