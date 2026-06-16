#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt  (PROJECT ROOT)
set -e

echo "═══ BACKEND ═══"

# ── 1. Add image field to ScanRequest ──
python3 << 'PYEOF'
content = open('app/models.py').read()
if 'image' not in content.split('class ScanRequest')[1][:400]:
    content = content.replace(
        '''    content: str = Field(..., min_length=1, max_length=50000, description="URL or text to analyze")
    mode: AnalysisMode = Field(default=AnalysisMode.brief, description="brief or detailed")''',
        '''    content: str = Field(default="", max_length=50000, description="URL or text to analyze")
    mode: AnalysisMode = Field(default=AnalysisMode.brief, description="brief or detailed")
    image: str | None = Field(default=None, description="Base64 data-URL of an image to analyze via vision")'''
    )
    open('app/models.py', 'w').write(content)
    print('✅ ScanRequest: added image field, content now optional')
else:
    print('  image field already present')
PYEOF

# ── 2. Add vision extraction helper + wire into scan() ──
python3 << 'PYEOF'
content = open('app/beacon/__init__.py').read()

# Add a vision helper near the top (after imports). Insert before "async def scan"
if 'async def _extract_from_image' not in content:
    helper = '''
async def _extract_from_image(image_data_url: str) -> str:
    """Use GPT-4o-mini vision to extract text + describe manipulation signals from an image."""
    try:
        from openai import AsyncOpenAI
        from app.config import get_settings
        s = get_settings()
        client = AsyncOpenAI(api_key=s.openai_api_key)
        resp = await client.chat.completions.create(
            model="gpt-4o-mini",
            max_tokens=1000,
            messages=[{
                "role": "user",
                "content": [
                    {"type": "text", "text": (
                        "Extract ALL text visible in this image verbatim (headlines, body, captions, overlaid text). "
                        "Then on a new line after '---VISUAL---', briefly note any visual manipulation signals "
                        "(misleading charts, emotional imagery, out-of-context or doctored photos, missing context). "
                        "If there is no text, transcribe what the image depicts."
                    )},
                    {"type": "image_url", "image_url": {"url": image_data_url}},
                ],
            }],
        )
        return resp.choices[0].message.content or ""
    except Exception as e:
        logger.warning(f"Image vision extraction failed: {e}")
        return ""

'''
    content = content.replace('async def scan(', helper + 'async def scan(', 1)
    print('✅ Added _extract_from_image vision helper')

# Change scan() signature to accept image
content = content.replace(
    'async def scan(content: str, mode: str = "brief") -> FullAnalysis:',
    'async def scan(content: str, mode: str = "brief", image: str | None = None) -> FullAnalysis:'
)

# At the start of scan(), if an image is provided, extract text and merge into content
# Find the first line inside scan() body (after the docstring) to inject
import re
# Inject right after the scan() def + its docstring
m = re.search(r'(async def scan\(content: str, mode: str = "brief", image: str \| None = None\) -> FullAnalysis:\n(?:    """.*?"""\n)?)', content, flags=re.DOTALL)
if m and '_extract_from_image(image)' not in content:
    inject = m.group(1) + '''    # Vision: if an image was supplied, extract its text/signals and prepend to content
    if image:
        _vision_text = await _extract_from_image(image)
        if _vision_text:
            content = (_vision_text + "\\n\\n" + (content or "")).strip()
        elif not content:
            content = "[Image provided but no text could be extracted]"
'''
    content = content[:m.start()] + inject + content[m.end():]
    print('✅ scan() now extracts image text via vision')

open('app/beacon/__init__.py', 'w').write(content)
PYEOF

# ── 3. Pass image from the API endpoint into scan() ──
python3 << 'PYEOF'
content = open('app/main.py').read()
# The /api/scan handler calls scan(...). Make it pass request.image.
import re
# Find scan( call inside scan_content handler
if 'image=request.image' not in content:
    content = re.sub(
        r'await scan\(\s*content=([^,)]+),\s*mode=([^,)]+)\s*\)',
        r'await scan(content=\1, mode=\2, image=request.image)',
        content,
        count=1
    )
    open('app/main.py', 'w').write(content)
    print('✅ /api/scan passes image to scan()')
else:
    print('  already passing image')
PYEOF

# Verify backend parses
for f in app/models.py app/beacon/__init__.py app/main.py; do
  python3 -c "import ast; ast.parse(open('$f').read())" && echo "✅ $f" || echo "❌ $f"
done

echo ""
echo "═══ FRONTEND ═══"
echo "Run the frontend fixer next (separate, in dissekt-web)."
