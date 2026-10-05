# Script: Tạo Software Restriction Policy - Path Rules
# Chỉ áp dụng cho Non-Administrators
# Chạy với quyền Administrator / SYSTEM

$ErrorActionPreference = "Stop"

$saferRoot = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Safer\CodeIdentifiers"

try {
    # 1. Khởi tạo SRP (chỉ Non-Administrators)
    if (-not (Test-Path $saferRoot)) {
        New-Item -Path $saferRoot -Force | Out-Null
    }

    Set-ItemProperty -Path $saferRoot -Name "DefaultLevel"        -Value 262144 -Type DWord -Force
    Set-ItemProperty -Path $saferRoot -Name "PolicyScope"         -Value 1      -Type DWord -Force  # trừ Administrators
    Set-ItemProperty -Path $saferRoot -Name "TransparentEnabled"  -Value 1      -Type DWord -Force
    Set-ItemProperty -Path $saferRoot -Name "AuthenticodeEnabled" -Value 0      -Type DWord -Force

    @(0, 262144) | ForEach-Object {
        $levelPath = Join-Path $saferRoot "$_\Paths"
        if (-not (Test-Path $levelPath)) {
            New-Item -Path $levelPath -Force | Out-Null
        }
    }

    # 2. Hàm tạo Path Rule (không in từng dòng)
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
    }

    # 3. Danh sách Path Unrestricted
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

    # 4. Disallowed
    New-SrpPathRule -Path "%programfiles%\WindowsApps\Microsoft.WindowsStore*" -Level "Disallowed" -Description "Disable MS Store"

    # Chỉ in 2 dòng kết quả
    Write-Output "✓ SRP Path Rules đã tạo thành công (Non-Administrators)"
    Write-Output "✓ Unrestricted: $($unrestricted.Count) | Disallowed: 1"
    exit 0
}
catch {
    Write-Output "✗ Lỗi khi tạo SRP: $_"
    exit 1
}
