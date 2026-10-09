# T7 - Chay tren MAY CUA USER (dung user dang dang nhap, KHONG chay bang SYSTEM): quet cac thu vien SharePoint dang sync
# bang OneDrive -> xuat file LGPO text de ap len may khac bang:  LGPO.exe /t "<file>"
# = policy "Configure team site libraries to sync automatically" (TenantAutoMount)
#
# Nguon du lieu: %LOCALAPPDATA%\Microsoft\OneDrive\settings\BusinessN\<cid>.ini (cid lay tu HKCU\Software\Microsoft\OneDrive\Accounts\BusinessN),
# cac dong libraryScope chua tenantId, siteId, webId, listId, webUrl va thu muc mount cua tung thu vien.
# Chay duoi quyen USER dang dang nhap OneDrive (khong dung SYSTEM). Nhieu tai khoan / nhieu to chuc: quet het,
# bo thu vien trung (vd KIA va KIA(1)), bo OneDrive ca nhan va thu vien chi sync thu muc con.
#
# Ket qua (mac dinh C:\Soft\OneDrive-Libraries):
#   OneDrive-TenantAutoMount-lgpo.txt : file cho LGPO /t  (Computer hoac User, xem -Scope)
#   OneDrive-Libraries.csv            : Name, Value, Source, Status  (sua Name trong CSV neu can, roi chay lai voi -FromCsv)
#   OneDrive-Libraries-raw.txt        : dong libraryScope + Providers goc (de debug neu ID khong khop)
#
# Cach dung:
#   .\T7_Export_OneDrive_Libraries.ps1                         # quet may nay
#   .\T7_Export_OneDrive_Libraries.ps1 -FromCsv C:\Soft\OneDrive-Libraries\OneDrive-Libraries.csv   # tao lai .txt tu CSV da sua
#   .\T7_Export_OneDrive_Libraries.ps1 -Scope User -NoClear    # ghi vao User Configuration, khong xoa gia tri cu
# Ap tren may dich (Admin):
#   LGPO.exe /t "C:\Soft\OneDrive-Libraries\OneDrive-TenantAutoMount-lgpo.txt" ; gpupdate /force
#   (roi thoat/mo lai OneDrive hoac dang xuat/dang nhap)

param(
    [string]$OutDir  = "C:\Soft\OneDrive-Libraries",
    [ValidateSet("Computer","User")][string]$Scope = "Computer",
    [switch]$NoClear,          # khong them khoi DELETEALLVALUES (giu cac gia tri TenantAutoMount co san tren may dich)
    [string]$FromCsv = ""      # bo qua buoc quet, doc CSV (cot Name, Value) de tao lai file .txt
)

$ErrorActionPreference = "Stop"

$policyKey = "SOFTWARE\Policies\Microsoft\OneDrive\TenantAutoMount"
$txtFile   = Join-Path $OutDir "OneDrive-TenantAutoMount-lgpo.txt"
$csvFile   = Join-Path $OutDir "OneDrive-Libraries.csv"
$rawFile   = Join-Path $OutDir "OneDrive-Libraries-raw.txt"
$guidRx    = '\{?[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\}?'

function Show-Err {
    param($ErrRec)
    Write-Output "ERROR: $($ErrRec.Exception.Message)"
    if ($ErrRec.InvocationInfo) { Write-Output ("  at line {0}: {1}" -f $ErrRec.InvocationInfo.ScriptLineNumber, $ErrRec.InvocationInfo.Line.Trim()) }
}

function ConvertTo-Ascii {
    # Bo dau tieng Viet / ky tu la -> ASCII (file LGPO text ghi ASCII); ky tu cam trong ten thu muc -> "_"
    param([string]$s)
    $d = $s.Normalize([Text.NormalizationForm]::FormD)
    $sb = New-Object Text.StringBuilder
    foreach ($c in $d.ToCharArray()) {
        if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($c) -ne [Globalization.UnicodeCategory]::NonSpacingMark) { [void]$sb.Append($c) }
    }
    $r = $sb.ToString().Replace([string][char]0x0111, "d").Replace([string][char]0x0110, "D")
    $r = $r -replace '[^\x20-\x7E]', '_'
    return ($r -replace '[\\/:*?"<>|]', '_').Trim()
}

