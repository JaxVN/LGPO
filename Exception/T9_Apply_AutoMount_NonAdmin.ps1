# T9 - Chay tren MAY DICH (qua Action1, quyen SYSTEM): ap danh sach thu vien SharePoint RIENG cua bo phan/user (TenantAutoMount)
# vao nhanh NON-ADMINISTRATORS cua Local GPO, NGOAI template (khong dung vao nhanh Computer, khong phu thuoc T3).
# Cac buoc: cai LGPO neu thieu -> tai file tu Exception/ tren GitHub -> kiem tra an toan -> backup Registry.pol Non-Admin -> LGPO /t -> gpupdate -> doi chieu so thu vien
# Chay lai nhieu lan an toan (file co khoi DELETEALLVALUES: ghi lai dung danh sach, khong nhan doi).
# Launcher dat bien moi truong EXC_FILE = ten file trong thu muc Exception/ (xem L9_AutoMount_*.ps1). Khong dat: dung lai.
# LUU Y: T3 nap lai Registry.pol Non-Admin tu template nen se XOA danh sach nay -> luon chay lai L9 sau moi lan T3.

$ErrorActionPreference = "Stop"

# ===== CAU HINH =====
$Owner  = "JaxVN"; $Repo = "LGPO"; $Branch = "main"
$ExcFile = $env:EXC_FILE            # vd OneDrive-AutoMount-PLY-DA-NonAdmin-lgpo.txt
$Force   = ($env:EXC_FORCE -eq "1") # = 1: bo qua kiem tra tenant cua may Entra joined
# ====================

$lgpoExe    = "C:\Soft\SCT\LGPO_30\LGPO.exe"
$lgpoZipUrl = "https://github.com/$Owner/$Repo/raw/$Branch/LGPO.zip"
$base       = "C:\Soft\GPO-Exception"
$backupRoot = "C:\Soft\GPO-Backup"
$ts         = Get-Date -Format "yyyyMMdd-HHmmss"
$log        = Join-Path $base "exception.log"
$naPol      = "$env:SystemRoot\System32\GroupPolicyUsers\S-1-5-32-545\User\Registry.pol"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
New-Item -ItemType Directory -Path $base, $backupRoot -Force | Out-Null

function Write-Log { param($m) $line = "$(Get-Date -Format s) $m"; Write-Output $line; Add-Content $log $line }

