# T1 - Chay tren LAPTOP MAU (655): Backup Local Policy da cau hinh tay -> dong goi 1 file ZIP mau
# = T1a (LGPO /b) + T1b (Extra + manifest) + T1c (zip) trong 1 script. Neu loi, chay tung script T1a/T1b/T1c de debug.
# Quyen: Administrator / SYSTEM. Ket qua: C:\Soft\GPO-Zip\GPO-Template.zip (+ .sha256) -> dung T2 de day len repo.
#
# Noi dung ZIP:
#   Backup\{GUID}\...        : LGPO /b (Machine + User + Security Settings + Audit)
#   Extra\NonAdmin-Registry.pol / Admin-Registry.pol : GPO rieng cho Non-Administrators / Administrators (LGPO /b KHONG backup phan nay)
#   manifest.json            : thong tin may mau, ngay backup

$ErrorActionPreference = "Stop"

$lgpoExe = "C:\Soft\SCT\LGPO_30\LGPO.exe"
$work    = "C:\Soft\GPO-Template-Build"
$zipRoot = "C:\Soft\GPO-Zip"
$zipFile = Join-Path $zipRoot "GPO-Template.zip"

function Show-Err {
    param($ErrRec)
    Write-Output "ERROR: $($ErrRec.Exception.Message)"
    if ($ErrRec.InvocationInfo) { Write-Output ("  at line {0}: {1}" -f $ErrRec.InvocationInfo.ScriptLineNumber, $ErrRec.InvocationInfo.Line.Trim()) }
    if ($ErrRec.ScriptStackTrace) { Write-Output $ErrRec.ScriptStackTrace }
}

function Invoke-Lgpo {
    param([string[]]$Arguments)
    $o = Join-Path $env:TEMP "lgpo_out.txt"; $e = Join-Path $env:TEMP "lgpo_err.txt"
    $p = Start-Process -FilePath $lgpoExe -ArgumentList $Arguments -Wait -PassThru -NoNewWindow -RedirectStandardOutput $o -RedirectStandardError $e
    Get-Content $o, $e -ErrorAction SilentlyContinue | ForEach-Object { Write-Output "  [lgpo] $_" }
    $script:LgpoExit = $p.ExitCode   # KHONG return (output ham se lan vao gia tri tra ve)
}

$step = "init"
try {
    # ---- [1/3] LGPO /b ----
    $step = "1/3 LGPO backup"; Write-Output "[$step]"
    if (-not (Test-Path $lgpoExe)) { throw "Khong tim thay LGPO.exe tai $lgpoExe (chay Part1 truoc)" }
    if (Test-Path $work) { Remove-Item $work -Recurse -Force }
    New-Item -ItemType Directory -Path "$work\Backup", "$work\Extra" -Force | Out-Null

    Invoke-Lgpo @("/b", "`"$work\Backup`"", "/n", "`"GPO-Template`"")
    Write-Output "  LGPO exit code: $script:LgpoExit"
    if ($script:LgpoExit -ne 0) { throw "LGPO /b loi, exit code $script:LgpoExit" }
    $guid = Get-ChildItem "$work\Backup" -Directory | Where-Object { $_.Name -match '^\{[0-9A-Fa-f-]{36}\}$' } | Select-Object -First 1
    if (-not $guid) { throw "Khong thay thu muc {GUID} trong $work\Backup" }
    Write-Output "  OK: $($guid.FullName)"

    # ---- [2/3] Extra + manifest ----
    $step = "2/3 Extra + manifest"; Write-Output "[$step]"
    $gpu = "$env:SystemRoot\System32\GroupPolicyUsers"
    $map = @{ "S-1-5-32-545" = "NonAdmin-Registry.pol"; "S-1-5-32-544" = "Admin-Registry.pol" }
    foreach ($sid in $map.Keys) {
        $src = Join-Path $gpu "$sid\User\Registry.pol"
        if (Test-Path $src) { Copy-Item $src (Join-Path "$work\Extra" $map[$sid]) -Force; Write-Output "  + Extra\$($map[$sid])" }
        else { Write-Output "  (khong co $src - bo qua)" }
    }
    $os = Get-CimInstance Win32_OperatingSystem
    $manifest = [pscustomobject]@{
        Computer = $env:COMPUTERNAME
        Created  = (Get-Date).ToString("s")
        OS       = $os.Caption
        Build    = $os.BuildNumber
        BackupId = $guid.Name
    } | ConvertTo-Json
    [IO.File]::WriteAllText("$work\manifest.json", $manifest, (New-Object Text.UTF8Encoding($false)))

    # ---- [3/3] Zip (.NET ZipFile, khong dung Compress-Archive) ----
    $step = "3/3 Zip"; Write-Output "[$step]"
    New-Item -ItemType Directory -Path $zipRoot -Force | Out-Null
    if (Test-Path $zipFile) { Remove-Item $zipFile -Force }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [IO.Compression.ZipFile]::CreateFromDirectory($work, $zipFile, [IO.Compression.CompressionLevel]::Optimal, $false)
    $hash = (Get-FileHash $zipFile -Algorithm SHA256).Hash.ToLower()
    [IO.File]::WriteAllText("$zipFile.sha256", $hash, (New-Object Text.ASCIIEncoding))

    Write-Output "OK: $zipFile ($([math]::Round((Get-Item $zipFile).Length/1KB,1)) KB)"
    Write-Output "SHA256: $hash"
    Write-Output "Buoc tiep theo: chay T2_Upload_Template.ps1 de day len repo."
    exit 0
}
catch {
    Write-Output "FAILED at step [$step]"
    Show-Err $_
    exit 1
}
