#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt
# Replace the OLD constellation endpoint with the COMPLETE one (preview + related scans)
set -e

python3 << 'PYEOF'
import re
c = open('app/main.py').read()

# Remove the existing @app.get("/api/constellation") ... function entirely.
# It starts at the decorator and ends right before the next @app. decorator.
pattern = r'@app\.get\("/api/constellation"\).*?(?=@app\.(get|post|put|delete|patch)\()'
m = re.search(pattern, c, re.DOTALL)
if not m:
    print("⚠️ could not locate existing constellation block — aborting")
    raise SystemExit(1)

print(f"Removing old endpoint ({len(m.group(0))} chars)")
c = c[:m.start()] + c[m.end():]

# Now insert the complete version before /api/techniques
marker = '@app.get("/api/techniques")'
endpoint = '''@app.get("/api/constellation")
async def constellation(email: str, preview: bool = False):
    """Member knowledge graph. Nodes=entities, edges=co-occurrence + technique-similarity.
    Each node carries related scans (analysis_id -> /report/{id}). preview bypasses threshold."""
    from fastapi import HTTPException
    if not email:
        raise HTTPException(status_code=400, detail="email required")
    try:
        _settings = get_settings()
        from supabase import create_client
        sb = create_client(_settings.supabase_url, _settings.supabase_service_key)
        rows = sb.table("scans").select(
            "id, analysis_id, techniques, entities, toxicity, clarity, created_at"
        ).eq("user_email", email).order("created_at", desc=True).limit(500).execute()
        scans = rows.data or []
        THRESHOLD = 10
        if len(scans) < THRESHOLD and not preview:
            return {"ready": False, "count": len(scans), "needed": THRESHOLD, "nodes": [], "edges": []}

        import math
        from collections import defaultdict, Counter
        STOP = {"ever", "dumbest", "president", "the", "a", "an", "this", "that",
                "it", "is", "was", "they", "we", "you", "i"}

        node_data = {}
        for s in scans:
            ents = s.get("entities") or []
            techs = [t.get("name") for t in (s.get("techniques") or []) if t.get("name")]
            top_tech = techs[0] if techs else None
            tox = s.get("toxicity") or 0.0
            clar = s.get("clarity")
            aid = s.get("analysis_id") or ""
            created = s.get("created_at", "")
            for e in ents:
                name = (e.get("name") or "").strip()
                if not name or name.lower() in STOP or len(name) < 2:
                    continue
                key = name.lower()
                if key not in node_data:
                    node_data[key] = {"name": name, "type": e.get("type", "topic"),
                                      "freq": 0, "tox_sum": 0.0, "clar_sum": 0.0, "clar_n": 0,
                                      "tech": Counter(), "scans": []}
                nd = node_data[key]
                nd["freq"] += 1
                nd["tox_sum"] += tox
                if clar is not None:
                    nd["clar_sum"] += clar; nd["clar_n"] += 1
                for t in techs:
                    nd["tech"][t] += 1
                if aid:
                    nd["scans"].append({"analysis_id": aid,
                        "clarity": round(clar, 3) if clar is not None else None,
                        "top_technique": top_tech, "toxicity": round(tox, 3),
                        "created_at": created})

        items = list(node_data.items())
        if len(items) > 40:
            items = [(k, v) for k, v in items if v["freq"] >= 2]

        nodes = []
        for key, nd in items:
            avg_tox = nd["tox_sum"] / max(nd["freq"], 1)
            avg_clar = (nd["clar_sum"] / nd["clar_n"]) if nd["clar_n"] else None
            nodes.append({"id": key, "name": nd["name"], "type": nd["type"],
                "freq": nd["freq"], "toxicity": round(avg_tox, 3),
                "clarity": round(avg_clar, 3) if avg_clar is not None else None,
                "top_techniques": [t for t, _ in nd["tech"].most_common(3)],
                "scans": nd["scans"][:10]})
        valid = {k for k, _ in items}

        co = defaultdict(int)
        for s in scans:
            ks = sorted({(e.get("name") or "").strip().lower()
                         for e in (s.get("entities") or [])
                         if (e.get("name") or "").strip().lower() in valid})
            for i in range(len(ks)):
                for j in range(i+1, len(ks)):
                    co[(ks[i], ks[j])] += 1

        all_t = sorted({t for _, nd in items for t in nd["tech"]})
        tix = {t: i for i, t in enumerate(all_t)}
        def vec(nd):
            v = [0.0]*len(all_t)
            for t, ct in nd["tech"].items():
                v[tix[t]] = ct
            return v
        def cosim(a, b):
            d = sum(x*y for x, y in zip(a, b))
            na = math.sqrt(sum(x*x for x in a)); nb = math.sqrt(sum(y*y for y in b))
            return d/(na*nb) if na and nb else 0.0
        vecs = {k: vec(nd) for k, nd in items}
        tech_edges = []
        ks = list(vecs.keys())
        for i in range(len(ks)):
            for j in range(i+1, len(ks)):
                if any(vecs[ks[i]]) and any(vecs[ks[j]]):
                    sim = cosim(vecs[ks[i]], vecs[ks[j]])
                    if sim >= 0.5:
                        tech_edges.append((ks[i], ks[j], round(sim, 2)))

        edges = []
        for (a, b), ct in co.items():
            edges.append({"source": a, "target": b, "type": "co", "weight": ct})
        for (a, b, sim) in tech_edges:
            edges.append({"source": a, "target": b, "type": "tech", "weight": sim})

        return {"ready": True, "count": len(scans), "nodes": nodes, "edges": edges,
                "stats": {"nodes": len(nodes), "co_edges": len(co), "tech_edges": len(tech_edges)}}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[constellation] failed: {e}")
        from fastapi import HTTPException
        raise HTTPException(status_code=500, detail=f"Constellation failed: {e}")

'''
c = c.replace(marker, endpoint + marker, 1)
open('app/main.py','w').write(c)
print("✅ Replaced with complete constellation endpoint (preview + related scans)")
PYEOF

python3 -c "import ast; ast.parse(open('app/main.py').read()); print('✅ parses')"
echo ""
echo "Verify (should now show preview param):"
grep -n 'async def constellation' app/main.py
grep -c 'preview' app/main.py | head -1
echo ""
echo "Push: git add app/main.py && git commit -m 'fix: complete constellation endpoint (preview+scans)' && git push"
