# L1 - Launcher cho Action1: tai T1_Backup_Template.ps1 tu GitHub roi chay (T1 = T1a + T1b + T1c trong 1 script)
# Chay tren LAPTOP MAU. Neu loi, chay rieng L1a -> L1b -> L1c de debug.

$ErrorActionPreference = "Stop"

# ===== CAU HINH =====
$Branch = "main"
$ScriptPath = "A/T1_Backup_Template.ps1"
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
