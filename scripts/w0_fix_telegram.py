import ast, pathlib
p = pathlib.Path("app/telegram_bot/__init__.py")
src = p.read_text()
EDITS = [
 (" + round(tox * 20)", ""),
 ('    lines.append(f"📊 Toxicity: {tox*100:.1f}% | Sentiment: '
  "{data.get('signal', {}).get('sentiment', 'neutral')}\")",
  '    lines.append(f"📊 Sentiment: '
  "{data.get('signal', {}).get('sentiment', 'neutral')}\")"),
]
for old, new in EDITS:
    assert src.count(old) == 1, f"{src.count(old)} matches for {old[:60]!r}"
    src = src.replace(old, new)
ast.parse(src)
p.write_text(src)
print("patched telegram_bot")
