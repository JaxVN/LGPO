# T1b - Laptop mau: STEP 2/3 - copy GPO rieng Non-Admin/Admin + manifest.json (chay sau T1a)
$ErrorActionPreference = "Stop"

$lgpoExe = "C:\Soft\SCT\LGPO_30\LGPO.exe"
$work    = "C:\Soft\GPO-Template-Build"
$zipRoot = "C:\Soft\GPO-Zip"
$zipFile = Join-Path $zipRoot "GPO-Template.zip"

function Show-Err {
    # In day du: thong diep, dong gay loi, stack -> de debug tren Action1
    param($ErrRec)
    Write-Output "ERROR: $($ErrRec.Exception.Message)"
    if ($ErrRec.InvocationInfo) { Write-Output ("  at line {0}: {1}" -f $ErrRec.InvocationInfo.ScriptLineNumber, $ErrRec.InvocationInfo.Line.Trim()) }
    if ($ErrRec.ScriptStackTrace) { Write-Output $ErrRec.ScriptStackTrace }
}

try {
    Write-Output "[T1b] Extra + manifest"
    $guid = Get-ChildItem "$work\Backup" -Directory -ErrorAction Stop | Where-Object { $_.Name -match '^\{[0-9A-Fa-f-]{36}\}$' } | Select-Object -First 1
    if (-not $guid) { throw "Chua co $work\Backup\{GUID} - chay T1a truoc" }
    New-Item -ItemType Directory -Path "$work\Extra" -Force | Out-Null

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
    Write-Output "[T1b] OK: manifest.json"
    exit 0
}
catch { Show-Err $_; exit 1 }
