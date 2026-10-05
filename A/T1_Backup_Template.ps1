# T1 - Chay tren LAPTOP MAU (655): Backup Local Policy da cau hinh tay -> dong goi 1 file ZIP mau
# Quyen: Administrator / SYSTEM. Co the chay bang Action1 hoac PowerShell (Run as Administrator).
# Ket qua: C:\Soft\GPO-Zip\GPO-Template.zip (+ .sha256)  -> dung T2 de day len repo.
#
# Noi dung ZIP:
#   Backup\{GUID}\...        : LGPO /b (Machine + User + Security Settings + Audit)
#   Extra\NonAdmin-Registry.pol / Admin-Registry.pol : GPO rieng cho Non-Administrators / Administrators (LGPO /b KHONG backup phan nay)
#   manifest.json            : thong tin may mau, ngay backup

$ErrorActionPreference = "Stop"

$lgpoExe  = "C:\Soft\SCT\LGPO_30\LGPO.exe"
$work     = "C:\Soft\GPO-Template-Build"
$zipRoot  = "C:\Soft\GPO-Zip"
$zipFile  = Join-Path $zipRoot "GPO-Template.zip"

function Invoke-Lgpo {
    # Chay LGPO, bat stdout/stderr vao file -> Action1 khong bao Error gia do stderr
    param([string[]]$Arguments)
    $o = Join-Path $env:TEMP "lgpo_out.txt"; $e = Join-Path $env:TEMP "lgpo_err.txt"
    $p = Start-Process -FilePath $lgpoExe -ArgumentList $Arguments -Wait -PassThru -NoNewWindow `
         -RedirectStandardOutput $o -RedirectStandardError $e
    Get-Content $o, $e -ErrorAction SilentlyContinue | ForEach-Object { Write-Output "  [lgpo] $_" }
    return $p.ExitCode
}

try {
    if (-not (Test-Path $lgpoExe)) { throw "Khong tim thay LGPO.exe tai $lgpoExe (chay Part1 truoc)" }

    if (Test-Path $work) { Remove-Item $work -Recurse -Force }
    New-Item -ItemType Directory -Path "$work\Backup", "$work\Extra", $zipRoot -Force | Out-Null

    # 1. Backup Local GPO (Machine + User + Security + Audit)
    Write-Output "Backup Local Policy..."
    $rc = Invoke-Lgpo @("/b", "`"$work\Backup`"", "/n", "`"GPO-Template`"")
    if ($rc -ne 0) { throw "LGPO /b loi, exit code $rc" }

    $guid = Get-ChildItem "$work\Backup" -Directory | Where-Object { $_.Name -match '^\{[0-9A-Fa-f-]{36}\}$' } | Select-Object -First 1
    if (-not $guid) { throw "LGPO khong tao thu muc {GUID} trong $work\Backup" }

    # 2. GPO rieng cho Non-Administrators (S-1-5-32-545) va Administrators (S-1-5-32-544)
    $gpu = "$env:SystemRoot\System32\GroupPolicyUsers"
    $map = @{ "S-1-5-32-545" = "NonAdmin-Registry.pol"; "S-1-5-32-544" = "Admin-Registry.pol" }
    foreach ($sid in $map.Keys) {
        $src = Join-Path $gpu "$sid\User\Registry.pol"
        if (Test-Path $src) {
            Copy-Item $src (Join-Path "$work\Extra" $map[$sid]) -Force
            Write-Output "  + Extra\$($map[$sid])"
        }
    }

    # 3. Manifest
    $os = Get-CimInstance Win32_OperatingSystem
    [pscustomobject]@{
        Computer = $env:COMPUTERNAME
        Created  = (Get-Date).ToString("s")
        OS       = $os.Caption
        Build    = $os.BuildNumber
        BackupId = $guid.Name
    } | ConvertTo-Json | Set-Content "$work\manifest.json" -Encoding UTF8

    # 4. Zip + SHA256
    if (Test-Path $zipFile) { Remove-Item $zipFile -Force }
    Compress-Archive -Path "$work\*" -DestinationPath $zipFile -CompressionLevel Optimal -Force
    $hash = (Get-FileHash $zipFile -Algorithm SHA256).Hash.ToLower()
    Set-Content -Path "$zipFile.sha256" -Value $hash -Encoding ASCII -NoNewline

    Write-Output "OK: $zipFile ($([math]::Round((Get-Item $zipFile).Length/1KB,1)) KB)"
    Write-Output "SHA256: $hash"
    Write-Output "Buoc tiep theo: chay T2_Upload_Template.ps1 de day len repo."
    exit 0
}
catch {
    Write-Output "ERROR: $_"
    exit 1
}
