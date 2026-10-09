# T7 - Chay tren MAY CUA USER (dung user dang dang nhap, KHONG chay bang SYSTEM): quet cac thu vien SharePoint dang sync
# bang OneDrive -> xuat file LGPO text de ap len may khac bang:  LGPO.exe /t "<file>"
# = policy "Configure team site libraries to sync automatically" (TenantAutoMount)
#
# Nguon du lieu (HKCU + %LOCALAPPDATA% cua user, nen phai chay duoi quyen user, OneDrive da dang nhap + da sync):
#   HKCU\Software\Microsoft\OneDrive\Accounts\BusinessN\ScopeIdToMountPointPathCache : danh sach thu muc thu vien cua TUNG tai khoan
#   HKCU\Software\SyncEngines\Providers\OneDrive\*  : WebUrl, IsFolderScope (chi dung khi MountPoint khop cache)
#   %LOCALAPPDATA%\Microsoft\OneDrive\settings\BusinessN\ClientPolicy_<listId>_<siteId>.ini : ten file cho biet listId + siteId
#   %LOCALAPPDATA%\Microsoft\OneDrive\settings\BusinessN\<cid>.ini : dong libraryScope (webId, tenantId neu co)
# Nhieu tai khoan / nhieu to chuc: quet het, bo thu vien trung (vd KIA va KIA(1)), bo shortcut thu muc va OneDrive ca nhan.
# Dong Status khac OK (MISSING / CHECK-TENANT) khong vao file .txt - sua trong CSV roi chay lai voi -FromCsv.
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