function Invoke-Lgpo {
    param([string[]]$Arguments, [string]$OutFile = "")
    $o = if ($OutFile) { $OutFile } else { Join-Path $env:TEMP "lgpo_out.txt" }
    $e = Join-Path $env:TEMP "lgpo_err.txt"
    $p = Start-Process -FilePath $lgpoExe -ArgumentList $Arguments -Wait -PassThru -NoNewWindow `
         -RedirectStandardOutput $o -RedirectStandardError $e
    if (-not $OutFile) { Get-Content $o, $e -ErrorAction SilentlyContinue | ForEach-Object { Write-Log "  [lgpo] $_" } }
    else { Get-Content $e -ErrorAction SilentlyContinue | ForEach-Object { Write-Log "  [lgpo] $_" } }
    $script:LgpoExit = $p.ExitCode   # KHONG return: output cua ham se lan vao gia tri tra ve
}

try {
    if (-not $ExcFile) { throw "Chua dat EXC_FILE (ten file trong Exception/). Dung launcher Exception/L9_AutoMount_<BOPHAN>.ps1" }
    if ($ExcFile -notmatch '^[A-Za-z0-9._-]+\.txt$') { throw "EXC_FILE '$ExcFile' khong hop le (chi chu, so, . _ -, duoi .txt)" }

    # 1. LGPO.exe
    if (-not (Test-Path $lgpoExe)) {
        Write-Log "Cai LGPO.exe..."
        New-Item -ItemType Directory -Path "C:\Soft\SCT" -Force | Out-Null
        Invoke-WebRequest -Uri $lgpoZipUrl -OutFile "C:\Soft\SCT\LGPO.zip" -UseBasicParsing
        Expand-Archive -Path "C:\Soft\SCT\LGPO.zip" -DestinationPath "C:\Soft\SCT" -Force
        if (-not (Test-Path $lgpoExe)) { throw "Cai LGPO that bai" }
    }

    # 2. Tai file danh sach
    $file = Join-Path $base $ExcFile
    $url = "https://raw.githubusercontent.com/$Owner/$Repo/$Branch/Exception/${ExcFile}?t=$([DateTime]::UtcNow.Ticks)"
    Write-Log "Tai: $url"
    Invoke-WebRequest -Uri $url -OutFile $file -UseBasicParsing
    $lines = @(Get-Content $file)
    if ($lines.Count -eq 0) { throw "File tai ve rong" }

    # 3. Kiem tra an toan: chi duoc ghi vao nhanh Non-Administrators
    $hdr = @($lines | Where-Object { $_ -match '^(Computer|User)(:.*)?\s*$' })
    if ($hdr.Count -eq 0) { throw "File khong co khoi LGPO nao (thieu dong User:Non-Administrators)" }
    $badHdr = @($hdr | Where-Object { $_.Trim() -ne 'User:Non-Administrators' })
    if ($badHdr.Count -gt 0) { throw "File co khoi khong phai User:Non-Administrators ('$($badHdr[0].Trim())'). Dung lai de khong ghi nham nhanh Computer/User khac." }
    $entries = @($lines | Where-Object { $_ -match '^SZ:tenantId=' })
    if ($entries.Count -eq 0) { throw "File khong co dong SZ:tenantId= (khong phai danh sach TenantAutoMount)" }
    Write-Log "File $ExcFile : $($entries.Count) thu vien"

    # May Entra joined: tenant cua may phai nam trong file (tranh ap nham bo phan cua cong ty khac)
    $fileTenants = @($entries | ForEach-Object { if ($_ -match 'tenantId=([0-9a-fA-F-]{36})') { $matches[1].ToLower() } } | Select-Object -Unique)
    $ds = (& dsregcmd.exe /status 2>&1 | Out-String)
    $machineTenant = ""
    if ($ds -match 'AzureAdJoined\s*:\s*YES') { if ($ds -match 'TenantId\s*:\s*([0-9a-fA-F-]{36})') { $machineTenant = $matches[1].ToLower() } }
    if ($machineTenant) {
        Write-Log "May Entra joined, tenant $machineTenant ; file co tenant: $($fileTenants -join ', ')"
        if (($fileTenants -notcontains $machineTenant) -and -not $Force) {
            throw "Tenant cua may ($machineTenant) khong co trong file. Dung lai, khong ghi policy. (Ep: EXC_FORCE=1)"
        }
    } else { Write-Log "May Workgroup/domain (khong tu nhan duoc tenant), bo qua kiem tra tenant" }

    # 4. Backup Registry.pol Non-Admin hien tai
    if (Test-Path $naPol) {
        $bk = Join-Path $backupRoot "Exception-$ts"
        New-Item -ItemType Directory -Path $bk -Force | Out-Null
        Copy-Item $naPol (Join-Path $bk "NonAdmin-Registry.pol") -Force
        Write-Log "Backup: $bk\NonAdmin-Registry.pol"
    } else { Write-Log "Chua co Registry.pol nhom Non-Administrators (se duoc tao moi)" }

    # 5. Ap dung
    Write-Log "LGPO /t $ExcFile"
    Invoke-Lgpo @("/t", "`"$file`"")
    if ($script:LgpoExit -ne 0) { throw "LGPO /t loi, exit code $script:LgpoExit" }
    & gpupdate.exe /force 2>&1 | Out-Null

    # 6. Doi chieu: so thu vien trong Registry.pol Non-Admin phai bang so thu vien trong file
    $parseOut = Join-Path $env:TEMP "lgpo_parse_na.txt"
    Remove-Item $parseOut -Force -ErrorAction SilentlyContinue
    Invoke-Lgpo @("/parse", "/q", "/un", "`"$naPol`"") $parseOut
    $applied = @(Get-Content $parseOut -ErrorAction SilentlyContinue | Where-Object { $_ -match '^SZ:tenantId=' })
    if ($applied.Count -ne $entries.Count) { throw "Doi chieu that bai: file co $($entries.Count) thu vien, Registry.pol Non-Admin co $($applied.Count)" }

    Write-Log "OK: da ap $($applied.Count) thu vien vao nhanh Non-Administrators. Nguoi dung dang xuat/dang nhap lai (hoac khoi dong lai OneDrive). Rollback: $backupRoot\Exception-$ts"
    exit 0
}
catch {
    Write-Log "ERROR: $_"
    exit 1
}
