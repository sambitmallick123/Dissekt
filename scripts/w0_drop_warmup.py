import ast, pathlib
p = pathlib.Path("app/main.py")
src = p.read_text().splitlines(keepends=True)
start = next(i for i, l in enumerate(src) if "Pre-load Detoxify" in l)
end   = next(i for i, l in enumerate(src) if "Detoxify warmup skipped" in l)
assert 0 < end - start <= 10, f"unexpected block span {start+1}..{end+1}"
block = "".join(src[start:end + 1])
assert "_get_detoxify" in block and block.count("try:") == 1, block
new = "".join(src[:start] + src[end + 1:])
ast.parse(new)
p.write_text(new)
print(f"removed app/main.py lines {start+1}-{end+1}")
