import pathlib
p = pathlib.Path("dissekt-web/src/components/ClarityScore.tsx")
src = p.read_text()
old = (
"          <div style={{ padding: '4px 8px', background: '#f8fafa', borderRadius: 4 }}>\n"
"            <div style={{ fontSize: 7, fontWeight: 600, textTransform: 'uppercase', color: '#888' }}>Toxicity</div>\n"
"            <div style={{ fontSize: 14, fontWeight: 700, color: tox > 0.3 ? '#dc2626' : '#16a34a' }}>{(tox * 100).toFixed(0)}%</div>\n"
"          </div>\n"
)
assert src.count(old) == 1, f"{src.count(old)} matches"
p.write_text(src.replace(old, ""))
print("removed toxicity chip")
