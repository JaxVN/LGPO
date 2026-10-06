# T2 - Chay tren LAPTOP MAU (655), bang tay: day GPO-Template.zip len repo GitHub
# KHONG nen chay bang Action1 (can token ca nhan). Chay PowerShell (Admin), sau T1.
#
# Can GitHub token (fine-grained PAT): repo JaxVN/LGPO, quyen "Contents: Read and write".
# Truyen token qua bien moi truong $env:GITHUB_TOKEN, hoac script se hoi (khong luu lai, khong in ra).
#
# Dich: Templates/<Win10|Win11>/GPO-Template.zip va .sha256 (nhanh main). Thu muc tu nhan theo build Windows cua may chay script
#   (build >= 22000 = Win11, nguoc lai Win10). Muon ep: dat $OsFolder o duoi.

$ErrorActionPreference = "Stop"

$Owner  = "JaxVN"
$Repo   = "LGPO"
$Branch = "main"
$OsFolder = ""    # de trong = tu nhan theo may mau ("Win10" hoac "Win11")
if (-not $OsFolder) { $OsFolder = if ([int](Get-CimInstance Win32_OperatingSystem).BuildNumber -ge 22000) { "Win11" } else { "Win10" } }
$Remote = "Templates/$OsFolder"
$zipFile = "C:\Soft\GPO-Zip\GPO-Template.zip"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Publish-RepoFile {
    param([string]$LocalPath, [string]$RemotePath, [string]$Message, [hashtable]$Headers)

    $uri   = "https://api.github.com/repos/$Owner/$Repo/contents/$RemotePath"
    $bytes = [IO.File]::ReadAllBytes($LocalPath)
    $body  = @{ message = $Message; branch = $Branch; content = [Convert]::ToBase64String($bytes) }

    try {   # file da ton tai -> can sha de ghi de
        $cur = Invoke-RestMethod -Uri "$uri`?ref=$Branch" -Headers $Headers -Method Get
        $body.sha = $cur.sha
    } catch { }

    Invoke-RestMethod -Uri $uri -Headers $Headers -Method Put -Body ($body | ConvertTo-Json) -ContentType "application/json" | Out-Null
    Write-Output "  uploaded: $RemotePath"
}

try {
    if (-not (Test-Path $zipFile)) { throw "Khong thay $zipFile - chay T1 truoc" }

    $token = $env:GITHUB_TOKEN
    if (-not $token) {
        $sec   = Read-Host "Nhap GitHub token" -AsSecureString
        $token = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec))
    }
    $headers = @{ Authorization = "Bearer $token"; "User-Agent" = "lgpo-template-upload"; Accept = "application/vnd.github+json" }

    $msg = "Update GPO template from $env:COMPUTERNAME - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    Publish-RepoFile -LocalPath $zipFile            -RemotePath "$Remote/GPO-Template.zip"        -Message $msg -Headers $headers
    Publish-RepoFile -LocalPath "$zipFile.sha256"   -RemotePath "$Remote/GPO-Template.zip.sha256" -Message $msg -Headers $headers

    Write-Output "OK. URL: https://raw.githubusercontent.com/$Owner/$Repo/$Branch/$Remote/GPO-Template.zip"
    exit 0
}
catch {
    Write-Output "ERROR: $_"
    exit 1
}