function Get-SafeProps {
    # Thuoc tinh cua key registry (bo PS*), bo qua gia tri nhay cam (token/cookie/secret/password)
    param($Path)
    $p = Get-ItemProperty -LiteralPath $Path -ErrorAction SilentlyContinue
    if (-not $p) { return @() }
    $p.PSObject.Properties | Where-Object { $_.Name -notlike 'PS*' } | ForEach-Object {
        if ($_.Name -match 'token|cookie|secret|passw|ticket') { "$($_.Name)=<hidden>" } else { "$($_.Name)=$($_.Value)" }
    }
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

    # ---- 1. Du lieu chung: Providers (URL cua thu vien), danh sach tai khoan ----
    $raw = New-Object Collections.Generic.List[string]
    $provRoot = "HKCU:\Software\SyncEngines\Providers\OneDrive"
    $provs = @{}
    if (Test-Path $provRoot) {
        foreach ($k in Get-ChildItem $provRoot) {
            $provs[$k.PSChildName] = Get-ItemProperty $k.PSPath
            $raw.Add("### Provider $($k.PSChildName)")
            foreach ($x in (Get-SafeProps $k.PSPath)) { $raw.Add("  $x") }
        }
    }
    $acctRoot = "HKCU:\Software\Microsoft\OneDrive\Accounts"
    if (-not (Test-Path $acctRoot)) { throw "Khong co $acctRoot - OneDrive chua dang nhap tren user nay." }
    $accts = @(Get-ChildItem $acctRoot | Where-Object { $_.PSChildName -match '^Business\d+$' })
    if ($accts.Count -eq 0) { throw "Khong co tai khoan OneDrive for Business (BusinessN)." }

    # ---- 2. Tung tai khoan: ScopeIdToMountPointPathCache (khoa -> thu muc) + ID tu file ini ----
    # Luu y: key trong Providers co the bi 2 tai khoan ghi de nhau (cung scope+seq) -> ten thu muc lay tu cache cua TUNG tai khoan.
    $out = @(); $skipped = 0
    foreach ($a in $accts) {
        $p = Get-ItemProperty $a.PSPath
        $tenant = ""
        if ($p.ConfiguredTenantId) { $tenant = ([string]$p.ConfiguredTenantId).Trim('{','}').ToLower() }
        Write-Output ("Tai khoan {0}: tenantId={1} email={2}" -f $a.PSChildName, $tenant, $p.UserEmail)
        $raw.Add("### Account $($a.PSChildName) tenant=$tenant email=$($p.UserEmail)")
        foreach ($x in (Get-SafeProps $a.PSPath)) { $raw.Add("  $x") }

        $cachePath = Join-Path $a.PSPath "ScopeIdToMountPointPathCache"
        $cache = @{}
        if (Test-Path $cachePath) {
            $cp = Get-ItemProperty $cachePath
            foreach ($pp in $cp.PSObject.Properties) { if ($pp.Name -notlike 'PS*' -and $pp.Name -like '*+*') { $cache[$pp.Name] = [string]$pp.Value } }
        }
        Write-Output "  Thu muc scope trong cache: $($cache.Count)"

        $iniDir = Join-Path $env:LOCALAPPDATA "Microsoft\OneDrive\settings\$($a.PSChildName)"
        if (-not (Test-Path $iniDir)) { Write-Output "  (khong co thu muc ini: $iniDir)"; $raw.Add("### (khong co thu muc ini $iniDir)"); continue }

        # cap (listId, siteId) lay tu TEN file ClientPolicy_<listId>_<siteId>.ini
        $siteSet = @{}; $listSet = @{}
        foreach ($f in Get-ChildItem $iniDir -Filter 'ClientPolicy_*_*.ini' -ErrorAction SilentlyContinue) {
            $m = [regex]::Match($f.Name, '^ClientPolicy_([0-9a-fA-F]{32})_([0-9a-fA-F]{32})\.ini$')
            if ($m.Success) { $listSet[(Format-Guid $m.Groups[1].Value)] = $true; $siteSet[(Format-Guid $m.Groups[2].Value)] = $true }
        }
        Write-Output "  ClientPolicy (list,site): site=$($siteSet.Count) list=$($listSet.Count)"

        # file ini cua tai khoan: <cid>.ini
        $scopeLines = @()
        foreach ($f in Get-ChildItem $iniDir -Filter '*.ini' -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}\.ini$' }) {
            $lines = @(Read-IniLines $f.FullName)
            $raw.Add("### file $($f.Name) lines=$($lines.Count)")
            foreach ($l in $lines) {
                if ($l -match '(?i)token|cookie|secret|passw|ticket') { continue }
                $t = if ($l.Length -gt 600) { $l.Substring(0,600) + '...' } else { $l }
                $raw.Add("  $t")
                if ($l -match '(?i)^\s*libraryScope\s*=') { $scopeLines += $l }
            }
        }
        Write-Output "  Dong libraryScope: $($scopeLines.Count)"

        foreach ($key in $cache.Keys) {
            $mount = $cache[$key]
            $pv = $provs[$key]
            $pvOk = ($pv -and $pv.MountPoint -and ([string]$pv.MountPoint).ToLower() -eq $mount.ToLower())
            if (-not $pvOk) { $pv = $null }
            # Bo qua: shortcut thu muc (IsFolderScope) va tai khoan goc (mysite/personal)
            if ($pv -and ($pv.IsFolderScope -eq 1 -or $pv.LibraryType -match 'mysite|personal')) { $skipped++; continue }
            if ($mount -match '\\Shortcuts\\') { $skipped++; continue }

            $name = ConvertTo-Ascii (Split-Path $mount -Leaf)
            $source = $mount
            $status = "OK"; $value = ""
            $webUrlRaw = ""
            if ($pv -and $pv.WebUrl) { $webUrlRaw = [string]$pv.WebUrl }

            $line = $scopeLines | Where-Object { $_ -like "*$key*" -or $_.ToLower().Contains($mount.ToLower()) } | Select-Object -First 1
            if (-not $line) { $status = "MISSING: khong thay dong libraryScope cho $key" }
            else {
                $mm = [regex]::Match($line, 'tenantId=([^&"\s]+)&siteId=([^&"\s]+)&webId=([^&"\s]+)&listId=([^&"\s]+)')
                if ($mm.Success) {
                    $t2 = $mm.Groups[1].Value.Trim('{','}').ToLower(); $sid = $mm.Groups[2].Value; $wid = $mm.Groups[3].Value; $lid = $mm.Groups[4].Value
                } else {
                    $g = @([regex]::Matches($line, $guidRx) | ForEach-Object { '{' + $_.Value.Trim('{','}').ToLower() + '}' } | Select-Object -Unique)
                    $sid = $g | Where-Object { $siteSet.ContainsKey($_) } | Select-Object -First 1
                    $lid = $g | Where-Object { $listSet.ContainsKey($_) } | Select-Object -First 1
                    $rest = @($g | Where-Object { $_ -ne $sid -and $_ -ne $lid -and $_.Trim('{','}') -ne $tenant })
                    $t2 = $tenant
                    if ($rest.Count -ge 1) { $wid = $rest[0] }
                    if ($rest.Count -ge 2) { $t2 = $rest[0].Trim('{','}'); $wid = $rest[1]; $status = "CHECK-TENANT: nhieu GUID du, doan tenantId=$t2" }
                    if (-not $sid -or -not $lid -or -not $wid) { $status = "MISSING: GUID trong dong libraryScope khong du/khong khop ClientPolicy" }
                }
                if (-not $webUrlRaw) {
                    $um = [regex]::Match($line, 'https?://[^\s"]+')
                    if ($um.Success) { $webUrlRaw = $um.Value }
                }
                if ($status -notlike 'MISSING*') {
                    if (-not $webUrlRaw) { $status = "MISSING: khong biet webUrl" }
                    else {
                        $value = "tenantId=$t2&siteId=$sid&webId=$wid&listId=$lid&webUrl=$([uri]::EscapeDataString($webUrlRaw))&version=1"
                    }
                }
            }
            $out += [pscustomobject]@{ Name = $name; Value = $value; Source = $source; Status = $status }
        }
    }
    Write-Output "Bo qua (shortcut thu muc / OneDrive ca nhan): $skipped | Thu vien SharePoint can xuat: $($out.Count)"
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
    $webListKey = @($ok | Group-Object { ($_.Value -split '&')[2] + ($_.Value -split '&')[3] } | Where-Object { $_.Count -gt 1 })
    foreach ($d in $webListKey) { Write-Output "WARN: $($d.Count) thu vien co CUNG webId+listId (hiem, nghi ID sai): $(($d.Group | ForEach-Object Name) -join ', ')" }
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
