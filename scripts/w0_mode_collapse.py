import pathlib, re

W = "dissekt-web/src/"
EDITS = [
 # limits: one number per tier, both keys same value
 ("app/main.py",
  'DEFAULTS = {"member": {"brief": 25, "detailed": 10}, "free": {"brief": 3, "detailed": 1}}',
  'DEFAULTS = {"member": {"brief": 15, "detailed": 15}, "free": {"brief": 3, "detailed": 3}}'),

 # ScanInput: no toggle, always detailed
 (W+"components/ScanInput.tsx",
  "  const [mode, setMode] = useState<'brief' | 'detailed'>('brief');\n", ""),
 (W+"components/ScanInput.tsx",
  "onScan(content.trim(), mode, image || undefined)",
  "onScan(content.trim(), 'detailed', image || undefined)"),

 # analyze: drop the member/feature gate on detailed
 (W+"app/analyze/page.tsx",
  "    const mode = (modeArg === 'detailed' ? 'detailed' : 'brief') as 'brief' | 'detailed';",
  "    const mode: 'brief' | 'detailed' = 'detailed';"),
 (W+"app/analyze/page.tsx", "handleScan(incoming, 'brief')", "handleScan(incoming, 'detailed')"),
 (W+"app/analyze/page.tsx", "handleScan(text, 'brief')", "handleScan(text, 'detailed')"),
 (W+"app/analyze/page.tsx",
  "              {' · '}{remaining.brief} brief, {remaining.detailed} detailed left",
  "              {' · '}{remaining.detailed} scans left"),
 (W+"app/analyze/page.tsx",
  "  const [remaining, setRemaining] = useState<{ brief: number; detailed: number; tier: 'free' | 'member' }>"
  "({ brief: 3, detailed: 1, tier: 'free' });",
  "  const [remaining, setRemaining] = useState<{ brief: number; detailed: number; tier: 'free' | 'member' }>"
  "({ brief: 3, detailed: 3, tier: 'free' });"),
]

for path, old, new in EDITS:
    p = pathlib.Path(path)
    src = p.read_text()
    assert src.count(old) == 1, f"{path}: {src.count(old)} matches for {old[:70]!r}"
    p.write_text(src.replace(old, new))
    print(f"ok  {path}")
