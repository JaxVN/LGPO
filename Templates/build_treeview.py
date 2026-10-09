#!/usr/bin/env python3
"""Tao docs/Template-Treeview.html (1 file, mo bang trinh duyet) tu Templates/Template-Compare.csv.

Cay giong gpedit: Computer/User Configuration -> Windows Settings -> Security Settings,
Administrative Templates (registry policy theo duong dan), SRP, GPO domain dang ap.
Moi la hien 3 cot Win 11 | Win10 | Domain + trang thai (Giong / Khac / Chi o ...).

Chay:  python3 Templates/build_treeview.py
"""
import csv, json, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
SRC = HERE / "Template-Compare.csv"
OUT = HERE.parent / "docs" / "Template-Treeview.html"

SEC_ROOT = ["Computer Configuration", "Windows Settings", "Security Settings"]


def tree_path(r):
    t, sec, name = r["Item type"], r["Section / Registry key"], r["Name"]
    if t == "Security":
        if sec == "System Access":
            return SEC_ROOT + ["Account Policies / System Access (mật khẩu, khóa tài khoản)"], name
        if sec == "Event Audit":
            return SEC_ROOT + ["Local Policies", "Audit Policy (cũ)"], name
        if sec == "Privilege Rights":
            return SEC_ROOT + ["Local Policies", "User Rights Assignment"], name
        if sec == "Registry Values":
            return SEC_ROOT + ["Local Policies", "Security Options"], name.split("\\")[-1]
        return SEC_ROOT + [sec], name
    if t == "Audit":
        return SEC_ROOT + ["Advanced Audit Policy Configuration"], name
    if t == "SRP path rule":
        return ["User Configuration", "Windows Settings", "Security Settings", "Software Restriction Policies", "Additional Rules", sec], name
    if t == "Registry policy":
        parts = sec.split("\\")
        hive, rest = parts[0], parts[1:]
        root = "Computer Configuration" if hive == "HKLM" else "User Configuration"
        return [root, "Administrative Templates / Registry policy (" + hive + ")"] + rest, name
    if t == "Domain GPO applied":
        scope, _, link = sec.partition(" | ")
        return ["GPO domain đang áp", scope, link or "?"], name
    if t == "Manifest":
        return ["Thông tin máy nguồn"], name
    if t == "File":
        return ["Nội dung gói zip (file)"], r["Path in zip"] + (" (" + r["Name"] + ")" if r["Name"] else "")
    return [t], name


def status(w11, w10, dom):
    vals = [("Win 11", w11), ("Win10", w10), ("Domain", dom)]
    pres = [(k, v) for k, v in vals if v != ""]
    if len(pres) == 1:
        return "only", "Chỉ ở " + pres[0][0]
    if len({v.lower() for _, v in pres}) == 1:
        return "same", "Giống nhau"
    return "diff", "Khác giá trị"


def main():
    rows = list(csv.DictReader(open(SRC, encoding="utf-8-sig", newline="")))
    root = {"n": "Template compare", "k": {}, "disp": {}, "leaves": []}
    skipped = 0
    for r in rows:
        w11, w10, dom = r["Win 11"], r["Win10"], r["Domain"]
        if r["Type"] == "REG_NONE" and not (w11 or w10 or dom):
            skipped += 1
            continue
        path, name = tree_path(r)
        node = root
        for seg in path:
            key = seg.lower()
            node = node["k"].setdefault(key, {"n": seg, "k": {}, "leaves": []})
        st, stxt = status(w11, w10, dom)
        full = (r["Section / Registry key"] + "\\" if r["Section / Registry key"] and r["Item type"] not in ("Security", "Audit", "SRP path rule", "Domain GPO applied") else "") + r["Name"]
        if r["Item type"] == "Security" and r["Section / Registry key"] == "Registry Values":
            full = r["Name"]
        note = " | ".join(x for x in (r["Note 1"], r["Note 2"]) if x)
        node["leaves"].append({"n": name, "a": w11, "b": w10, "c": dom, "s": st, "t": stxt, "tip": full + ("  [" + r["Type"] + "]" if r["Type"] else ""), "note": note})

    def conv(node):
        kids = [conv(c) for c in sorted(node["k"].values(), key=lambda x: x["n"].lower())]
        leaves = sorted(node["leaves"], key=lambda x: x["n"].lower())
        out = {"n": node["n"], "c": kids, "l": leaves}
        while len(out["c"]) == 1 and not out["l"] and out is not None:        # gop chuoi 1 nhanh (compact folders)
            only = out["c"][0]
            out = {"n": out["n"] + " \u203a " + only["n"], "c": only["c"], "l": only["l"]}
        return out
    tree = conv(root)
    sources = {r["Name"]: (r["Win 11"], r["Win10"], r["Domain"]) for r in rows if r["Item type"] == "Manifest" and r["Name"] in ("Computer", "OS", "Build", "Created")}
    data = {"tree": tree, "sources": sources, "skipped": skipped, "total": len(rows)}
    html = TEMPLATE.replace("/*DATA*/", json.dumps(data, ensure_ascii=False).replace("</", "<\\/"))
    OUT.parent.mkdir(exist_ok=True)
    OUT.write_text(html, encoding="utf-8")
    print(f"Wrote {OUT} ({len(html)//1024} KB, {len(rows)-skipped} muc, bỏ qua {skipped} khóa rỗng)")


