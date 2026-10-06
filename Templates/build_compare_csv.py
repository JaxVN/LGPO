#!/usr/bin/env python3
"""Tao Templates/Template-Compare.csv tu cac ZIP mau (Templates/Win11, Templates/Win10).

Moi dong = 1 file hoac 1 setting trong ZIP. Cot "Win 11" / "Win10" = gia tri trong ZIP tuong ung
(trong = khong co). "Note 1" / "Note 2" do nguoi dung nhap tay - chay lai script se GIU NGUYEN
note cu (khop theo Item type + Path + Section + Name).

Chay:  python3 Templates/build_compare_csv.py
"""
import csv, io, json, re, struct, sys, zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
OUT = HERE / "Template-Compare.csv"
SOURCES = [("Win 11", HERE / "Win11" / "GPO-Template.zip"), ("Win10", HERE / "Win10" / "GPO-Template.zip")]
HEADER = ["Item type", "Path in zip", "Section / Registry key", "Name", "Type", "Win 11", "Win10", "Note 1", "Note 2"]
GUID = re.compile(r"\{[0-9A-Fa-f]{8}-(?:[0-9A-Fa-f]{4}-){3}[0-9A-Fa-f]{12}\}")
REG_TYPES = {0: "REG_NONE", 1: "REG_SZ", 2: "REG_EXPAND_SZ", 3: "REG_BINARY", 4: "REG_DWORD", 7: "REG_MULTI_SZ", 11: "REG_QWORD"}
SRP_PATH = re.compile(r"^(.*\\CodeIdentifiers\\(\d+)\\Paths)\\\{[0-9A-Fa-f-]{36}\}$", re.I)
SRP_LEVEL = {"0": "Disallowed", "262144": "Unrestricted", "131072": "Basic User", "65536": "Constrained"}


def norm_path(name):
    return GUID.sub("{GUID}", name.replace("\\", "/"))


def decode_text(b):
    if b[:2] in (b"\xff\xfe", b"\xfe\xff"):
        return b.decode("utf-16")
    if b[:3] == b"\xef\xbb\xbf":
        return b[3:].decode("utf-8")
    try:
        return b.decode("utf-8")
    except UnicodeDecodeError:
        return b.decode("cp1252", "replace")


def parse_pol(data):
    """PReg -> [(key, name, type_str, value_str)]"""
    out, i = [], 8
    if data[:4] != b"PReg":
        return out

    def read_str(i):
        j = i
        while data[j:j + 2] != b"\x00\x00" or (j - i) % 2:
            j += 1
        return data[i:j].decode("utf-16le"), j + 2

    while i + 2 <= len(data):
        if data[i:i + 2] != b"[\x00":
            i += 1
            continue
        i += 2
        key, i = read_str(i); i += 2            # ';'
        name, i = read_str(i); i += 2
        typ = struct.unpack_from("<I", data, i)[0]; i += 4 + 2
        size = struct.unpack_from("<I", data, i)[0]; i += 4 + 2
        raw = data[i:i + size]; i += size + 2   # ']'
        if typ == 4 and size >= 4:
            val = str(struct.unpack_from("<I", raw)[0])
        elif typ == 11 and size >= 8:
            val = str(struct.unpack_from("<Q", raw)[0])
        elif typ in (1, 2):
            val = raw.decode("utf-16le", "replace").rstrip("\x00")
        elif typ == 7:
            val = " | ".join(s for s in raw.decode("utf-16le", "replace").split("\x00") if s)
        else:
            val = raw.hex()
        out.append((key, name, REG_TYPES.get(typ, str(typ)), val))
    return out


def pol_rows(path, data):
    rows, srp = [], {}
    entries = parse_pol(data)
    for key, name, typ, val in entries:
        m = SRP_PATH.match(key)
        if m:
            d = srp.setdefault(key, {"base": m.group(1), "lvl": m.group(2)})
            d[name] = val
        else:
            rows.append(("Setting", path, key, name or "(key)", typ, val))
    for key, d in srp.items():
        info = SRP_LEVEL.get(d["lvl"], d["lvl"])
        desc = d.get("Description", "")
        rows.append(("SRP path rule", path, d["base"], d.get("ItemData", ""), "SRP path rule", info + (" - " + desc if desc else "")))
    return rows