function Write-LgpoFile {
    param($Rows)   # doi tuong co .Name, .Value
    $nl = "`r`n"
    $sb = New-Object Text.StringBuilder
    [void]$sb.Append("; OneDrive - Configure team site libraries to sync automatically ($($Rows.Count) thu vien) - $Scope Configuration" + $nl)
    [void]$sb.Append("; Ap bang:  LGPO.exe /t `"<duong dan>\OneDrive-TenantAutoMount-lgpo.txt`"" + $nl)
    [void]$sb.Append("; Nguon: may $env:COMPUTERNAME, user $env:USERNAME, ngay $(Get-Date -Format 'yyyy-MM-dd HH:mm') (T7_Export_OneDrive_Libraries.ps1)" + $nl + $nl)
    if (-not $NoClear) {
        [void]$sb.Append("$Scope$nl$policyKey$nl*${nl}DELETEALLVALUES$nl$nl")
    }
    foreach ($r in $Rows) {
        [void]$sb.Append("$Scope$nl$policyKey$nl$($r.Name)${nl}SZ:$($r.Value)$nl$nl")
    }
    [IO.File]::WriteAllText($txtFile, $sb.ToString(), [Text.Encoding]::ASCII)
}

function Read-IniLines {
    # Doc file ini ke ca khi OneDrive dang mo; tu nhan UTF-16 (co/khong BOM) hoac UTF-8
    param([string]$Path)
    try {
        $fs = New-Object IO.FileStream($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
        $ms = New-Object IO.MemoryStream
        $fs.CopyTo($ms); $fs.Dispose()
        $b = $ms.ToArray()
    } catch { return @() }
    if     ($b.Length -ge 2 -and $b[0] -eq 0xFF -and $b[1] -eq 0xFE) { $t = [Text.Encoding]::Unicode.GetString($b, 2, $b.Length - 2) }
    elseif ($b.Length -ge 3 -and $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF) { $t = [Text.Encoding]::UTF8.GetString($b, 3, $b.Length - 3) }
    elseif ($b.Length -ge 4 -and $b[1] -eq 0 -and $b[3] -eq 0) { $t = [Text.Encoding]::Unicode.GetString($b) }
    else { $t = [Text.Encoding]::UTF8.GetString($b) }
    return @($t -split "`r?`n")
}

function Format-Guid {
    # 32 ky tu hex -> {xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}
    param([string]$h)
    $h = $h.ToLower()
    return ("{{{0}-{1}-{2}-{3}-{4}}}" -f $h.Substring(0,8), $h.Substring(8,4), $h.Substring(12,4), $h.Substring(16,4), $h.Substring(20,12))
}

try {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

    # ---- Che do -FromCsv: tao lai .txt tu CSV da sua tay ----
    if ($FromCsv) {
        if (-not (Test-Path $FromCsv)) { throw "Khong thay file CSV: $FromCsv" }
        $rows = @(Import-Csv -Path $FromCsv | Where-Object { $_.Name -and $_.Value } | ForEach-Object {
            [pscustomobject]@{ Name = (ConvertTo-Ascii $_.Name); Value = $_.Value.Trim() }
        })
        if ($rows.Count -eq 0) { throw "CSV khong co dong nao co Name + Value" }
        Write-LgpoFile $rows
        Write-Output "OK: $($rows.Count) thu vien -> $txtFile"
        exit 0
    }

    Write-Output "=== T7: quet thu vien SharePoint dang sync (user $env:USERNAME) ==="
    if ($env:USERNAME -like '*$') { throw "Dang chay bang tai khoan may (SYSTEM). Chay bang user dang dang nhap OneDrive." }

    # ---- 1. Doc file <cid>.ini cua tung tai khoan OneDrive for Business ----
    # Dong thu vien dang:
    #   libraryScope = <n> <scopeKey> 5 "<site>" "<library>" <n> "<webUrl>" "<tenantId>" <siteId32> <webId32> <listId32> <ts> "<mountPath>" ...
    # mountPath rong = chi sync thu muc con (libraryFolder), khong phai ca thu vien -> AutoMount khong ap dung.
    $raw = New-Object Collections.Generic.List[string]
    $accts = @()
    $acctRoot = "HKCU:\Software\Microsoft\OneDrive\Accounts"
    if (-not (Test-Path $acctRoot)) { throw "Khong co $acctRoot - OneDrive chua dang nhap tren user nay." }
    $accts = @(Get-ChildItem $acctRoot | Where-Object { $_.PSChildName -match '^Business\d+$' })
    if ($accts.Count -eq 0) { throw "Khong co tai khoan OneDrive for Business (BusinessN)." }

    $rx = '^\s*libraryScope\s*=\s*\d+\s+(\S+)\s+\d+\s+"([^"]*)"\s+"([^"]*)"\s+\d+\s+"([^"]*)"\s+"([^"]*)"\s+([0-9a-fA-F]{32})\s+([0-9a-fA-F]{32})\s+([0-9a-fA-F]{32})\s+\d+\s+"([^"]*)"'
    $out = @(); $skipFolder = 0; $skipPersonal = 0
    foreach ($a in $accts) {
        $p = Get-ItemProperty $a.PSPath
        Write-Output ("Tai khoan {0}: email={1} tenantId={2}" -f $a.PSChildName, $p.UserEmail, $p.ConfiguredTenantId)
        $raw.Add("### Account $($a.PSChildName) email=$($p.UserEmail) tenant=$($p.ConfiguredTenantId) cid=$($p.cid)")
        if (-not $p.cid) { Write-Output "  (khong co cid - bo qua)"; continue }
        $ini = Join-Path $env:LOCALAPPDATA "Microsoft\OneDrive\settings\$($a.PSChildName)\$($p.cid).ini"
        if (-not (Test-Path $ini)) { Write-Output "  (khong thay $ini - bo qua)"; continue }
        $n = 0
        foreach ($l in (Read-IniLines $ini)) {
            if ($l -notmatch '^\s*(libraryScope|libraryFolder|AddedScope)\s*=') { continue }
            $raw.Add($l)
            if ($l -notmatch '^\s*libraryScope\s*=') { continue }
            $m = [regex]::Match($l, $rx)
            if (-not $m.Success) { Write-Output "  WARN: khong doc duoc dong: $($l.Substring(0, [Math]::Min(120, $l.Length)))"; continue }
            $siteT = $m.Groups[2].Value; $libT = $m.Groups[3].Value; $url = $m.Groups[4].Value; $tenant = $m.Groups[5].Value.ToLower()
            $mount = $m.Groups[9].Value
            if ($url -match '-my\.sharepoint\.com' -or $libT -eq 'ODB') { $skipPersonal++; continue }
            if (-not $mount) { $skipFolder++; continue }
            $value = "tenantId=$tenant&siteId=$(Format-Guid $m.Groups[6].Value)&webId=$(Format-Guid $m.Groups[7].Value)&listId=$(Format-Guid $m.Groups[8].Value)&webUrl=$([uri]::EscapeDataString($url))&version=1"
            $out += [pscustomobject]@{ Name = (ConvertTo-Ascii "$siteT - $libT"); Value = $value; Source = $mount; Status = "OK" }
            $n++
        }
        Write-Output "  Thu vien (mount day du): $n"
    }
    Write-Output "Bo qua: $skipPersonal OneDrive ca nhan, $skipFolder thu vien chi sync thu muc con (AutoMount khong ho tro)"
    if ($out.Count -eq 0) { [IO.File]::WriteAllLines($rawFile, $raw.ToArray()); throw "Khong tim thay thu vien SharePoint nao. Xem $rawFile" }

    # ---- 4. Kiem tra (nhieu tai khoan / nhieu to chuc) ----
    # Cung 1 thu vien co the hien o nhieu tai khoan (vd KIA va KIA(1)) -> bo ban trung (cung Value)
    $seen = @{}; $uniq = @()
    foreach ($o in $out) {
        if ($o.Value -and $seen.ContainsKey($o.Value)) { Write-Output "Bo ban trung (da co trong danh sach): $($o.Name)"; continue }
        if ($o.Value) { $seen[$o.Value] = $true }
        $uniq += $o
    }
    $out = $uniq
    # Khac thu vien nhung trung ten (vd 'Documents' o 2 to chuc) -> them hau to _2, _3 (ten gia tri policy phai duy nhat)
    foreach ($g in @($out | Group-Object Name | Where-Object { $_.Count -gt 1 })) {
        $i = 0
        foreach ($o in $g.Group) { $i++; if ($o -ne $g.Group[0]) { $o.Name = "$($o.Name)_$i"; Write-Output "WARN: trung ten '$($g.Name)' -> doi thanh '$($o.Name)'" } }
    }
    $ok = @($out | Where-Object { $_.Status -eq "OK" })
    foreach ($d in @($ok | Group-Object { ($_.Value -split '&')[4] } | Where-Object { $_.Count -gt 1 })) {
        Write-Output "WARN: $($d.Count) thu vien khac nhau cung webUrl (kiem tra lai, Providers co the ghi de): $(($d.Group | ForEach-Object Name) -join ', ')"
    }
    Write-Output ""
    Write-Output "Tong ket theo to chuc (tenantId):"
    $ok | Group-Object { ($_.Value -split '&')[0] } | ForEach-Object { Write-Output ("  {0} : {1} thu vien" -f $_.Name, $_.Count) }

    $out | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8
    [IO.File]::WriteAllLines($rawFile, $raw.ToArray())

    Write-Output ""
    $out | ForEach-Object { Write-Output ("  [{0}] {1}  <-  {2}" -f $_.Status, $_.Name, $_.Source) }
    Write-Output ""

    if ($ok.Count -eq 0) { Write-Output "KHONG lay duoc ID thu vien nao. Gui file nay de chinh lai cach doc: $rawFile"; exit 2 }
    Write-LgpoFile $ok
    Write-Output "OK: $($ok.Count)/$($out.Count) thu vien -> $txtFile"
    Write-Output "CSV: $csvFile | Raw: $rawFile"
    if ($ok.Count -lt $out.Count) { Write-Output "CANH BAO: $($out.Count - $ok.Count) thu vien bi thieu ID/trung ten - xem cot Status trong CSV." }
    Write-Output "Ap tren may dich (Admin): LGPO.exe /t `"$txtFile`" ; gpupdate /force"
    exit 0
}
catch {
    Show-Err $_
    if ($raw -and $raw.Count -gt 0) { try { [IO.File]::WriteAllLines($rawFile, $raw.ToArray()); Write-Output "Raw (de debug): $rawFile" } catch {} }
    exit 1
}
