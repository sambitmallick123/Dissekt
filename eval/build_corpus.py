import json, pathlib
raw = pathlib.Path("eval/raw")
out = []
for i, f in enumerate(sorted(raw.glob("*.txt")), 1):
    genre, _, source = f.stem.partition("__")
    text = f.read_text(encoding="utf-8").strip()
    if len(text) < 200:
        print(f"SKIP {f.name}: only {len(text)} chars"); continue
    out.append({"id": f"g{i:03d}", "genre": genre,
                "source": source.replace("_", "."), "url": "", "text": text})
pathlib.Path("eval/corpus/genre.jsonl").write_text(
    "\n".join(json.dumps(r, ensure_ascii=False) for r in out) + "\n")
print(f"wrote {len(out)} items")
for g in sorted({r['genre'] for r in out}):
    print(f"  {g}: {sum(1 for r in out if r['genre']==g)}")