TEMPLATE = r"""<!doctype html>
<html lang="vi">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Template Treeview</title>
<style>
:root{--bg:#f7f7f5;--panel:#fff;--fg:#1d1d1b;--muted:#6b6b66;--line:#e4e3de;--hover:#f0efe9;
--same:#2f7d4f;--same-bg:#e6f3ea;--diff:#a35a00;--diff-bg:#fbefd9;--only:#1f5fa8;--only-bg:#e3eefa;--acc:#2a6df4}
@media (prefers-color-scheme:dark){:root:not([data-theme=light]){--bg:#171716;--panel:#1f1f1d;--fg:#ecebe6;--muted:#9a9990;--line:#33332f;--hover:#2a2a27;
--same:#6fcf97;--same-bg:#1d3326;--diff:#f2b35c;--diff-bg:#3a2d17;--only:#7fb4f2;--only-bg:#1b2c42;--acc:#7aa2ff}}
:root[data-theme=dark]{--bg:#171716;--panel:#1f1f1d;--fg:#ecebe6;--muted:#9a9990;--line:#33332f;--hover:#2a2a27;
--same:#6fcf97;--same-bg:#1d3326;--diff:#f2b35c;--diff-bg:#3a2d17;--only:#7fb4f2;--only-bg:#1b2c42;--acc:#7aa2ff}
*{box-sizing:border-box}
html,body{margin:0;background:var(--bg);color:var(--fg);font:14px/1.45 system-ui,-apple-system,"Segoe UI",Roboto,sans-serif}
header{padding:16px 16px 8px;max-width:1500px;margin:0 auto}
h1{font-size:18px;margin:0 0 4px}
.src{color:var(--muted);font-size:12px}
.bar{position:sticky;top:0;z-index:5;background:var(--bg);padding:8px 16px;border-bottom:1px solid var(--line)}
.bar-in{max-width:1500px;margin:0 auto;display:flex;flex-wrap:wrap;gap:8px;align-items:center}
input[type=search]{flex:1 1 240px;min-width:0;padding:7px 10px;border:1px solid var(--line);border-radius:8px;background:var(--panel);color:var(--fg);font:inherit}
button,label.chk{border:1px solid var(--line);background:var(--panel);color:var(--fg);padding:6px 10px;border-radius:8px;font:inherit;cursor:pointer}
button:hover{background:var(--hover)}
label.chk{display:inline-flex;gap:6px;align-items:center}
.stats{color:var(--muted);font-size:12px;margin-left:auto}
main{max-width:1500px;margin:0 auto;padding:12px 16px 40px}
.wrap{background:var(--panel);border:1px solid var(--line);border-radius:10px;overflow:auto;max-height:calc(100vh - 170px)}
.cols,.row{display:grid;grid-template-columns:minmax(320px,1fr) 180px 180px 240px 130px 140px;gap:0;align-items:start;min-width:1200px}
.cols{position:sticky;top:0;background:var(--panel);border-bottom:1px solid var(--line);font-weight:600;font-size:12px;color:var(--muted);z-index:2}
.cols>div{padding:8px 10px}
.row{border-bottom:1px solid var(--line)}
.row:hover{background:var(--hover)}
.cell{padding:6px 10px;overflow-wrap:anywhere;font-size:13px}
.name{display:flex;gap:6px;align-items:flex-start}
.tg{width:16px;flex:none;color:var(--muted);user-select:none;text-align:center}
.folder>.row{cursor:pointer;font-weight:600;background:color-mix(in srgb,var(--panel) 92%,var(--fg) 4%)}
.folder>.row .cnt{font-weight:400;color:var(--muted);font-size:12px;margin-left:6px;white-space:nowrap}
.folder>.row .cnt b{color:var(--diff)}
.children{display:none}
.folder.open>.children{display:block}
.val{font-family:ui-monospace,Menlo,Consolas,monospace;font-size:12px;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden;word-break:break-all}
.leaf.full .val{display:block;-webkit-line-clamp:unset}
.leaf{cursor:default}
.badge{display:inline-block;padding:1px 8px;border-radius:999px;font-size:12px;white-space:nowrap}
.same .badge{background:var(--same-bg);color:var(--same)}
.diff .badge{background:var(--diff-bg);color:var(--diff)}
.only .badge{background:var(--only-bg);color:var(--only)}
.empty{color:var(--muted)}
.hidden{display:none!important}
mark{background:#ffe07a;color:#000;border-radius:3px}
.legend{display:flex;gap:8px;flex-wrap:wrap;margin-top:6px}
@media (max-width:640px){header,.bar,main{padding-left:10px;padding-right:10px}}
</style>
</head>
<body>
<header>
  <h1>Template Treeview &ndash; Win 11 / Win10 / Domain</h1>
  <div class="src" id="src"></div>
  <div class="legend"><span class="same"><span class="badge">Giống nhau</span></span><span class="diff"><span class="badge">Khác giá trị</span></span><span class="only"><span class="badge">Chỉ ở 1 nguồn</span></span></div>
</header>
<div class="bar"><div class="bar-in">
  <input id="q" type="search" placeholder="Tìm theo tên, đường dẫn, giá trị..." autocomplete="off">
  <label class="chk"><input id="diffOnly" type="checkbox"> Chỉ mục cần xem (khác / chỉ ở 1 nguồn)</label>
  <button id="exp">Mở hết</button><button id="col">Đóng hết</button><button id="lvl">Mở 3 cấp đầu</button>
  <span class="stats" id="stats"></span>
</div></div>
<main><div class="wrap" id="wrap">
  <div class="cols"><div>Mục</div><div>Win 11</div><div>Win10</div><div>Domain</div><div>Trạng thái</div><div>Ghi chú</div></div>
  <div id="tree"></div>
</div></main>
<script>
const DATA = /*DATA*/;
const $ = s => document.querySelector(s);
const esc = s => String(s).replace(/[&<>"]/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
let nodes = [];                      // {el, kids, leaf, folder}
function count(n){ let all=n.l.length, bad=n.l.filter(x=>x.s!=='same').length;
  n.c.forEach(c=>{const r=count(c); all+=r[0]; bad+=r[1];}); n._all=all; n._bad=bad; return [all,bad]; }
function mkVal(v){ return v===''?'<span class="empty">&ndash;</span>':'<span class="val">'+esc(v)+'</span>'; }
function build(n, depth, parent){
  const f = document.createElement('div'); f.className='folder'; f.dataset.d=depth;
  const h = document.createElement('div'); h.className='row';
  h.innerHTML = '<div class="cell name"><span class="tg">&#9656;</span><span class="lbl">'+esc(n.n)+'<span class="cnt">'+n._all+' mục'+(n._bad?' &middot; <b>'+n._bad+' cần xem</b>':'')+'</span></span></div><div></div><div></div><div></div><div></div><div></div>';
  const ch = document.createElement('div'); ch.className='children';
  f.append(h, ch);
  h.querySelector('.name').style.paddingLeft=(10+depth*16)+'px';
  const rec = {el:f, head:h, kids:[], folder:true, depth, text:n.n.toLowerCase(), box:ch, tg:h.querySelector('.tg'), lbl:h.querySelector('.lbl')};
  nodes.push(rec);
  h.onclick = () => toggle(rec);
  n.c.forEach(c => rec.kids.push(build(c, depth+1, rec)));
  n.l.forEach(l => rec.kids.push(leaf(l, depth+1)));
  rec.kids.forEach(k => ch.append(k.el));
  return rec;
}
function leaf(l, depth){
  const e = document.createElement('div'); e.className='row leaf '+l.s; e.title = l.tip + '\n(bấm vào dòng để xem đủ giá trị)'; e.onclick = ()=>e.classList.toggle('full');
  e.innerHTML = '<div class="cell name"><span class="tg"></span><span class="nm">'+esc(l.n)+'</span></div><div class="cell">'+mkVal(l.a)+'</div><div class="cell">'+mkVal(l.b)+'</div><div class="cell">'+mkVal(l.c)+'</div><div class="cell"><span class="badge">'+esc(l.t)+'</span></div><div class="cell">'+esc(l.note)+'</div>';
  e.querySelector('.name').style.paddingLeft=(10+depth*16+22)+'px';
  const rec = {el:e, leaf:true, l, depth, text:(l.n+' '+l.tip+' '+l.a+' '+l.b+' '+l.c+' '+l.note).toLowerCase(), nm:e.querySelector('.nm')};
  nodes.push(rec); return rec;
}
function setOpen(r, o){ r.el.classList.toggle('open', o); r.tg.innerHTML = o?'&#9662;':'&#9656;'; }
function toggle(r){ setOpen(r, !r.el.classList.contains('open')); }
function folders(){ return nodes.filter(r=>r.folder); }
function setLevel(max){ folders().forEach(r=>setOpen(r, r.depth<max)); }
function apply(){
  const q = $('#q').value.trim().toLowerCase(), only = $('#diffOnly').checked, active = q||only;
  let shown = 0;
  function vis(r){
    if(r.leaf){
      const ok = (!only || r.l.s!=='same') && (!q || r.text.includes(q));
      r.el.classList.toggle('hidden', !ok);
      if(ok) shown++;
      if(r.nm){ r.nm.innerHTML = q && r.l.n.toLowerCase().includes(q) ? esc(r.l.n).replace(new RegExp(q.replace(/[.*+?^${}()|[\]\\]/g,'\\$&').replace(/&/g,'&amp;'),'ig'), m=>'<mark>'+m+'</mark>') : esc(r.l.n); }
      return ok;
    }
    let any=false; r.kids.forEach(k=>{ if(vis(k)) any=true; });
    r.el.classList.toggle('hidden', !any);
    if(active && any) setOpen(r, true);
    return any;
  }
  nodes.filter(r=>r.folder && r.depth===0).forEach(vis);
  $('#stats').textContent = shown+' / '+LEAVES+' mục';
}
let LEAVES=0;
(function init(){
  const T = DATA.tree; count(T);
  LEAVES = T._all;
  const top = T.c.length || T.l.length ? T : T;
  const root = build(T, 0, null);
  $('#tree').append(root.el);
  setLevel(3);
  const s = DATA.sources, names=['Win 11','Win10','Domain'];
  const info = names.map((n,i)=> n+': '+((s.Computer||[])[i]||'?')+' ('+((s.OS||[])[i]||'').replace('Microsoft ','')+' b'+((s.Build||[])[i]||'?')+')').join('  |  ');
  $('#src').textContent = 'Nguồn: '+info+(DATA.skipped?'  |  '+DATA.skipped+' khóa rỗng không hiển thị':'');
  $('#q').addEventListener('input', apply);
  $('#diffOnly').addEventListener('change', apply);
  $('#exp').onclick = ()=>folders().forEach(r=>setOpen(r,true));
  $('#col').onclick = ()=>{ folders().forEach(r=>setOpen(r,false)); setOpen(nodes[0], true); };
  $('#lvl').onclick = ()=>setLevel(3);
  apply();
})();
</script>
</body>
</html>
"""

if __name__ == "__main__":
    main()
