# Script: Download PolicyDefinitions từ GitHub → C:\Soft\LGPO → C:\Windows\PolicyDefinitions
# Chạy với quyền Administrator

$ErrorActionPreference = "Stop"

$repoOwner = "JaxVN"
$repoName  = "LGPO"
$branch    = "main"
$remotePath = "PolicyDefinitions"
$localTemp  = "C:\Soft\LGPO"
$targetPath = "C:\Windows\PolicyDefinitions"

# Tạo thư mục tạm
if (-not (Test-Path $localTemp)) {
    New-Item -ItemType Directory -Path $localTemp -Force | Out-Null
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Download-GitHubFolder {
    param(
        [string]$ApiUrl,
        [string]$LocalFolder
    )

    Write-Output "Đang lấy danh sách: $ApiUrl"
    $items = Invoke-RestMethod -Uri $ApiUrl -UseBasicParsing

    foreach ($item in $items) {
        $localItemPath = Join-Path $LocalFolder $item.name

        if ($item.type -eq "file") {
            Write-Output "  Tải file: $($item.name)"
            Invoke-WebRequest -Uri $item.download_url -OutFile $localItemPath -UseBasicParsing
        }
        elseif ($item.type -eq "dir") {
            Write-Output "  Tạo thư mục: $($item.name)"
            if (-not (Test-Path $localItemPath)) {
                New-Item -ItemType Directory -Path $localItemPath -Force | Out-Null
            }
            # Gọi đệ quy
            Download-GitHubFolder -ApiUrl $item.url -LocalFolder $localItemPath
        }
    }
}

# 1. Tải toàn bộ từ GitHub về C:\Soft\LGPO
$apiUrl = "https://api.github.com/repos/$repoOwner/$repoName/contents/$remotePath`?ref=$branch"
Download-GitHubFolder -ApiUrl $apiUrl -LocalFolder $localTemp

Write-Output "`n✓ Đã tải xong về: $localTemp"

# 2. Copy vào C:\Windows\PolicyDefinitions
Write-Output "Đang copy vào $targetPath ..."

# Copy các file .admx
Get-ChildItem -Path $localTemp -Filter "*.admx" -File | ForEach-Object {
    Copy-Item $_.FullName -Destination $targetPath -Force
    Write-Output "  + $($_.Name)"
}

# Copy thư mục ngôn ngữ (en-us)
$enUsSource = Join-Path $localTemp "en-us"
$enUsTarget = Join-Path $targetPath "en-US"   # Windows dùng en-US

if (Test-Path $enUsSource) {
    if (-not (Test-Path $enUsTarget)) {
        New-Item -ItemType Directory -Path $enUsTarget -Force | Out-Null
    }
    Copy-Item -Path "$enUsSource\*" -Destination $enUsTarget -Force -Recurse
    Write-Output "  + en-US\*.adml"
}

Write-Output "`n✓ Hoàn tất! Đã cài PolicyDefinitions."
Write-Output "Khuyến nghị: đóng hết gpedit.msc / MMC rồi mở lại."
