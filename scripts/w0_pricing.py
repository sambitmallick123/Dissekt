import pathlib
p = pathlib.Path("dissekt-web/src/components/LandingPage.tsx")
src = p.read_text()
EDITS = [
 ("3 brief / day<br />1 detailed / day<br />Help + Feedback",
  "3 scans / day<br />Help + Feedback"),
 ("25 brief / day<br />10 detailed / day<br />All features + API + Dashboard",
  "15 scans / day<br />Dashboard + scan history"),
]
for old, new in EDITS:
    assert src.count(old) == 1, f"{src.count(old)} matches for {old[:40]!r}"
    src = src.replace(old, new)
p.write_text(src)
print("pricing updated")
