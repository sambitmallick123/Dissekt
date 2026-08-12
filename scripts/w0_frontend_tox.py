import pathlib
W = "dissekt-web/src/"
EDITS = [
 (W+"components/AnalysisResult.tsx", "import BiasTags from './BiasTags';\n", ""),
 (W+"components/AnalysisResult.tsx",
  '      <div className="anim-fade"><BiasTags data={data} /></div>\n\n', ""),

 (W+"components/ClarityScore.tsx", "  const tox = data.signal?.toxicity_score || 0;\n", ""),

 (W+"components/SpectrumCard.tsx",
  "  const tox = signal.toxicity_score || 0;\n"
  "  const toxLabel = tox > 0.5 ? 'High' : tox > 0.2 ? 'Moderate' : 'Low';\n"
  "  const toxColor = tox > 0.5 ? '#dc2626' : tox > 0.2 ? '#d97706' : '#16a34a';\n", ""),

 # bulk: use the real clarity score, fix inverted colours
 (W+"components/BulkAnalysis.tsx",
  "      const tox = r.signal?.toxicity_score || 0; const bulkScore = "
  "r.scoring?.clarity_score || r.clarity_score || 50;\n"
  "      let score = (techs.length > 0 ? Math.round(maxConf * 40) : 0) + "
  "Math.min(fcs * 4, 30) + Math.round(tox * 20) + (fcs >= 3 ? 10 : 0);\n"
  "      score = Math.min(score, 100);\n",
  "      const score = Math.round((r.scoring?.clarity_score ?? 0.5) * 100);\n"),
 (W+"components/BulkAnalysis.tsx",
  "    const tox = r.signal?.toxicity_score || 0; const bulkScore = "
  "r.scoring?.clarity_score || r.clarity_score || 50;\n"
  "    let s = (techs.length > 0 ? Math.round(maxConf * 40) : 0) + "
  "Math.min(fcs * 4, 30) + Math.round(tox * 20) + (fcs >= 3 ? 10 : 0);\n"
  "    return Math.min(s, 100);\n",
  "    return Math.round((r.scoring?.clarity_score ?? 0.5) * 100);\n"),
 (W+"components/BulkAnalysis.tsx",
  "${fcs},${(tox*100).toFixed(1)}%,${r.signal?.sentiment || ''}",
  "${fcs},${r.signal?.sentiment || ''}"),
 (W+"components/BulkAnalysis.tsx",
  "  const scoreColor = (s: number) => s >= 70 ? '#dc2626' : s >= 40 ? '#d97706' : '#16a34a';",
  "  const scoreColor = (s: number) => s >= 65 ? '#16a34a' : s >= 35 ? '#d97706' : '#dc2626';"),

 # embed badge: same fix on the public share surface
 (W+"app/embed/[id]/page.tsx", "  const tox = a.signal?.toxicity_score || 0;\n", ""),
 (W+"app/embed/[id]/page.tsx",
  "{fcs.length} cross-refs · {(tox * 100).toFixed(1)}% toxicity",
  "{fcs.length} cross-refs"),
]

for path, old, new in EDITS:
    p = pathlib.Path(path)
    src = p.read_text()
    assert src.count(old) == 1, f"{path}: {src.count(old)} matches for {old[:70]!r}"
    p.write_text(src.replace(old, new))
    print(f"ok  {path}")
