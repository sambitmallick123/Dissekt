import pathlib
W = "dissekt-web/src/"

def cut_block(path, anchor, closer, expect):
    p = pathlib.Path(path); lines = p.read_text().splitlines(keepends=True)
    start = next(i for i, l in enumerate(lines) if anchor in l)
    end = next(i for i, l in enumerate(lines[start:], start) if l.rstrip() == closer)
    assert end - start == expect, f"{path}: span {start+1}..{end+1}, expected {expect}"
    p.write_text("".join(lines[:start] + lines[end + 1:]))
    print(f"cut {path} lines {start+1}-{end+1}")

def sub(path, old, new=""):
    p = pathlib.Path(path); src = p.read_text()
    assert src.count(old) == 1, f"{path}: {src.count(old)} matches for {old[:60]!r}"
    p.write_text(src.replace(old, new)); print(f"ok  {path}")

# ── help page: stale FAQ + citations ──
H = W + "app/help/page.tsx"
sub(H, """    ['What is a "Brief" vs "Detailed" scan?', 'Brief is a fast analysis using a lightweight model — good for quick checks. Detailed runs a deeper model with fuller reasoning and more thorough cross-referencing. Detailed scans count separately against your daily limit.'],\n""")
sub(H, """    ['Why is toxicity usually 0%?', 'Professional news writing rarely triggers toxicity detection, which looks for insults, threats, and obscenity. A low toxicity score is normal for news and does not mean the content is unbiased.'],\n""")
sub(H, """              ['Pavlopoulos et al., ACL 2020', 'Context-aware toxicity', 'https://aclanthology.org/2020.acl-main.396/'],\n""")
sub(H, """              ['Borkan et al., WWW 2019', 'Toxicity sub-labels (Jigsaw/Detoxify)', 'https://arxiv.org/abs/1903.04561'],\n""")
sub(H, "            'Choose Brief (fast) or Detailed (deeper).',\n")
sub(H, "          <Tip>Use Brief for a quick gut-check, Detailed when a piece matters and you want the fuller reasoning and cross-referencing.</Tip>\n")
sub(H, "            'Pick Brief (more articles) or Detailed (deeper, fewer), then Analyze topic.',\n")
sub(H, "          <P>Brief and detailed scans are counted separately. Keyword topic analyses count as one scan of the chosen depth.</P>\n")
sub(H, "          <P><strong>Toxicity sub-types</strong> (shown when detected): Severe toxicity, Obscene language, Threat, Insult, Identity attack, Sexually explicit.</P>\n")

# ── scoring.py citation ──
sub("app/scoring.py",
    "  Pavlopoulos et al., ACL 2020 — context-aware toxicity (Intent/tone)\n"
    "    https://aclanthology.org/2020.acl-main.396/\n")

# ── privacy ──
sub(W + "app/privacy/page.tsx",
    "<p>Toxicity analysis (Detoxify), sentiment analysis (VADER), and source credibility scoring (MBFC) run entirely on our servers.",
    "<p>Sentiment analysis (VADER) and source credibility scoring run entirely on our servers.")
sub(W + "app/privacy/page.tsx",
    "          <p><strong>Ledger:</strong> If you mark content as Trust/Unsure/Reject, this is stored to enable the journal feature.</p>\n")

# ── docs: engine names ──
sub(W + "app/docs/page.tsx",
    "                { icon: '📊', name: 'Signal', desc: 'Toxicity, sentiment, source bias from 231 sources' },\n",
    "                { icon: '📊', name: 'Signal', desc: 'Sentiment and source credibility' },\n")

# ── Ledger / Reflect out of the UI ──
sub(W + "components/AnalysisResult.tsx", "import { LedgerButtons } from './Ledger';\n")
sub(W + "app/dashboard/page.tsx", "import Reflect from '@/components/Reflect';\n")
sub(W + "app/dashboard/page.tsx", "import LedgerView from '@/components/Ledger';\n")
sub(W + "app/dashboard/page.tsx", "            <Reflect />\n")
sub(W + "app/dashboard/page.tsx", "            <LedgerView />\n")

# ── landing: engines, tools, stats ──
L = W + "components/LandingPage.tsx"
cut_block(L, "name: 'Beacon'", "          </div>", 4)
