# T3 - Chay tren MAY DICH (qua Action1, quyen SYSTEM): tai GPO mau tu GitHub va ap dung
# Cac buoc: cai LGPO neu thieu -> tai zip + kiem SHA256 -> backup hien trang (de rollback) -> xoa policy cu -> LGPO /g -> gpupdate
# Chay lai nhieu lan an toan: neu zip khong doi so voi lan deploy truoc thi bo qua (dat $Force = $true de ep).

$ErrorActionPreference = "Stop"

# ===== CAU HINH =====
$Owner  = "JaxVN"; $Repo = "LGPO"; $Branch = "main"
$Remote = "Templates/GPO-Template.zip"
$Token  = ""            # Chi can neu repo PRIVATE (PAT quyen Contents: Read). Repo public de trong.
$Force  = $false
$CleanBeforeApply = $true   # xoa Registry.pol cu truoc khi import -> may dich giong het may mau
# ====================

$lgpoExe   = "C:\Soft\SCT\LGPO_30\LGPO.exe"
$lgpoZipUrl = "https://github.com/$Owner/$Repo/raw/$Branch/LGPO.zip"
$base      = "C:\Soft\GPO-Template"
$backupRoot = "C:\Soft\GPO-Backup"
$ts        = Get-Date -Format "yyyyMMdd-HHmmss"
$log       = Join-Path $base "deploy.log"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
New-Item -ItemType Directory -Path $base, $backupRoot -Force | Out-Null

function Write-Log { param($m) $line = "$(Get-Date -Format s) $m"; Write-Output $line; Add-Content $log $line }

function Invoke-Lgpo {
    param([string[]]$Arguments)
    $o = Join-Path $env:TEMP "lgpo_out.txt"; $e = Join-Path $env:TEMP "lgpo_err.txt"
    $p = Start-Process -FilePath $lgpoExe -ArgumentList $Arguments -Wait -PassThru -NoNewWindow `
         -RedirectStandardOutput $o -RedirectStandardError $e
    Get-Content $o, $e -ErrorAction SilentlyContinue | ForEach-Object { Write-Log "  [lgpo] $_" }
    return $p.ExitCode
}

function Get-Remote {
    param([string]$Path, [string]$OutFile)
    $h = @{ "User-Agent" = "lgpo-deploy" }
    if ($Token) { $h.Authorization = "Bearer $Token" }
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$Owner/$Repo/$Branch/$Path" -Headers $h -OutFile $OutFile -UseBasicParsing
}

try {
    # 1. LGPO.exe
    if (-not (Test-Path $lgpoExe)) {
        Write-Log "Cai LGPO.exe..."
        New-Item -ItemType Directory -Path "C:\Soft\SCT" -Force | Out-Null
        Invoke-WebRequest -Uri $lgpoZipUrl -OutFile "C:\Soft\SCT\LGPO.zip" -UseBasicParsing
        Expand-Archive -Path "C:\Soft\SCT\LGPO.zip" -DestinationPath "C:\Soft\SCT" -Force
        if (-not (Test-Path $lgpoExe)) { throw "Cai LGPO that bai" }
    }

    # 2. Tai zip + kiem hash
    $zip = Join-Path $base "GPO-Template.zip"
    Get-Remote -Path $Remote -OutFile $zip
    Get-Remote -Path "$Remote.sha256" -OutFile "$zip.sha256"
    $expected = (Get-Content "$zip.sha256" -Raw).Trim().ToLower()
    $actual   = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
    if ($expected -ne $actual) { throw "SHA256 khong khop (expected $expected, actual $actual)" }

    $deployedFile = Join-Path $base "deployed.sha256"
    if (-not $Force -and (Test-Path $deployedFile) -and ((Get-Content $deployedFile -Raw).Trim() -eq $actual)) {
        Write-Log "Template khong doi ($actual) - bo qua."
        exit 0
    }

    # 3. Giai nen
    $ex = Join-Path $base "extract"
    if (Test-Path $ex) { Remove-Item $ex -Recurse -Force }
    Expand-Archive -Path $zip -DestinationPath $ex -Force
    $guid = Get-ChildItem "$ex\Backup" -Directory | Where-Object { $_.Name -match '^\{[0-9A-Fa-f-]{36}\}$' } | Select-Object -First 1
    if (-not $guid) { throw "Zip khong chua thu muc Backup\{GUID}" }

    # 4. Backup hien trang truoc khi ap (cho T4 rollback)
    $pre = Join-Path $backupRoot "PreDeploy-$ts"
    New-Item -ItemType Directory -Path $pre -Force | Out-Null
    $rc = Invoke-Lgpo @("/b", "`"$pre`"", "/n", "`"PreDeploy-$ts`"")
    if ($rc -ne 0) { throw "Backup hien trang loi (exit $rc) - dung, chua thay doi gi" }
    $gpu = "$env:SystemRoot\System32\GroupPolicyUsers"
    if (Test-Path $gpu) { Copy-Item $gpu (Join-Path $pre "GroupPolicyUsers") -Recurse -Force }

    # 5. Xoa policy cu
    if ($CleanBeforeApply) {
        Write-Log "Xoa Registry.pol cu..."
        foreach ($f in @("$env:SystemRoot\System32\GroupPolicy\Machine\Registry.pol",
                         "$env:SystemRoot\System32\GroupPolicy\User\Registry.pol")) {
            if (Test-Path $f) { Remove-Item $f -Force }
        }
        if (Test-Path $gpu) { Get-ChildItem $gpu -Recurse -File -Filter "Registry.pol" | Remove-Item -Force }
    }

    # 6. Ap dung
    Write-Log "Ap dung $($guid.Name)..."
    $rc = Invoke-Lgpo @("/g", "`"$($guid.FullName)`"")
    if ($rc -ne 0) { throw "LGPO /g loi, exit code $rc" }

    $na = Join-Path $ex "Extra\NonAdmin-Registry.pol"
    $ad = Join-Path $ex "Extra\Admin-Registry.pol"
    if (Test-Path $na) { if ((Invoke-Lgpo @("/un", "`"$na`"")) -ne 0) { throw "LGPO /un loi" } }
    if (Test-Path $ad) { if ((Invoke-Lgpo @("/ua", "`"$ad`"")) -ne 0) { throw "LGPO /ua loi" } }

    # 7. Cap nhat policy
    & gpupdate.exe /force 2>&1 | Out-Null
    Set-Content -Path $deployedFile -Value $actual -Encoding ASCII -NoNewline

    Write-Log "OK: da deploy template (SHA256 $actual). Rollback: backup tai $pre. Nen cho user logoff/login lai."
    exit 0
}
catch {
    Write-Log "ERROR: $_"
    exit 1
}
