# T4 - Rollback: khoi phuc Local Policy ve trang thai ngay truoc lan T3 gan nhat (thu muc C:\Soft\GPO-Backup\PreDeploy-*)
# Chay tren may dich qua Action1 (SYSTEM).

$ErrorActionPreference = "Stop"

$lgpoExe    = "C:\Soft\SCT\LGPO_30\LGPO.exe"
$backupRoot = "C:\Soft\GPO-Backup"

function Invoke-Lgpo {
    param([string[]]$Arguments)
    $o = Join-Path $env:TEMP "lgpo_out.txt"; $e = Join-Path $env:TEMP "lgpo_err.txt"
    $p = Start-Process -FilePath $lgpoExe -ArgumentList $Arguments -Wait -PassThru -NoNewWindow `
         -RedirectStandardOutput $o -RedirectStandardError $e
    Get-Content $o, $e -ErrorAction SilentlyContinue | ForEach-Object { Write-Output "  [lgpo] $_" }
    $script:LgpoExit = $p.ExitCode   # KHONG return: output cua ham se lan vao gia tri tra ve
}

try {
    if (-not (Test-Path $lgpoExe)) { throw "Khong thay LGPO.exe" }

    $pre = Get-ChildItem $backupRoot -Directory -Filter "PreDeploy-*" -ErrorAction SilentlyContinue |
           Sort-Object Name -Descending | Select-Object -First 1
    if (-not $pre) { throw "Khong co backup PreDeploy-* trong $backupRoot" }
    $guid = Get-ChildItem $pre.FullName -Directory | Where-Object { $_.Name -match '^\{[0-9A-Fa-f-]{36}\}$' } | Select-Object -First 1
    if (-not $guid) { throw "Backup $($pre.Name) khong co thu muc {GUID}" }

    Write-Output "Rollback ve: $($pre.Name)"

    foreach ($f in @("$env:SystemRoot\System32\GroupPolicy\Machine\Registry.pol",
                     "$env:SystemRoot\System32\GroupPolicy\User\Registry.pol")) {
        if (Test-Path $f) { Remove-Item $f -Force }
    }
    $gpu = "$env:SystemRoot\System32\GroupPolicyUsers"
    if (Test-Path $gpu) { Get-ChildItem $gpu -Recurse -File -Filter "Registry.pol" | Remove-Item -Force }

    Invoke-Lgpo @("/g", "`"$($guid.FullName)`"")
    if ($script:LgpoExit -ne 0) { throw "LGPO /g loi, exit code $script:LgpoExit" }

    # Khoi phuc GPO rieng Administrators / Non-Administrators neu co
    $saved = Join-Path $pre.FullName "GroupPolicyUsers"
    if (Test-Path $saved) {
        New-Item -ItemType Directory -Path $gpu -Force | Out-Null
        Copy-Item "$saved\*" $gpu -Recurse -Force
    }

    & gpupdate.exe /force 2>&1 | Out-Null
    Remove-Item "C:\Soft\GPO-Template\deployed.sha256" -Force -ErrorAction SilentlyContinue   # cho phep deploy lai
    Write-Output "OK: rollback hoan tat."
    exit 0
}
catch {
    Write-Output "ERROR: $_"
    exit 1
}
