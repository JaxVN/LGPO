# L7 - Launcher cho Action1: tai T7_Export_OneDrive_Libraries.ps1 tu GitHub roi chay DUOI QUYEN USER dang dang nhap.
# T7 doc HKCU va %LOCALAPPDATA% cua user nen KHONG chay duoc bang SYSTEM. Launcher xu ly ca hai truong hop:
#   - Action1 chay bang user: chay T7 truc tiep.
#   - Action1 chay bang SYSTEM: tim user dang dang nhap (console), tao Scheduled Task chay T7 bang user do (chi khi user dang dang nhap),
#     cho xong, in log, tra exit code cua T7 cho Action1.
# Ket qua nam trong $OutDir tren may do: OneDrive-TenantAutoMount-lgpo.txt, OneDrive-Libraries.csv, OneDrive-Libraries-raw.txt, t7.log
# Chua kiem tra tren may that voi tai khoan Entra ID (AzureAD\...): test 1 may truoc.

$ErrorActionPreference = "Stop"

# ===== CAU HINH =====
$Branch     = "main"
$ScriptPath = "A/T7_Export_OneDrive_Libraries.ps1"
$OutDir     = "C:\Soft\OneDrive-Libraries"
$Scope      = "Computer"      # Computer | User | User:Non-Administrators (xem T7). Computer = HKLM, ap cho moi user.
$NoClear    = $false          # $true = khong them khoi DELETEALLVALUES (giu thu vien co san tren may dich)
$TargetUser = ""              # chi dung khi chay bang SYSTEM: de trong = user dang dang nhap console; hoac "DOMAIN\user"
$TimeoutSec = 300
# ====================

$url = ("https://raw.githubusercontent.com/JaxVN/LGPO/{0}/{1}?t={2}" -f $Branch, $ScriptPath, [DateTime]::UtcNow.Ticks)   # ?t= tranh cache CDN
$t7   = Join-Path $OutDir "T7_Export_OneDrive_Libraries.ps1"
$log  = Join-Path $OutDir "t7.log"
$exitFile = Join-Path $OutDir "t7.exitcode"
$runner   = Join-Path $OutDir "t7-run.ps1"
$taskName = "T7-Export-OneDrive-Libraries"

try {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Write-Output "Tai: $url"
    $content = (Invoke-WebRequest -Uri $url -UseBasicParsing).Content
    if ([string]::IsNullOrWhiteSpace($content)) { throw "Noi dung tai ve rong" }
    [IO.File]::WriteAllText($t7, $content, (New-Object Text.UTF8Encoding($true)))
}
catch {
    Write-Output "ERROR tai script: $($_.Exception.Message)"
    exit 1
}

$t7Args = @("-OutDir", "`"$OutDir`"", "-Scope", "`"$Scope`"")
if ($NoClear) { $t7Args += "-NoClear" }

$me = [Security.Principal.WindowsIdentity]::GetCurrent()

# ---- Truong hop 1: dang chay bang user (khong phai SYSTEM) ----
if (-not $me.IsSystem) {
    Write-Output "Chay T7 truc tiep bang user $($me.Name)"
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $t7 @t7Args
    exit $LASTEXITCODE
}

# ---- Truong hop 2: SYSTEM -> chay bang user dang dang nhap qua Scheduled Task ----
try {
    $user = $TargetUser
    if (-not $user) { $user = (Get-CimInstance Win32_ComputerSystem).UserName }
    if (-not $user) { throw "Khong co user nao dang dang nhap console. Nho user dang nhap roi chay lai." }
    Write-Output "Chay T7 bang user: $user"

    # Cho phep user ghi vao thu muc ket qua
    & icacls.exe $OutDir /grant "${user}:(OI)(CI)M" | Out-Null

    Remove-Item $log, $exitFile -Force -ErrorAction SilentlyContinue
    $argText = $t7Args -join " "
    $runnerText = @"
`$ErrorActionPreference = 'Continue'
& '$t7' $argText *> '$log'
Set-Content -Path '$exitFile' -Value `$LASTEXITCODE
"@
    [IO.File]::WriteAllText($runner, $runnerText, (New-Object Text.UTF8Encoding($true)))

    $action    = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$runner`""
    $principal = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Limited
    $settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 10)
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    Register-ScheduledTask -TaskName $taskName -Action $action -Principal $principal -Settings $settings -Force | Out-Null
    Start-ScheduledTask -TaskName $taskName

    $waited = 0
    while (-not (Test-Path $exitFile) -and $waited -lt $TimeoutSec) { Start-Sleep -Seconds 3; $waited += 3 }
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

    if (Test-Path $log) { Get-Content $log | ForEach-Object { Write-Output $_ } }
    if (-not (Test-Path $exitFile)) { throw "T7 chua xong sau $TimeoutSec giay (kiem tra $log tren may)." }
    $code = [int]((Get-Content $exitFile -Raw).Trim())
    Write-Output "T7 exit code: $code. Ket qua: $OutDir"
    exit $code
}
catch {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
