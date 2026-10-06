# T1c - Laptop mau: STEP 3/3 - nen C:\Soft\GPO-Template-Build -> C:\Soft\GPO-Zip\GPO-Template.zip + .sha256 (chay sau T1a, T1b)
# Dung .NET ZipFile (khong dung Compress-Archive: hay loi tren Windows PowerShell 5.1)
$ErrorActionPreference = "Stop"

$lgpoExe = "C:\Soft\SCT\LGPO_30\LGPO.exe"
$work    = "C:\Soft\GPO-Template-Build"
$zipRoot = "C:\Soft\GPO-Zip"
$zipFile = Join-Path $zipRoot "GPO-Template.zip"

function Show-Err {
    # In day du: thong diep, dong gay loi, stack -> de debug tren Action1
    param($ErrRec)
    Write-Output "ERROR: $($ErrRec.Exception.Message)"
    if ($ErrRec.InvocationInfo) { Write-Output ("  at line {0}: {1}" -f $ErrRec.InvocationInfo.ScriptLineNumber, $ErrRec.InvocationInfo.Line.Trim()) }
    if ($ErrRec.ScriptStackTrace) { Write-Output $ErrRec.ScriptStackTrace }
}

try {
    Write-Output "[T1c] Zip"
    if (-not (Test-Path "$work\Backup")) { throw "Chua co $work\Backup - chay T1a truoc" }
    New-Item -ItemType Directory -Path $zipRoot -Force | Out-Null
    if (Test-Path $zipFile) { Remove-Item $zipFile -Force }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [IO.Compression.ZipFile]::CreateFromDirectory($work, $zipFile, [IO.Compression.CompressionLevel]::Optimal, $false)

    $hash = (Get-FileHash $zipFile -Algorithm SHA256).Hash.ToLower()
    [IO.File]::WriteAllText("$zipFile.sha256", $hash, (New-Object Text.ASCIIEncoding))

    Write-Output "[T1c] OK: $zipFile ($([math]::Round((Get-Item $zipFile).Length/1KB,1)) KB)"
    Write-Output "SHA256: $hash"
    # Liet ke noi dung zip de kiem tra
    $z = [IO.Compression.ZipFile]::OpenRead($zipFile)
    try { $z.Entries | ForEach-Object { Write-Output "  $($_.FullName)  ($($_.Length) bytes)" } } finally { $z.Dispose() }
    Write-Output "Buoc tiep theo: T2_Upload_Template.ps1"
    exit 0
}
catch { Show-Err $_; exit 1 }
