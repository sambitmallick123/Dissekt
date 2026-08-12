import ast, pathlib

EDITS = [
 ("app/scoring.py",
  'def compute_tone(text: str, raw_toxicity: float, sentiment_compound: float, source_name: str = "") -> dict:',
  'def compute_tone(text: str, sentiment_compound: float, source_name: str = "") -> dict:'),
 ("app/scoring.py",
  "    baseline = GENRE_BASELINES.get(genre, 0.06)\n"
  "    adjusted_tox = max(raw_toxicity - baseline, 0) / max(1.0 - baseline, 0.01)\n"
  "    quote_ratio = len(quoted) / max(len(text), 1)\n"
  "    editorial_tox = adjusted_tox * (1.0 - quote_ratio * 0.6)\n",
  "    quote_ratio = len(quoted) / max(len(text), 1)\n"),
 ("app/scoring.py", "    tox_pen = editorial_tox * 0.30\n    host_pen", "    host_pen"),
 ("app/scoring.py", "1.0 - tox_pen - host_pen - sent_pen", "1.0 - host_pen - sent_pen"),
 ("app/scoring.py",
  '"score": _round(score), "raw_toxicity": _round(raw_toxicity), "adjusted_toxicity": _round(editorial_tox), "hostility"',
  '"score": _round(score), "hostility"'),
 ("app/scoring.py",
  '"penalties": {"toxicity": _round(tox_pen), "hostility"', '"penalties": {"hostility"'),
 ("app/scoring.py",
  "def compute_full_score(techniques: list, fact_checks: list, toxicity_score: float,\n"
  "                       sentiment_compound: float,",
  "def compute_full_score(techniques: list, fact_checks: list,\n"
  "                       sentiment_compound: float,"),
 ("app/scoring.py",
  "    tone = compute_tone(text, toxicity_score, sentiment_compound, source_name)",
  "    tone = compute_tone(text, sentiment_compound, source_name)"),
 ("app/beacon/__init__.py", "        tox_raw = 0.0\n        sent_raw = 0.0", "        sent_raw = 0.0"),
 ("app/beacon/__init__.py",
  "            tox_raw = sig.get('toxicity_score', 0.0)\n            sent_raw", "            sent_raw"),
 ("app/beacon/__init__.py",
  "            toxicity_score=tox_raw, sentiment_compound=sent_raw,", "            sentiment_compound=sent_raw,"),
 ("app/beacon/__init__.py",
  'signal_raw = {"toxicity_score": 0.0, "toxicity_labels": {}, "source_bias": None,',
  'signal_raw = {"source_bias": None,'),
]

for path, old, new in EDITS:
    p = pathlib.Path(path)
    src = p.read_text()
    assert src.count(old) == 1, f"{path}: {src.count(old)} matches for {old[:60]!r}"
    out = src.replace(old, new)
    ast.parse(out)
    p.write_text(out)
    print(f"ok  {path}: {old[:50]!r}")
