# T7 - Chay tren MAY CUA USER (dung user dang dang nhap, KHONG chay bang SYSTEM): quet cac thu vien SharePoint dang sync
# bang OneDrive -> xuat file LGPO text de ap len may khac bang:  LGPO.exe /t "<file>"
# = policy "Configure team site libraries to sync automatically" (TenantAutoMount)
#
# Nguon du lieu (HKCU + %LOCALAPPDATA% cua user, nen phai chay duoi quyen user, OneDrive da dang nhap + da sync):
#   HKCU\Software\SyncEngines\Providers\OneDrive\*   : MountPoint (ten thu muc = ten gia tri policy), UrlNamespace (-> webUrl)
#   HKCU\Software\Microsoft\OneDrive\Accounts\BusinessN : ConfiguredTenantId
#   %LOCALAPPDATA%\Microsoft\OneDrive\settings\BusinessN\*.ini : dong "libraryScope" chua siteId / webId / listId
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
    # Doc file ini ke ca khi OneDrive dang mo (FileShare.ReadWrite); tu nhan UTF-16/UTF-8 theo BOM
    param([string]$Path)
    $fs = $null
    try {
        $fs = New-Object IO.FileStream($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
        $sr = New-Object IO.StreamReader($fs, [Text.Encoding]::Default, $true)
        $txt = $sr.ReadToEnd()
        return @($txt -split "`r?`n")
    } catch { return @() } finally { if ($fs) { $fs.Dispose() } }
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

    # ---- 1. Tai khoan OneDrive for Business ----
    $acctRoot = "HKCU:\Software\Microsoft\OneDrive\Accounts"
    if (-not (Test-Path $acctRoot)) { throw "Khong co $acctRoot - OneDrive chua dang nhap tren user nay." }
    $accts = @(Get-ChildItem $acctRoot | Where-Object { $_.PSChildName -match '^Business\d+$' })
    if ($accts.Count -eq 0) { throw "Khong co tai khoan OneDrive for Business (BusinessN)." }

    $raw = New-Object Collections.Generic.List[string]
    $scopeLines = @()      # @{Acct; Tenant; Line}
    foreach ($a in $accts) {
        $p = Get-ItemProperty $a.PSPath
        $tenant = ""
        if ($p.ConfiguredTenantId) { $tenant = ([string]$p.ConfiguredTenantId).Trim('{','}').ToLower() }
        Write-Output ("Tai khoan {0}: tenantId={1} email={2}" -f $a.PSChildName, $tenant, $p.UserEmail)
        $raw.Add("### Account $($a.PSChildName) tenant=$tenant email=$($p.UserEmail)")
        foreach ($sub in @("Tenants","ScopeIdToMountPointPathCache")) {
            $sp = Join-Path $a.PSPath $sub
            if (Test-Path $sp) {
                $raw.Add("### $($a.PSChildName)\$sub")
                foreach ($k in @($sp) + @(Get-ChildItem $sp -ErrorAction SilentlyContinue | ForEach-Object { $_.PSPath })) { foreach ($x in (Get-SafeProps $k)) { $raw.Add("  $x") } }
            }
        }
        $iniDir = Join-Path $env:LOCALAPPDATA "Microsoft\OneDrive\settings\$($a.PSChildName)"
        if (-not (Test-Path $iniDir)) { Write-Output "  (khong co thu muc ini: $iniDir)"; $raw.Add("### (khong co thu muc ini $iniDir)"); continue }
        foreach ($f in Get-ChildItem $iniDir -File -ErrorAction SilentlyContinue) {
            $lines = @(Read-IniLines $f.FullName)
            $raw.Add("### file $($f.Name) size=$($f.Length) lines=$($lines.Count)")
            foreach ($l in $lines) {
                if ($l -match '(?i)^\s*libraryScope\s*=') {
                    $scopeLines += [pscustomobject]@{ Acct = $a.PSChildName; Tenant = $tenant; Line = $l }
                    $raw.Add("[$($f.Name)] $l")
                } elseif ($f.Extension -eq '.ini' -and $l -match '(?i)scope|siteid|listid|webid|library') {
                    $raw.Add("[$($f.Name)] (other) $l")
                }
            }
        }
    }
    Write-Output "Dong libraryScope tim thay: $($scopeLines.Count)"

    # ---- 2. Cac thu vien SharePoint dang mount (Providers) ----
    $provRoot = "HKCU:\Software\SyncEngines\Providers\OneDrive"
    if (-not (Test-Path $provRoot)) { throw "Khong co $provRoot - chua sync thu vien nao." }
    $provs = @()
    foreach ($k in Get-ChildItem $provRoot) {
        $p = Get-ItemProperty $k.PSPath
        $raw.Add("### Provider $($k.PSChildName)")
        foreach ($x in (Get-SafeProps $k.PSPath)) { $raw.Add("  $x") }
        if ($p.UrlNamespace -and $p.UrlNamespace -match '^https://[^/]+/(sites|teams)/' -and $p.UrlNamespace -notmatch '-my\.sharepoint\.com') {
            $provs += [pscustomobject]@{ Key = $k.PSChildName; Mount = [string]$p.MountPoint; Url = [string]$p.UrlNamespace }
        }
    }
    Write-Output "Thu vien SharePoint (sites/teams) dang mount: $($provs.Count)"
    if ($provs.Count -eq 0) { throw "Khong tim thay thu vien SharePoint nao dang sync." }

    # ---- 3. Ghep Provider <-> dong libraryScope, dung chuoi library ID ----
    $out = @()
    foreach ($pv in $provs) {
        $name = ""
        if ($pv.Mount) { $name = ConvertTo-Ascii (Split-Path $pv.Mount -Leaf) }
        if (-not $name) { $name = ConvertTo-Ascii ($pv.Url -replace '^https://[^/]+/(sites|teams)/', '' -replace '/.*$', '') }
        $site = ([regex]::Match($pv.Url, '^https://[^/]+/(?:sites|teams)/[^/]+')).Value
        $webUrl = [uri]::EscapeDataString($site)

        $m = @($scopeLines | Where-Object { $_.Line -like "*$($pv.Key)*" })
        $status = "OK"; $value = ""
        if ($m.Count -eq 0) {
            $status = "MISSING: khong thay dong libraryScope chua $($pv.Key)"
        } else {
            $line = $m[0].Line; $tenant = $m[0].Tenant
            $mm = [regex]::Match($line, 'tenantId=([^&"\s]+)&siteId=([^&"\s]+)&webId=([^&"\s]+)&listId=([^&"\s]+)')
            if ($mm.Success) {
                $tenant = $mm.Groups[1].Value.Trim('{','}').ToLower()
                $s = $mm.Groups[2].Value; $w = $mm.Groups[3].Value; $li = $mm.Groups[4].Value
            } else {
                $g = @([regex]::Matches($line, $guidRx) | ForEach-Object { '{' + $_.Value.Trim('{','}').ToLower() + '}' } | Select-Object -Unique)
                $g = @($g | Where-Object { $_.Trim('{','}') -ne $tenant })
                if ($g.Count -ge 3) { $s = $g[0]; $w = $g[1]; $li = $g[2] } else { $status = "MISSING: chi co $($g.Count) GUID trong dong libraryScope" }
            }
            if ($status -eq "OK") {
                if (-not $site) { $status = "MISSING: khong tach duoc webUrl tu $($pv.Url)" }
                elseif (-not $tenant) { $status = "MISSING: khong biet tenantId" }
                else { $value = "tenantId=$tenant&siteId=$s&webId=$w&listId=$li&webUrl=$webUrl&version=1" }
            }
        }
        $out += [pscustomobject]@{ Name = $name; Value = $value; Source = $pv.Url; Status = $status }
    }

    # ---- 4. Kiem tra ----
    $dupName = @($out | Group-Object Name | Where-Object { $_.Count -gt 1 })
    foreach ($d in $dupName) { Write-Output "WARN: trung ten '$($d.Name)' ($($d.Count) thu vien) - sua Name trong CSV roi chay lai voi -FromCsv"; foreach ($o in $d.Group) { $o.Status = "DUP-NAME" } }
    $ok = @($out | Where-Object { $_.Status -eq "OK" })
    $webListKey = @($ok | Group-Object { ($_.Value -split '&')[2] + ($_.Value -split '&')[3] } | Where-Object { $_.Count -gt 1 })
    foreach ($d in $webListKey) { Write-Output "WARN: $($d.Count) thu vien co CUNG webId+listId (hiem, nghi ID sai): $(($d.Group | ForEach-Object Name) -join ', ')" }

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
