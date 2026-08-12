import pathlib
p = pathlib.Path("dissekt-web/src/components/ScanInput.tsx")
lines = p.read_text().splitlines(keepends=True)
start = next(i for i, l in enumerate(lines)
             if "background: '#f0f0ee', borderRadius: 8, padding: 3" in l)
end = next(i for i, l in enumerate(lines[start:], start) if l.rstrip() == "          </div>")
assert end - start == 4, f"unexpected span {start+1}..{end+1}"
block = "".join(lines[start:end + 1])
assert "setMode" in block and block.count("<div") == 1, "shape mismatch"
p.write_text("".join(lines[:start] + lines[end + 1:]))
print(f"removed lines {start+1}-{end+1}")
