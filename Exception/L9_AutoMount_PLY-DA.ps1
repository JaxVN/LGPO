# L9 - Launcher cho Action1: ap danh sach thu vien rieng cua bo phan PLY-DA vao nhanh Non-Administrators (ngoai template)
# Tai Exception/T9_Apply_AutoMount_NonAdmin.ps1 tu GitHub roi chay (MAY DICH, SYSTEM). Test 1-2 may truoc khi ap cho ca nhom.
# Chay SAU T3/L3b (T3 xoa Registry.pol Non-Admin). Them bo phan moi: copy file nay, doi $env:EXC_FILE, dat file danh sach vao Exception/.

$ErrorActionPreference = "Stop"

# ===== CAU HINH =====
$Branch = "main"
$ScriptPath = "Exception/T9_Apply_AutoMount_NonAdmin.ps1"
$env:EXC_FILE = "OneDrive-AutoMount-PLY-DA-NonAdmin-lgpo.txt"   # file trong thu muc Exception/
# $env:EXC_FORCE = "1"   # bo comment neu muon ep ap len may Entra joined thuoc tenant khac
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
