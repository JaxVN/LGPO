# T8 - Chay tren MAY DICH (qua Action1, quyen SYSTEM): dang nhap OneDrive im lang + Known Folder Move (Desktop/Documents/Pictures)
# vao LOCAL GPO bang LGPO /t (Policies/OneDrive-KFM-lgpo.txt). Khong can domain: may Workgroup hoac join Entra ID.
#
# Chon tenant:
#   - Launcher A/L8_KFM_<TEN>.ps1 dat $env:KFM_TENANT = KIA|SNP|KSL|LAV|CIT|DTC (hoac Tenant ID dang GUID)
#   - Khong dat KFM_TENANT: may Entra joined tu lay Tenant ID tu dsregcmd; may Workgroup -> bao loi, thoat 1
#   - Dat KFM_TENANT ma may Entra joined thuoc tenant KHAC -> dung lai (tranh nham launcher). Ep: $env:KFM_FORCE = "1"
# Chi them/ghi de cac gia tri KFM/SilentAccountConfig, khong dung toi AllowTenantList/TenantAutoMount.

$ErrorActionPreference = "Stop"

# ===== CAU HINH =====
$Owner = "JaxVN"; $Repo = "LGPO"; $Branch = "main"
$Template = "Policies/OneDrive-KFM-lgpo.txt"
$Token = ""   # Chi can neu repo PRIVATE (PAT quyen Contents: Read)
$Tenants = [ordered]@{
    KIA = "6fcf7bf2-2eb6-4b21-b92a-914d27ce33a8"
    SNP = "4be02620-368a-4c1c-81da-d298040b2d92"
    KSL = "692eb525-c279-4d74-a010-638ac401a7d9"
    LAV = "fa0fc2b5-6ddc-40aa-8f77-838d08c1e9e7"
    CIT = "e9e8ce93-6c8e-48c7-81ec-20fc1841b63c"
    DTC = "02cc35ba-57a1-438b-8ae4-f68de204fe24"
}
# ====================

$lgpoExe    = "C:\Soft\SCT\LGPO_30\LGPO.exe"
$lgpoZipUrl = "https://github.com/$Owner/$Repo/raw/$Branch/LGPO.zip"
$base       = "C:\Soft\OneDrive-KFM"
$log        = Join-Path $base "kfm.log"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
New-Item -ItemType Directory -Path $base -Force | Out-Null

function Write-Log { param($m) $line = "$(Get-Date -Format s) $m"; Write-Output $line; Add-Content $log $line }

function Invoke-Lgpo {
    param([string[]]$Arguments)
    $o = Join-Path $env:TEMP "lgpo_out.txt"; $e = Join-Path $env:TEMP "lgpo_err.txt"
    $p = Start-Process -FilePath $lgpoExe -ArgumentList $Arguments -Wait -PassThru -NoNewWindow `
         -RedirectStandardOutput $o -RedirectStandardError $e
    Get-Content $o, $e -ErrorAction SilentlyContinue | ForEach-Object { Write-Log "  [lgpo] $_" }
    $script:LgpoExit = $p.ExitCode   # KHONG return: output cua ham se lan vao gia tri tra ve
}

try {
    # 1. Xac dinh Tenant ID
    $guid = '^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$'
    $name = "$env:KFM_TENANT".Trim()
    $detected = $null
    $m = (& dsregcmd.exe /status 2>$null) | Select-String '^\s*TenantId\s*:\s*(\S+)'
    if ($m) { $detected = $m.Matches[0].Groups[1].Value.ToLower() }
    Write-Log "May: $env:COMPUTERNAME | Tenant Entra phat hien: $(if ($detected) { $detected } else { '(khong co - Workgroup?)' })"

    if ($name) {
        if ($Tenants.Contains($name.ToUpper())) { $name = $name.ToUpper(); $tenantId = $Tenants[$name] }
        elseif ($name -match $guid)             { $tenantId = $name.ToLower(); $name = "GUID" }
        else { throw "KFM_TENANT '$name' khong hop le. Hop le: $($Tenants.Keys -join ', ') hoac Tenant ID (GUID)." }
        if ($detected -and $detected -ne $tenantId -and $env:KFM_FORCE -ne "1") {
            $known = ($Tenants.GetEnumerator() | Where-Object { $_.Value -eq $detected } | Select-Object -First 1).Key
            throw "Launcher $name ($tenantId) nhung may thuoc tenant $detected$(if ($known) { " ($known)" }). Dung launcher sai? Dat KFM_FORCE=1 de ep."
        }
    }
    elseif ($detected) {
        $tenantId = $detected
        $name = ($Tenants.GetEnumerator() | Where-Object { $_.Value -eq $tenantId } | Select-Object -First 1).Key
        if (-not $name) { $name = "UNKNOWN"; Write-Log "WARNING: tenant $tenantId khong nam trong danh sach 6 tenant" }
    }
    else {
        throw "May Workgroup, khong tu nhan duoc tenant. Dung launcher L8_KFM_<TEN>.ps1 (hoac dat KFM_TENANT)."
    }
    Write-Log "Ap dung KFM cho tenant: $name ($tenantId)"

    # 2. LGPO.exe
    if (-not (Test-Path $lgpoExe)) {
        Write-Log "Cai LGPO.exe..."
        New-Item -ItemType Directory -Path "C:\Soft\SCT" -Force | Out-Null
        Invoke-WebRequest -Uri $lgpoZipUrl -OutFile "C:\Soft\SCT\LGPO.zip" -UseBasicParsing
        Expand-Archive -Path "C:\Soft\SCT\LGPO.zip" -DestinationPath "C:\Soft\SCT" -Force
        if (-not (Test-Path $lgpoExe)) { throw "Cai LGPO that bai" }
    }

    # 3. Tai file mau, thay Tenant ID
    $h = @{ "User-Agent" = "lgpo-kfm" }
    if ($Token) { $h.Authorization = "Bearer $Token" }
    $url = "https://raw.githubusercontent.com/$Owner/$Repo/$Branch/$Template" + "?t=" + [DateTime]::UtcNow.Ticks
    $text = (Invoke-WebRequest -Uri $url -Headers $h -UseBasicParsing).Content
    if ($text -notmatch 'YOUR-TENANT-ID-HERE') { throw "File mau khong co placeholder YOUR-TENANT-ID-HERE" }
    $text = $text -replace 'YOUR-TENANT-ID-HERE', $tenantId
    $txt = Join-Path $base "OneDrive-KFM-$name.txt"
    Set-Content -Path $txt -Value $text -Encoding ASCII

    # 4. Ap bang LGPO /t
    Invoke-Lgpo -Arguments @("/t", "`"$txt`"")
    if ($script:LgpoExit -ne 0) { throw "LGPO /t that bai, exit code $script:LgpoExit" }
    & gpupdate.exe /target:computer /force | ForEach-Object { Write-Log "  [gpupdate] $_" }

    # 5. Kiem tra
    $k = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive" -ErrorAction Stop
    if ($k.KFMSilentOptIn -ne $tenantId -or $k.SilentAccountConfig -ne 1) { throw "Kiem tra registry that bai: KFMSilentOptIn=$($k.KFMSilentOptIn) SilentAccountConfig=$($k.SilentAccountConfig)" }
    Write-Log "OK: KFMSilentOptIn=$($k.KFMSilentOptIn), SilentAccountConfig=$($k.SilentAccountConfig). User dang xuat/dang nhap lai (hoac khoi dong lai OneDrive) de ap dung."
    exit 0
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    Write-Log $_.ScriptStackTrace
    exit 1
}
