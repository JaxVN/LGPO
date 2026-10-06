# L1c - Launcher cho Action1: tai T1c_Zip_Template.ps1 tu GitHub roi chay (Nen zip + SHA256)
# Chay tren LAPTOP MAU. Thu tu: L1a -> L1b -> L1c

$ErrorActionPreference = "Stop"

# ===== CAU HINH =====
$Branch = "main"
$ScriptPath = "A/T1c_Zip_Template.ps1"
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
