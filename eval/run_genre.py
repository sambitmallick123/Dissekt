import json, sys, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))
from app.scoring import compute_full_score, detect_genre
from app.prism.heuristics import run_all_heuristics, analyze_sentiment

rows = [json.loads(l) for l in open("eval/corpus/genre.jsonl") if l.strip()]
print(f"{'id':<6}{'genre':<15}{'detected':<15}{'clarity':>8}{'constr':>8}{'intent':>8}")
for r in rows:
    text = r["text"]
    if text == "PASTE":
        continue
    sent = analyze_sentiment(text)
    s = compute_full_score(
        techniques=[], fact_checks=[], sentiment_compound=sent["compound"],
        source_factuality=None, source_bias=None, text=text[:5000],
        source_name=r.get("source", ""), claims=[])
    print(f"{r['id']:<6}{r['genre']:<15}{detect_genre(text, r.get('source','')):<15}"
          f"{s['clarity_score']:>8.3f}{s['construction']['score']:>8.3f}{s['intent']['score']:>8.3f}")
