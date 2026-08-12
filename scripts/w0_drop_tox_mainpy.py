import ast, pathlib

EDITS = [
 # persist: stop writing a hardcoded zero to Supabase (column stays, new rows null)
 ("app/main.py",
  '        toxicity = g(result, "signal", "toxicity_score", default=0.0)\n', ""),
 ("app/main.py", '            "toxicity": toxicity,\n', ""),

 # keyword aggregate: drop the per-article field
 ("app/main.py",
  '            tox = ((rd.get("signal") or {}).get("toxicity_score")) or 0.0\n', ""),
 ("app/main.py",
  '                    "toxicity": round(tox, 3), "techniques": techs, "ok": True}',
  '                    "techniques": techs, "ok": True}'),
 ("app/main.py",
  '    tox_vals = [a["toxicity"] for a in good if a.get("toxicity") is not None]\n', ""),
 ("app/main.py",
  '    avg_tox = round(sum(tox_vals)/len(tox_vals), 3) if tox_vals else None\n', ""),
 ("app/main.py",
  '                "avg_clarity": avg_clar, "avg_toxicity": avg_tox,',
  '                "avg_clarity": avg_clar,'),

 # compare: score_diff was toxicity-based despite the name — use clarity
 ("app/main.py",
  '                "score_diff": abs(\n'
  '                    (dict_a.get("signal", {}).get("toxicity_score", 0) * 100) -\n'
  '                    (dict_b.get("signal", {}).get("toxicity_score", 0) * 100)\n'
  '                ),',
  '                "score_diff": abs(\n'
  '                    ((dict_a.get("scoring") or {}).get("clarity_score") or 0) * 100 -\n'
  '                    ((dict_b.get("scoring") or {}).get("clarity_score") or 0) * 100\n'
  '                ),'),

 # telegram bot
 ("app/telegram_bot/__init__.py",
  '    tox = data.get("signal", {}).get("toxicity_score", 0)\n', ""),
]

for path, old, new in EDITS:
    p = pathlib.Path(path)
    src = p.read_text()
    assert src.count(old) == 1, f"{path}: {src.count(old)} matches for {old[:60]!r}"
    out = src.replace(old, new)
    ast.parse(out)
    p.write_text(out)
    print(f"ok  {path}: {old[:50]!r}")
