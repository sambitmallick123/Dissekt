import pathlib
p = pathlib.Path("dissekt-web/src/components/SpectrumCard.tsx")
src = p.read_text()
old = (
"          <div style={metricBox}>\n"
"            <div style={metricLabel}>Toxicity</div>\n"
"            <span style={{ fontSize: 14, fontWeight: 600, color: toxColor }}>{toxLabel}</span>\n"
"            <span style={{ fontSize: 11, color: '#aaa', marginLeft: 4 }}>({(tox*100).toFixed(1)}%)</span>\n"
"          </div>\n"
)
assert src.count(old) == 1, f"{src.count(old)} matches"
p.write_text(src.replace(old, ""))
print("removed toxicity metric box")
