# L8 - Launcher cho Action1: OneDrive silent sign-in + Known Folder Move cho tenant LAV
# Tai A/T8_Apply_OneDrive_KFM.ps1 tu GitHub roi chay (MAY DICH, SYSTEM). Test 1-2 may truoc khi ap cho ca doi.

$ErrorActionPreference = "Stop"

# ===== CAU HINH =====
$Branch = "main"
$ScriptPath = "A/T8_Apply_OneDrive_KFM.ps1"
$env:KFM_TENANT = "LAV"   # SNP | KIA | KSL | LAV | CIT | DTC (T8 doi chieu voi tenant cua may Entra joined)
# ====================

$url = ("https://raw.githubusercontent.com/JaxVN/LGPO/{0}/{1}?t={2}" -f $Branch, $ScriptPath, [DateTime]::UtcNow.Ticks)   # ?t= tranh cache CDN

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Write-Output "Tai: $url"
    $content = (Invoke-WebRequest -Uri $url -UseBasicParsing).Content
    if ([string]::IsNullOrWhiteSpace($content)) { throw "Noi dung tai ve rong" }
}
catch {
    Write-Output "ERROR tai script: $($_.Exception.Message)"
    exit 1
}

# Script con tu goi exit 0/1 -> exit code duoc chuyen thang cho Action1
Invoke-Expression $content