def inf_rows(path, text):
    rows, sec = [], None
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith(";"):
            continue
        m = re.match(r"^\[(.+)\]$", line)
        if m:
            sec = m.group(1); continue
        if sec in (None, "Unicode", "Version"):
            continue
        if sec == "Registry Values" and "=" in line:
            k, v = line.split("=", 1)
            rows.append(("Security", path, sec, k, "Security option", v))
        elif "=" in line:
            k, v = line.split("=", 1)
            rows.append(("Security", path, sec, k.strip(), "Security", v.strip()))
    return rows


def audit_rows(path, text):
    rows = []
    for r in csv.DictReader(io.StringIO(text)):
        sub = r.get("Subcategory", "")
        if sub:
            rows.append(("Audit", path, "Advanced Audit Policy", sub, "Audit", r.get("Inclusion Setting", "")))
    return rows


DISP = {}


def read_zip(zpath):
    disp = DISP
    """-> {(item_type, path, section, name): (type, value)} va thu tu dong"""
    items, order = {}, []

    def add(rows):
        for t, p, s, n, ty, v in rows:
            k = (t, p, s.lower(), n.lower())      # registry khong phan biet hoa/thuong
            if k not in items:
                order.append(k)
                disp[k] = (s, n)
            items[k] = (ty, v)

    with zipfile.ZipFile(zpath) as z:
        add([("File", zpath.name, "", "", "zip", str(zpath.stat().st_size))])
        for info in z.infolist():
            if info.is_dir():
                continue
            p = norm_path(info.filename)
            add([("File", p, "", "", "file", str(info.file_size))])
            data = z.read(info)
            low = p.lower()
            if low.endswith(".pol"):
                add(pol_rows(p, data))
            elif low.endswith("gpttmpl.inf"):
                add(inf_rows(p, decode_text(data)))
            elif low.endswith("audit.csv"):
                add(audit_rows(p, decode_text(data)))
            elif low.endswith("manifest.json"):
                for k, v in json.loads(decode_text(data)).items():
                    if k != "BackupId":
                        add([("Manifest", p, "", k, "info", str(v))])
    return items, order


def main():
    old_notes = {}
    if OUT.exists():
        with open(OUT, encoding="utf-8-sig", newline="") as f:
            for r in csv.DictReader(f):
                old_notes[(r["Item type"], r["Path in zip"], r["Section / Registry key"].lower(), r["Name"].lower())] = (r["Note 1"], r["Note 2"])

    data, order = {}, []
    for label, zpath in SOURCES:
        if zpath.exists():
            data[label], o = read_zip(zpath)
            order += [k for k in o if k not in order]
        else:
            print("Bo qua (chua co):", zpath, file=sys.stderr)
            data[label] = {}

    def sort_key(k):
        return ({"File": 0, "Manifest": 1, "Setting": 2, "SRP path rule": 3, "Security": 4, "Audit": 5}.get(k[0], 9), k[1], k[2], k[3].lower())

    with open(OUT, "w", encoding="utf-8-sig", newline="") as f:
        w = csv.writer(f)
        w.writerow(HEADER)
        for k in sorted(order, key=sort_key):
            v11, v10 = data["Win 11"].get(k), data["Win10"].get(k)
            ty = (v11 or v10)[0]
            n1, n2 = old_notes.get(k, ("", ""))
            sec, nm = DISP[k]
            w.writerow([k[0], k[1], sec, nm, ty, v11[1] if v11 else "", v10[1] if v10 else "", n1, n2])
    print(f"Wrote {OUT} ({len(order)} rows)")


if __name__ == "__main__":
    main()
