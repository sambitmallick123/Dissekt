import ast, pathlib

EDITS = [
 ("app/models.py",
  '\n    toxicity_score: float = Field(default=0.0, ge=0.0, le=1.0)'
  '\n    toxicity_labels: dict[str, float] = Field(default_factory=dict)',
  ''),
 ("app/beacon/__init__.py",
  '    if light:\n'
  '        async def _light_signal():\n'
  '            return run_spectrum(extracted_text, source_url, skip_toxicity=True)\n'
  '        signal_task = _light_signal()\n'
  '    else:\n'
  '        signal_task = asyncio.to_thread(run_spectrum, extracted_text, source_url)\n',
  '    signal_task = asyncio.to_thread(run_spectrum, extracted_text, source_url)\n'),
]

for path, old, new in EDITS:
    p = pathlib.Path(path)
    src = p.read_text()
    assert src.count(old) == 1, f"{path}: expected 1 match, got {src.count(old)}"
    out = src.replace(old, new)
    ast.parse(out)
    p.write_text(out)
    print(f"patched {path}")
