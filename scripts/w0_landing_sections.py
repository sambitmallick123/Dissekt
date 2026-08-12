import pathlib

def cut(path, start_marker, _unused, check):
    p = pathlib.Path(path); lines = p.read_text().splitlines(keepends=True)
    start = next(i for i, l in enumerate(lines) if start_marker in l)
    end = next(i for i, l in enumerate(lines[start:], start) if l.rstrip() == "      </section>")
    assert 3 < end - start < 30, f"{start_marker}: span {start+1}..{end+1}"
    block = "".join(lines[start:end + 1])
    assert check in block, f"{start_marker}: shape mismatch"
    # drop the blank line that followed the section, if present
    tail = end + 2 if end + 1 < len(lines) and lines[end + 1].strip() == "" else end + 1
    p.write_text("".join(lines[:start] + lines[tail:]))
    print(f"cut {start_marker} → lines {start+1}-{end+1}")

L = "dissekt-web/src/components/LandingPage.tsx"
cut(L, "{/* NUMBERS */}", 181, "'Media rated'")     # stats bar
cut(L, "{/* FEATURES */}", 172, "'Ledger'")          # tools grid
cut(L, "{/* 12 ENGINES */}", 138, "'Beacon'")        # engines

# AnalysisResult: LedgerButtons render block
p = pathlib.Path("dissekt-web/src/components/AnalysisResult.tsx")
src = p.read_text()
old = ("      {/* Ledger */}\n"
       "      <div className=\"anim-fade\" style={{ marginTop: 12 }}>\n"
       "        <LedgerButtons analysisId={data.id || data.blockchain?.content_hash?.slice(0, 12) || ''} "
       "inputPreview={data.input_content || data.extracted_text?.slice(0, 200) || ''} />\n"
       "      </div>\n\n")
assert src.count(old) == 1, f"AnalysisResult: {src.count(old)} matches"
p.write_text(src.replace(old, ""))
print("cut LedgerButtons block")
