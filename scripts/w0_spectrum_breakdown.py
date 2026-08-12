import pathlib
p = pathlib.Path("dissekt-web/src/components/SpectrumCard.tsx")
lines = p.read_text().splitlines(keepends=True)
start = next(i for i, l in enumerate(lines) if "signal.toxicity_labels &&" in l)
end   = next(i for i, l in enumerate(lines[start:], start) if l.rstrip() == "        )}")
assert end - start == 17, f"unexpected span {start+1}..{end+1}"
block = "".join(lines[start:end + 1])
assert block.count("toxicity") == 3 and block.count("(") == block.count(")"), "shape mismatch"
p.write_text("".join(lines[:start] + lines[end + 1:]))
print(f"removed lines {start+1}-{end+1}")
