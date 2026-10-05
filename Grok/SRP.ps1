# Script: Tạo Software Restriction Policy - Path Rules
# Chạy với quyền Administrator / SYSTEM

$ErrorActionPreference = "Stop"

# Registry gốc của SRP
$saferRoot = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Safer\CodeIdentifiers"

# Bật SRP (nếu chưa)
if (-not (Test-Path $saferRoot)) {
    New-Item -Path $saferRoot -Force | Out-Null
}
Set-ItemProperty -Path $saferRoot -Name "DefaultLevel" -Value 262144 -Type DWord -Force   # Unrestricted = 262144, Disallowed = 0
Set-ItemProperty -Path $saferRoot -Name "PolicyScope"  -Value 0 -Type DWord -Force        # 0 = All users
Set-ItemProperty -Path $saferRoot -Name "TransparentEnabled" -Value 1 -Type DWord -Force

# Thư mục chứa Path Rules
$pathRules = Join-Path $saferRoot "0\Paths"          # 0 = Disallowed level? → thực tế Path Rules nằm dưới level
# Cấu trúc chuẩn: CodeIdentifiers\<Level>\Paths\<GUID>

function New-SrpPathRule {
    param(
        [string]$Path,
        [ValidateSet("Unrestricted","Disallowed")]
        [string]$Level = "Unrestricted",
        [string]$Description = ""
    )

    $levelValue = if ($Level -eq "Unrestricted") { 262144 } else { 0 }
    $levelKey   = Join-Path $saferRoot "$levelValue\Paths"
    
    if (-not (Test-Path $levelKey)) {
        New-Item -Path $levelKey -Force | Out-Null
    }

    $guid = [guid]::NewGuid().ToString("B").ToUpper()
    $ruleKey = Join-Path $levelKey $guid

    New-Item -Path $ruleKey -Force | Out-Null
    Set-ItemProperty -Path $ruleKey -Name "ItemData"     -Value $Path -Type String -Force
    Set-ItemProperty -Path $ruleKey -Name "Description"  -Value $Description -Type String -Force
    Set-ItemProperty -Path $ruleKey -Name "LastModified" -Value ([DateTime]::Now.ToFileTime()) -Type QWord -Force
    Set-ItemProperty -Path $ruleKey -Name "SaferFlags"   -Value 0 -Type DWord -Force

    Write-Output "  + [$Level] $Path"
}

Write-Output "=== Tạo Path Rules Unrestricted ==="

$unrestricted = @(
    "%AppData%\Telegram Desktop",
    "%HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRoot%",
    "%HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication%",
    "%HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\ProgramFilesDir (x86)%",
    "%HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\ProgramFilesDir%",
    "%LOCALAPPDATA%\Temp\is-*.tmp\iTaxViewer*.tmp",
    "%LocalAppData%\Viber",
    "%UserProfile%\Desktop",
    "*.lnk",
    "\\%USERDNSDOMAIN%\Sysvol\",
    "\\10.10.6.13\FASTFOXPRO\*",
    "\\kiena.local\dfs\Public\IT\00. Software\03. Deloy\*",
    "\\kiena.local\NETLOGON\LAPS\",
    "\\stcvm003\FASTFOXPRO\*",
    "\\stcvm003\FASTFOXPRO\KIENTHINH",
    "\\stcvm003\FASTFOXPRO\KIENTHINH\KIENTHINH",
    "\\stcvm003\FASTFOXPRO\KIENTHINH\KIENTHINH_2015",
    "\\stcvm003\FASTFOXPRO\KIENTHINH\KIENTHINH_2015\WS",
    "C:\Dev\*",
    "C:\FAST\*",
    "C:\Program Files (x86)\iTax Viewer\iTaxViewer.exe",
    "C:\Program Files\Adobe\Acrobat DC\Acrobat\Acrobat.exe",
    "C:\Soft\*",
    "C:\Users\*\AppData\Local\CapCut\Apps\CapCut.exe",
    "C:\Users\*\AppData\Local\Microsoft\*",
    "C:\Users\*\AppData\Local\Microsoft\*.exe",
    "C:\Users\*\AppData\Local\Microsoft\*\*.exe",
    "C:\Users\*\AppData\Local\Microsoft\*\*\*.exe",
    "C:\Users\*\Appdata\Local\Microsoft\Onedrive\??.?.????.????\*.exe",
    "C:\Users\*\AppData\Local\SquirrelTemp\Update.exe",
    "C:\Users\*\AppData\Local\Viber\Viber.exe",
    "C:\Users\*\AppData\Roaming\Autodesk\ADPSDK\bin\ADPClientService.exe",
    "C:\Users\*\AppData\Roaming\Autodesk\ADPSDK\bin\AdpSDKUtil.exe",
    "C:\Users\*\AppData\Roaming\D5 Render\d5_immerse\Binaries\Win64\d5_immerse.exe",
    "C:\Users\*\AppData\Roaming\D5 Render\d5_launcher.exe",
    "C:\Users\*\AppData\Roaming\D5 Render\d5_render.exe",
    "C:\WINDOWS\system32\backgroundTaskHost.exe",
    "C:\Windows\System32\BackgroundTransferHost.exe",
    "C:\Windows\System32\SecurityHealth\*\SecurityHealthHost.exe",
    "D:\FAST\*",
    "F:\*\*\*\*",
    "F:\*\vfp7.exe",
    "F:\*\WS\vfp7.exe",
    "F:\KIENA\2025\kiena_2015-2018\WS\vfp7.exe",
    "F:\KIENTHINH",
    "F:\KIENTHINH\KIENTHINH\WS\",
    "F:\KIENTHINH\KIENTHINH\WS\vfp7.exe",
    "F:\KIENTHINH\KIENTHINH_2015\WS\"
)

foreach ($p in $unrestricted) {
    New-SrpPathRule -Path $p -Level "Unrestricted"
}

Write-Output "`n=== Tạo Path Rules Disallowed ==="
New-SrpPathRule -Path "%programfiles%\WindowsApps\Microsoft.WindowsStore*" -Level "Disallowed" -Description "Disable MS Store"

Write-Output "`n✓ Đã tạo xong Path Rules"
Write-Output "Lưu ý: Hash Rules (UniKey, VFP7) vẫn phải tạo tay trên máy mẫu."
