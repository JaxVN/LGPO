# L3b - Launcher cho Action1: ap template WIN11 (Templates/Win11) len may bat ky (vd Win10), dung T3_Deploy_Template.ps1
# Chay tren MAY DICH (SYSTEM). Test 1-2 may truoc khi ap cho ca doi. Doi $OsFolder = "Win10" de ep template Win10.
# Khong phu thuoc T3 tren repo da ho tro $env:LGPO_OSFOLDER hay chua: launcher tu thay dong $OsFolder trong noi dung T3 truoc khi chay.

$ErrorActionPreference = "Stop"

# ===== CAU HINH =====
$Branch = "main"
$ScriptPath = "A/T3_Deploy_Template.ps1"
$OsFolder = "Win11"      # thu muc trong Templates/ can ap len may nay
# ====================

$url = ("https://raw.githubusercontent.com/JaxVN/LGPO/{0}/{1}?t={2}" -f $Branch, $ScriptPath, [DateTime]::UtcNow.Ticks)   # ?t= tranh cache CDN

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Write-Output "Tai: $url"
    $content = (Invoke-WebRequest -Uri $url -UseBasicParsing).Content
    if ([string]::IsNullOrWhiteSpace($content)) { throw "Noi dung tai ve rong" }

    # Ep thu muc template: thay dong '$OsFolder = ...' dau tien trong T3
    $new = (New-Object System.Text.RegularExpressions.Regex('(?m)^\$OsFolder\s*=.*$')).Replace($content, ('$OsFolder = "' + $OsFolder + '"'), 1)
    if ($new -eq $content) { throw "Khong tim thay dong `$OsFolder trong T3 - dung lai, khong ap nham template" }
    $content = $new
    Write-Output "Ep dung template: Templates/$OsFolder/GPO-Template.zip"
}
catch {
    Write-Output "ERROR tai script: $($_.Exception.Message)"
    exit 1
}

# Script con tu goi exit 0/1 -> exit code duoc chuyen thang cho Action1
Invoke-Expression $content
