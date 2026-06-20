#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt
# PHASE 3: Constellation graph endpoint — nodes from entities, edges from
# co-occurrence + technique-similarity. 10-scan threshold.
set -e

python3 << 'PYEOF'
c = open('app/main.py').read()

# Insert the endpoint near the other GET endpoints (after /api/techniques is safe).
marker = '@app.get("/api/techniques")'

endpoint = '''@app.get("/api/constellation")
async def constellation(email: str):
    """Build the member's knowledge graph from their scan history.
    Nodes = entities/topics. Edges = co-occurrence (same scan) + technique-similarity.
    Returns {ready, count, nodes, edges} — ready=false if under 10 scans.
    """
    from fastapi import HTTPException
    if not email:
        raise HTTPException(status_code=400, detail="email required")
    try:
        _settings = get_settings()
        from supabase import create_client
        sb = create_client(_settings.supabase_url, _settings.supabase_service_key)
        rows = sb.table("scans").select("id, techniques, entities, toxicity, clarity, created_at") \\
            .eq("user_email", email).order("created_at", desc=True).limit(500).execute()
        scans = rows.data or []
        THRESHOLD = 10
        if len(scans) < THRESHOLD:
            return {"ready": False, "count": len(scans), "needed": THRESHOLD, "nodes": [], "edges": []}

        import math
        from collections import defaultdict

        # ── Build nodes from entities ──
        # node key = lowercased name; aggregate frequency, type, avg toxicity/clarity,
        # and the set of techniques seen alongside it (for technique-similarity edges).
        node_data = {}  # key -> {name, type, freq, tox_sum, clar_sum, clar_n, tech: Counter, scans: set}
        STOP = {"ever", "dumbest", "president", "the", "a", "an", "this", "that", "it", "is", "was"}

        for s in scans:
            ents = s.get("entities") or []
            techs = [t.get("name") for t in (s.get("techniques") or []) if t.get("name")]
            tox = s.get("toxicity") or 0.0
            clar = s.get("clarity")
            sid = s.get("id")
            for e in ents:
                name = (e.get("name") or "").strip()
                if not name or name.lower() in STOP or len(name) < 2:
                    continue
                key = name.lower()
                if key not in node_data:
                    node_data[key] = {"name": name, "type": e.get("type", "topic"),
                                      "freq": 0, "tox_sum": 0.0, "clar_sum": 0.0, "clar_n": 0,
                                      "tech": defaultdict(int), "scans": set()}
                nd = node_data[key]
                nd["freq"] += 1
                nd["tox_sum"] += tox
                if clar is not None:
                    nd["clar_sum"] += clar; nd["clar_n"] += 1
                for t in techs:
                    nd["tech"][t] += 1
                nd["scans"].add(sid)

        # Drop singletons only if we have plenty of nodes (keep graph populated)
        nodes_list = list(node_data.items())
        if len(nodes_list) > 40:
            nodes_list = [(k, v) for k, v in nodes_list if v["freq"] >= 2]

        # Final nodes
        nodes = []
        keyidx = {}
        for i, (key, nd) in enumerate(nodes_list):
            keyidx[key] = key  # use key as id
            avg_tox = nd["tox_sum"] / max(nd["freq"], 1)
            avg_clar = (nd["clar_sum"] / nd["clar_n"]) if nd["clar_n"] else None
            nodes.append({
                "id": key,
                "name": nd["name"],
                "type": nd["type"],
                "freq": nd["freq"],
                "toxicity": round(avg_tox, 3),
                "clarity": round(avg_clar, 3) if avg_clar is not None else None,
            })

        valid_keys = set(keyidx.keys())

        # ── Co-occurrence edges: entities appearing in the same scan ──
        co_counts = defaultdict(int)
        scan_to_ents = defaultdict(list)
        for s in scans:
            sid = s.get("id")
            for e in (s.get("entities") or []):
                k = (e.get("name") or "").strip().lower()
                if k in valid_keys:
                    scan_to_ents[sid].append(k)
        for sid, ks in scan_to_ents.items():
            uniq = sorted(set(ks))
            for i in range(len(uniq)):
                for j in range(i+1, len(uniq)):
                    co_counts[(uniq[i], uniq[j])] += 1

        # ── Technique-similarity edges: nodes with similar technique fingerprints ──
        # Build a technique vector per node, cosine similarity, connect if > threshold.
        all_techs = sorted({t for _, nd in nodes_list for t in nd["tech"]})
        tindex = {t: i for i, t in enumerate(all_techs)}
        def vec(nd):
            v = [0.0] * len(all_techs)
            for t, ct in nd["tech"].items():
                v[tindex[t]] = ct
            return v
        def cosine(a, b):
            dot = sum(x*y for x, y in zip(a, b))
            na = math.sqrt(sum(x*x for x in a)); nb = math.sqrt(sum(y*y for y in b))
            return dot / (na*nb) if na and nb else 0.0

        node_vecs = {key: vec(nd) for key, nd in nodes_list}
        tech_edges = []
        keys = list(node_vecs.keys())
        SIM_THRESHOLD = 0.5
        for i in range(len(keys)):
            for j in range(i+1, len(keys)):
                if not any(node_vecs[keys[i]]) or not any(node_vecs[keys[j]]):
                    continue
                sim = cosine(node_vecs[keys[i]], node_vecs[keys[j]])
                if sim >= SIM_THRESHOLD:
                    tech_edges.append((keys[i], keys[j], round(sim, 2)))

        # ── Assemble edges (dedup; co-occurrence and technique can both exist) ──
        edges = []
        for (a, b), ct in co_counts.items():
            edges.append({"source": a, "target": b, "type": "co", "weight": ct})
        for (a, b, sim) in tech_edges:
            edges.append({"source": a, "target": b, "type": "tech", "weight": sim})

        return {
            "ready": True,
            "count": len(scans),
            "nodes": nodes,
            "edges": edges,
            "stats": {"nodes": len(nodes), "co_edges": len(co_counts), "tech_edges": len(tech_edges)},
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[constellation] failed: {e}")
        from fastapi import HTTPException
        raise HTTPException(status_code=500, detail=f"Constellation build failed: {e}")

'''

if '/api/constellation' not in c:
    c = c.replace(marker, endpoint + marker)
    print("✅ /api/constellation endpoint added")
else:
    print("⚠️ endpoint already exists")

open('app/main.py','w').write(c)
PYEOF

python3 -c "import ast; ast.parse(open('app/main.py').read()); print('✅ main.py parses')"
grep -n "/api/constellation\|def constellation" app/main.py | head

echo ""
echo "Commit + push:"
echo "  git add app/main.py && git commit -m 'feat: constellation P3 graph endpoint' && git push"
