"""Dissekt Telegram Bot — Analyze claims via Telegram."""
import logging
from app.config import get_settings

logger = logging.getLogger("dissekt.telegram")


def format_result(data: dict) -> str:
    """Format Dissekt analysis for Telegram (HTML)."""
    techs = data.get("prism", {}).get("techniques", [])
    fcs = data.get("trace", {}).get("fact_checks", [])
    tox = data.get("signal", {}).get("toxicity_score", 0)
    brief = data.get("prism", {}).get("brief", "")
    claims = data.get("extracted_claims", [])
    report_id = data.get("id", "")

    max_conf = max((t.get("confidence", 0) for t in techs), default=0)
    score = min(100, (
        (round(max_conf * 40) if techs else 0) +
        min(len(fcs) * 4, 30) +
        round(tox * 20) +
        (10 if len(fcs) >= 3 else 0)
    ))

    emoji = "🔴" if score >= 70 else "🟡" if score >= 40 else "🟢"
    label = "HIGH RISK" if score >= 70 else "MEDIUM RISK" if score >= 40 else "LOW RISK"

    lines = [
        f"🛡 <b>DISSEKT ANALYSIS</b>",
        f"",
        f"{emoji} <b>Threat Score: {score}/100 — {label}</b>",
    ]

    if techs:
        lines.append(f"")
        lines.append(f"👁 <b>Techniques ({len(techs)}):</b>")
        for t in techs[:6]:
            name = t.get("name", "").replace("_", " ").title()
            conf = round(t.get("confidence", 0) * 100)
            lines.append(f"  • {name} — {conf}%")
        if len(techs) > 6:
            lines.append(f"  + {len(techs) - 6} more — see full report")

    if brief:
        lines.append(f"")
        lines.append(f"📝 <i>{brief[:250]}</i>")

    if fcs:
        lines.append(f"")
        lines.append(f"🌐 <b>Fact-checks ({len(fcs)}):</b>")
        for fc in fcs[:8]:
            pub = fc.get("publisher", "")
            rating = fc.get("rating", "")
            lines.append(f"  • {pub}: {rating}")
        if len(fcs) > 8:
            lines.append(f"  + {len(fcs) - 8} more — see full report")

    if claims:
        lines.append(f"")
        lines.append(f"📋 <b>Claims ({len(claims)}):</b>")
        for c in claims[:3]:
            lines.append(f"  • {c.get('claim', '')[:80]}")

    lines.append(f"")
    lines.append(f"📊 Toxicity: {tox*100:.1f}% | Sentiment: {data.get('signal', {}).get('sentiment', 'neutral')}")

    if report_id:
        lines.append(f"")
        lines.append(f'🔗 <a href="https://dissekt.info/report/{report_id}">Full report</a>')

    lines.append(f"")
    lines.append(f"<i>Powered by dissekt.info</i>")

    return "\n".join(lines)


WELCOME_MSG = """🛡 <b>Welcome to Dissekt!</b>

I detect manipulation in any content. Send me:

📝 <b>Text</b> — paste any claim or article text
🔗 <b>URL</b> — send a news article link
📷 <b>Image</b> — send a screenshot of a post

I'll analyze it and show you:
- Manipulation techniques used
- Existing fact-checks
- Source credibility scores
- Verifiable claims extracted

Try it now — paste any suspicious text!

<i>Free | 10 scans/day | dissekt.info</i>"""


HELP_MSG = """🛡 <b>How to use Dissekt Bot</b>

Just send me any of these:

1. <b>Text</b> — paste a claim like:
   <i>"COVID vaccines contain microchips"</i>

2. <b>URL</b> — send an article link:
   <i>https://example.com/article</i>

3. <b>Image</b> — send a screenshot of a WhatsApp forward or social media post

I'll reply with the full analysis in seconds.

<b>Commands:</b>
/start — Welcome message
/help — This message

<i>dissekt.info | See the playbook behind the content</i>"""
