#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt
# STEP 2: cluster report endpoint — LLM generates a grounded report for a chosen cluster
set -e

python3 << 'PYEOF'
lines = open('app/main.py').read().split('\n')
src = '\n'.join(lines)

if '/api/constellation/report' in src:
    print("⚠️ report endpoint already exists — skipping")
else:
    # Insert before the @app.get("/api/techniques") marker
    marker = '@app.get("/api/techniques")'
    idx = None
    for i, ln in enumerate(lines):
        if ln.strip().startswith(marker):
            idx = i
            break
    if idx is None:
        print("⚠️ marker not found")
        raise SystemExit(1)

    endpoint = '''@app.get("/api/constellation/report")
async def constellation_report(email: str, cluster: int,
                               x_admin_key: str = Header(default="")):
    """Generate a grounded LLM report for one cluster of the member's Constellation."""
    from fastapi import HTTPException
    if not email:
        raise HTTPException(status_code=400, detail="email required")
    try:
        # Reuse the constellation builder to get nodes/edges with cluster ids
        data = await constellation(email=email, preview=True, x_admin_key=x_admin_key)
        if not data.get("ready"):
            return {"ready": False, "count": data.get("count", 0), "needed": data.get("needed", 10)}

        nodes = [n for n in data["nodes"] if n.get("cluster") == cluster]
        if not nodes:
            raise HTTPException(status_code=404, detail=f"cluster {cluster} not found")

        # Gather grounded facts for this cluster
        from collections import Counter
        names = [n["name"] for n in nodes]
        tech_counter = Counter()
        clar_vals = []
        scan_ids = set()
        for n in nodes:
            for t in n.get("top_techniques", []):
                tech_counter[t] += 1
            if n.get("clarity") is not None:
                clar_vals.append(n["clarity"])
            for sc in (n.get("scans") or []):
                if sc.get("analysis_id"):
                    scan_ids.add(sc["analysis_id"])
        # edges within this cluster
        cl_ids = {n["id"] for n in nodes}
        co_pairs = [(e["source"], e["target"]) for e in data["edges"]
                    if e["type"] == "co" and e["source"] in cl_ids and e["target"] in cl_ids]
        tech_pairs = [(e["source"], e["target"]) for e in data["edges"]
                      if e["type"] == "tech" and e["source"] in cl_ids and e["target"] in cl_ids]

        clar_lo = round(min(clar_vals), 2) if clar_vals else None
        clar_hi = round(max(clar_vals), 2) if clar_vals else None
        top_techs = [{"name": t, "count": c} for t, c in tech_counter.most_common(6)]

        facts = {
            "entities": names,
            "entity_count": len(names),
            "dominant_techniques": top_techs,
            "clarity_low": clar_lo,
            "clarity_high": clar_hi,
            "scans_involved": len(scan_ids),
            "co_occurrence_pairs": co_pairs[:20],
            "technique_similarity_pairs": tech_pairs[:20],
        }

        import openai, json as _json
        _s = get_settings()
        client = openai.AsyncOpenAI(api_key=_s.openai_api_key)
        prompt = (
            "You are an analyst writing a brief for a journalist about patterns in their own "
            "content analysis history. Below is structured DATA about one cluster of topics they "
            "have analyzed. Write a clear, grounded report in 2-3 short paragraphs, then a final "
            "line starting with 'Watch for:' giving one practical thing to watch for.\\n\\n"
            "RULES:\\n"
            "- Use ONLY the data provided. Do not invent facts, sources, or numbers.\\n"
            "- Cite specific techniques and counts where relevant.\\n"
            "- If the entities span clearly different topics, say so plainly rather than forcing a single narrative.\\n"
            "- Be concise and concrete. No vague editorializing about 'democratic discourse'.\\n"
            "- Clarity is scored 0-1 where higher = clearer/less manipulative.\\n\\n"
            "DATA:\\n" + _json.dumps(facts, indent=2)
        )
        resp = await client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.4, max_tokens=500,
        )
        report_text = resp.choices[0].message.content.strip()

        return {
            "ready": True,
            "cluster": cluster,
            "report": report_text,
            "facts": facts,
            "scan_ids": list(scan_ids),
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[constellation report] failed: {e}")
        from fastapi import HTTPException
        raise HTTPException(status_code=500, detail=f"Report failed: {e}")


'''
    lines[idx:idx] = endpoint.split('\n')
    open('app/main.py','w').write('\n'.join(lines))
    print("✅ /api/constellation/report endpoint added")
PYEOF

python3 -c "import ast; ast.parse(open('app/main.py').read()); print('✅ parses')"
python3 -c "import app.main; print('✅ imports cleanly')" 2>&1 | grep -v pkg_resources | grep -v UserWarning | tail -1

echo ""
echo "Verify:"
grep -n 'constellation/report\|async def constellation_report' app/main.py

echo ""
echo "Commit + push, then test:"
echo "  git add app/main.py && git commit -m 'feat: constellation cluster report endpoint' && git push"
echo '  curl -H "X-Admin-Key: dsk-a42de644ee9ecd4fa0e9e0aa62c565d4" "https://dissekt-api.up.railway.app/api/constellation/report?email=sambitmallick123@gmail.com&cluster=0" | python3 -m json.tool'
