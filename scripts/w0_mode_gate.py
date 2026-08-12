import pathlib
p = pathlib.Path("dissekt-web/src/app/analyze/page.tsx")
src = p.read_text()
EDITS = [
 ("    // Gate detailed mode — members always have access; free users gated by feature list\n"
  "    if (mode === 'detailed' && !isMember() && !enabledFeatures.includes('detailed_mode')) {\n"
  "      checkFeature('Detailed mode', enabledFeatures);\n"
  "      return;\n"
  "    }\n", ""),
 ("setError(`Free tier limit reached for ${mode} scans (${LIMITS.free[mode]}/day). "
  "Resets in ${getResetTime()} at 00:00 GMT.`);",
  "setError(`Free tier limit reached (${LIMITS.free[mode]}/day). "
  "Resets in ${getResetTime()} at 00:00 GMT.`);"),
 ("setError(`Daily limit reached for ${mode} scans. Resets in ${getResetTime()} at 00:00 GMT.`);",
  "setError(`Daily limit reached. Resets in ${getResetTime()} at 00:00 GMT.`);"),
]
for old, new in EDITS:
    assert src.count(old) == 1, f"{src.count(old)} matches for {old[:70]!r}"
    src = src.replace(old, new)
p.write_text(src)
print("patched analyze/page.tsx")
