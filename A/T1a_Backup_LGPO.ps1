# T1a - Laptop mau: STEP 1/3 - LGPO /b vao C:\Soft\GPO-Template-Build\Backup\{GUID}
# Debug tung buoc: T1a (backup) -> T1b (extra + manifest) -> T1c (zip). T1_Backup_Template.ps1 = chay ca 3.
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

function Invoke-Lgpo {
    param([string[]]$Arguments)
    $o = Join-Path $env:TEMP "lgpo_out.txt"; $e = Join-Path $env:TEMP "lgpo_err.txt"
    $p = Start-Process -FilePath $lgpoExe -ArgumentList $Arguments -Wait -PassThru -NoNewWindow -RedirectStandardOutput $o -RedirectStandardError $e
    Get-Content $o, $e -ErrorAction SilentlyContinue | ForEach-Object { Write-Output "  [lgpo] $_" }
    $script:LgpoExit = $p.ExitCode   # KHONG return (output ham se lan vao gia tri tra ve)
}

try {
    Write-Output "[T1a] Backup Local Policy"
    if (-not (Test-Path $lgpoExe)) { throw "Khong tim thay LGPO.exe tai $lgpoExe (chay Part1 truoc)" }

    if (Test-Path $work) { Remove-Item $work -Recurse -Force }
    New-Item -ItemType Directory -Path "$work\Backup", "$work\Extra" -Force | Out-Null

    Invoke-Lgpo @("/b", "`"$work\Backup`"", "/n", "`"GPO-Template`"")
    Write-Output "  LGPO exit code: $script:LgpoExit"
    if ($script:LgpoExit -ne 0) { throw "LGPO /b loi, exit code $script:LgpoExit" }

    $guid = Get-ChildItem "$work\Backup" -Directory | Where-Object { $_.Name -match '^\{[0-9A-Fa-f-]{36}\}$' } | Select-Object -First 1
    if (-not $guid) { throw "Khong thay thu muc {GUID} trong $work\Backup" }

    Write-Output "[T1a] OK: $($guid.FullName)"
    Get-ChildItem $guid.FullName -Recurse -File | ForEach-Object { Write-Output ("  {0}  ({1} bytes)" -f $_.FullName.Substring($work.Length), $_.Length) }
    exit 0
}
catch { Show-Err $_; exit 1 }
