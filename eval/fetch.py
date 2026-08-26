import asyncio, sys, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))
from app.beacon import extract_from_url

async def main():
    genre, url = sys.argv[1], sys.argv[2]
    text, title = await extract_from_url(url)
    text = (text or "").strip()
    domain = url.split("//")[-1].split("/")[0].replace("www.", "")
    p = pathlib.Path("eval/raw") / f"{genre}__{domain.replace('.', '_')}.txt"
    p.parent.mkdir(parents=True, exist_ok=True)
    if len(text.split()) < 120:
        print(f"THIN  {len(text.split())} words — {title[:60]}")
        print(text[:400]); return
    p.write_text(text, encoding="utf-8")
    print(f"{p}  —  {len(text.split())} words  —  {title[:60]}")

asyncio.run(main())
