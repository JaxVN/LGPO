# T6 - Chay tren MAY DOMAIN (qua Action1, SYSTEM hoac Admin): thu chinh sach DANG CO HIEU LUC (ke ca GPO tu domain)
# de doi chieu khi lam GPO cho nhom WorkGroup. LGPO /b (T1) chi lay Local GPO + Security Settings, KHONG co
# Administrative Templates cua GPO domain -> T6 bu phan nay.
#
# Thu thap:
#   gpresult-computer.xml/.html : danh sach GPO da ap + setting (Computer)
#   gpresult-user.xml/.html     : nhu tren cho user dang dang nhap (neu co, co the that bai - bo qua)
#   HKLM-Policies.reg, HKLM-CurrentVersion-Policies.reg : registry policy muc may
#   HKCU-Policies.reg, HKCU-CurrentVersion-Policies.reg : registry policy cua user dang dang nhap (neu co)
#   manifest.json
# Ket qua: C:\Soft\GPO-Zip\Domain-Effective.zip (+ .sha256)
# Day len repo (chay tay tren may nay):
#   $env:LGPO_ZIP = "Domain-Effective.zip"; $env:LGPO_FOLDER = "Domain"; .\T2_Upload_Template.ps1
#
# Luu y: file .reg co the chua thong tin nhay cam (duong dan noi bo, ten may chu...). Kiem tra truoc khi dua len repo public.

$ErrorActionPreference = "Stop"

$work    = "C:\Soft\GPO-Domain-Effective"
$zipRoot = "C:\Soft\GPO-Zip"
$zipFile = Join-Path $zipRoot "Domain-Effective.zip"

function Show-Err {
    param($ErrRec)
    Write-Output "ERROR: $($ErrRec.Exception.Message)"
    if ($ErrRec.InvocationInfo) { Write-Output ("  at line {0}: {1}" -f $ErrRec.InvocationInfo.ScriptLineNumber, $ErrRec.InvocationInfo.Line.Trim()) }
}

function Invoke-Native {
    # Chay exe, bat stdout/stderr vao file (Action1 khong bao Error gia). Exit code o $script:NativeExit
    param([string]$Exe, [string[]]$Arguments)
    $o = Join-Path $env:TEMP "native_out.txt"; $e = Join-Path $env:TEMP "native_err.txt"
    $p = Start-Process -FilePath $Exe -ArgumentList $Arguments -Wait -PassThru -NoNewWindow -RedirectStandardOutput $o -RedirectStandardError $e
    $script:NativeExit = $p.ExitCode
}

function Export-Reg {
    param([string]$Key, [string]$File)
    Invoke-Native "reg.exe" @("export", "`"$Key`"", "`"$File`"", "/y")
    if ($script:NativeExit -eq 0) { Write-Output "  + $(Split-Path $File -Leaf)" }
    else { Write-Output "  (khong co key $Key - bo qua)" }
}

$step = "init"
try {
    $step = "1/4 chuan bi"; Write-Output "[$step]"
    if (Test-Path $work) { Remove-Item $work -Recurse -Force }
    New-Item -ItemType Directory -Path $work, $zipRoot -Force | Out-Null

    $cs = Get-CimInstance Win32_ComputerSystem
    Write-Output "  May: $($cs.Name) | Domain: $($cs.Domain) | PartOfDomain: $($cs.PartOfDomain) | User: $($cs.UserName)"

    # ---- gpresult ----
    $step = "2/4 gpresult"; Write-Output "[$step]"
    Invoke-Native "gpresult.exe" @("/scope", "computer", "/x", "`"$work\gpresult-computer.xml`"", "/f")
    Write-Output "  computer xml exit: $script:NativeExit"
    Invoke-Native "gpresult.exe" @("/scope", "computer", "/h", "`"$work\gpresult-computer.html`"", "/f")

    $user = $cs.UserName
    $sid = $null
    if ($user) {
        try { $sid = (New-Object Security.Principal.NTAccount($user)).Translate([Security.Principal.SecurityIdentifier]).Value } catch { $sid = $null }
        Invoke-Native "gpresult.exe" @("/user", "`"$user`"", "/scope", "user", "/x", "`"$work\gpresult-user.xml`"", "/f")
        Write-Output "  user xml exit: $script:NativeExit (khac 0 = khong lay duoc, bo qua)"
        Invoke-Native "gpresult.exe" @("/user", "`"$user`"", "/scope", "user", "/h", "`"$work\gpresult-user.html`"", "/f")
    } else { Write-Output "  Khong co user dang nhap - bo qua gpresult user" }

    # ---- registry policy ----
    $step = "3/4 registry policy"; Write-Output "[$step]"
    Export-Reg "HKLM\SOFTWARE\Policies" "$work\HKLM-Policies.reg"
    Export-Reg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies" "$work\HKLM-CurrentVersion-Policies.reg"
    if ($sid -and (Test-Path "Registry::HKEY_USERS\$sid")) {
        Export-Reg "HKU\$sid\Software\Policies" "$work\HKCU-Policies.reg"
        Export-Reg "HKU\$sid\Software\Microsoft\Windows\CurrentVersion\Policies" "$work\HKCU-CurrentVersion-Policies.reg"
    } else { Write-Output "  Khong tim thay hive cua user dang nhap - bo qua HKCU" }

    # ---- manifest + zip ----
    $step = "4/4 zip"; Write-Output "[$step]"
    $os = Get-CimInstance Win32_OperatingSystem
    $manifest = [pscustomobject]@{
        Computer = $env:COMPUTERNAME; Domain = $cs.Domain; User = $user
        Created = (Get-Date).ToString("s"); OS = $os.Caption; Build = $os.BuildNumber
    } | ConvertTo-Json
    [IO.File]::WriteAllText("$work\manifest.json", $manifest, (New-Object Text.UTF8Encoding($false)))

    if (Test-Path $zipFile) { Remove-Item $zipFile -Force }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [IO.Compression.ZipFile]::CreateFromDirectory($work, $zipFile, [IO.Compression.CompressionLevel]::Optimal, $false)
    $hash = (Get-FileHash $zipFile -Algorithm SHA256).Hash.ToLower()
    [IO.File]::WriteAllText("$zipFile.sha256", $hash, (New-Object Text.ASCIIEncoding))

    Write-Output "OK: $zipFile ($([math]::Round((Get-Item $zipFile).Length/1KB,1)) KB)"
    Write-Output "SHA256: $hash"
    Get-ChildItem $work -File | ForEach-Object { Write-Output ("  {0} ({1} bytes)" -f $_.Name, $_.Length) }
    exit 0
}
catch {
    Write-Output "FAILED at step [$step]"
    Show-Err $_
    exit 1
}
