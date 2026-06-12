#!/bin/bash
# Dissekt — Global Rename: Optics Theme
# Renames all UI-visible names across frontend + backend
# Backend module directories stay the same (safe), display names change
set -e

cd /mnt/d/Startup\ Ideas/Dissekt/dissekt-web

echo "================================"
echo "Phase 1: Rename frontend component files"
echo "================================"

# Rename component files
[ -f src/components/ReadingMode.tsx ] && mv src/components/ReadingMode.tsx src/components/Loupe.tsx && echo "  ReadingMode → Loupe"
[ -f src/components/PrePublishCheck.tsx ] && mv src/components/PrePublishCheck.tsx src/components/Polish.tsx && echo "  PrePublishCheck → Polish"
[ -f src/components/SourceMatrix.tsx ] && mv src/components/SourceMatrix.tsx src/components/Kaleidoscope.tsx && echo "  SourceMatrix → Kaleidoscope"
[ -f src/components/NarrativeArc.tsx ] && mv src/components/NarrativeArc.tsx src/components/Arc.tsx && echo "  NarrativeArc → Arc"
[ -f src/components/BiasProfile.tsx ] && mv src/components/BiasProfile.tsx src/components/Reflect.tsx && echo "  BiasProfile → Reflect"
[ -f src/components/DecisionJournal.tsx ] && mv src/components/DecisionJournal.tsx src/components/Ledger.tsx && echo "  DecisionJournal → Ledger"
[ -f src/components/ReaderMemory.tsx ] && mv src/components/ReaderMemory.tsx src/components/Recall.tsx && echo "  ReaderMemory → Recall"
[ -f src/components/Annotations.tsx ] && mv src/components/Annotations.tsx src/components/Marginalia.tsx && echo "  Annotations → Marginalia"
[ -f src/components/TrustNetwork.tsx ] && mv src/components/TrustNetwork.tsx src/components/Chorus.tsx && echo "  TrustNetwork → Chorus"
[ -f src/components/RadarFeed.tsx ] && mv src/components/RadarFeed.tsx src/components/Scope.tsx && echo "  RadarFeed → Scope"
[ -f src/components/CounterfactualCard.tsx ] && mv src/components/CounterfactualCard.tsx src/components/Mirror.tsx && echo "  CounterfactualCard → Mirror"
[ -f src/components/ThreatScore.tsx ] && mv src/components/ThreatScore.tsx src/components/ClarityScore.tsx && echo "  ThreatScore → ClarityScore"
[ -f src/components/SignalCard.tsx ] && mv src/components/SignalCard.tsx src/components/SpectrumCard.tsx && echo "  SignalCard → SpectrumCard"
[ -f src/components/TraceCard.tsx ] && mv src/components/TraceCard.tsx src/components/LensCard.tsx && echo "  TraceCard → LensCard"
[ -f src/components/CompassCard.tsx ] && mv src/components/CompassCard.tsx src/components/MeridianCard.tsx && echo "  CompassCard → MeridianCard"
[ -f src/components/PulseCard.tsx ] && mv src/components/PulseCard.tsx src/components/FlareCard.tsx && echo "  PulseCard → FlareCard"
[ -f src/components/ExtractedClaims.tsx ] && mv src/components/ExtractedClaims.tsx src/components/FacetCard.tsx && echo "  ExtractedClaims → FacetCard"
[ -f src/components/SimilarClaims.tsx ] && mv src/components/SimilarClaims.tsx src/components/LatticeCard.tsx && echo "  SimilarClaims → LatticeCard"

echo ""
echo "================================"
echo "Phase 2: Rename page routes"
echo "================================"

[ -d src/app/topics ] && mv src/app/topics src/app/observatory && echo "  /topics → /observatory"
[ -d src/app/fingerprint ] && mv src/app/fingerprint src/app/imprint && echo "  /fingerprint → /imprint"
[ -d src/app/lifecycle ] && mv src/app/lifecycle src/app/thread && echo "  /lifecycle → /thread"
[ -d src/app/bookmarklet ] && mv src/app/bookmarklet src/app/aperture && echo "  /bookmarklet → /aperture"
[ -d src/app/badge ] && mv src/app/badge src/app/seal && echo "  /badge → /seal"

echo ""
echo "================================"
echo "Phase 3: Update all imports + references"
echo "================================"

python3 << 'PYEOF'
import glob, re

# Import path renames (component files)
import_renames = {
    # Component imports
    "'./ReadingMode'": "'./Loupe'",
    "'./PrePublishCheck'": "'./Polish'",
    "'./SourceMatrix'": "'./Kaleidoscope'",
    "'./NarrativeArc'": "'./Arc'",
    "'./BiasProfile'": "'./Reflect'",
    "'./DecisionJournal'": "'./Ledger'",
    "'./ReaderMemory'": "'./Recall'",
    "'./Annotations'": "'./Marginalia'",
    "'./TrustNetwork'": "'./Chorus'",
    "'./RadarFeed'": "'./Scope'",
    "'./CounterfactualCard'": "'./Mirror'",
    "'./ThreatScore'": "'./ClarityScore'",
    "'./SignalCard'": "'./SpectrumCard'",
    "'./TraceCard'": "'./LensCard'",
    "'./CompassCard'": "'./MeridianCard'",
    "'./PulseCard'": "'./FlareCard'",
    "'./ExtractedClaims'": "'./FacetCard'",
    "'./SimilarClaims'": "'./LatticeCard'",
    # @ imports
    "'@/components/ReadingMode'": "'@/components/Loupe'",
    "'@/components/PrePublishCheck'": "'@/components/Polish'",
    "'@/components/SourceMatrix'": "'@/components/Kaleidoscope'",
    "'@/components/NarrativeArc'": "'@/components/Arc'",
    "'@/components/BiasProfile'": "'@/components/Reflect'",
    "'@/components/DecisionJournal'": "'@/components/Ledger'",
    "'@/components/ReaderMemory'": "'@/components/Recall'",
    "'@/components/Annotations'": "'@/components/Marginalia'",
    "'@/components/TrustNetwork'": "'@/components/Chorus'",
    "'@/components/RadarFeed'": "'@/components/Scope'",
    "'@/components/CounterfactualCard'": "'@/components/Mirror'",
    "'@/components/ThreatScore'": "'@/components/ClarityScore'",
    "'@/components/SignalCard'": "'@/components/SpectrumCard'",
    "'@/components/TraceCard'": "'@/components/LensCard'",
    "'@/components/CompassCard'": "'@/components/MeridianCard'",
    "'@/components/PulseCard'": "'@/components/FlareCard'",
    "'@/components/ExtractedClaims'": "'@/components/FacetCard'",
    "'@/components/SimilarClaims'": "'@/components/LatticeCard'",
}

# Component name renames (JSX tags + function names)
component_renames = {
    'ReadingMode': 'Loupe',
    'PrePublishCheck': 'Polish',
    'SourceMatrix': 'Kaleidoscope',
    'NarrativeArc': 'Arc',
    'BiasProfile': 'Reflect',
    'DecisionJournalView': 'LedgerView',
    'DecisionButtons': 'LedgerButtons',
    'DecisionJournal': 'Ledger',
    'ReaderMemory': 'Recall',
    'Annotations': 'Marginalia',
    'TrustNetwork': 'Chorus',
    'RadarFeed': 'Scope',
    'CounterfactualCard': 'Mirror',
    'ThreatScore': 'ClarityScore',
    'SignalCard': 'SpectrumCard',
    'TraceCard': 'LensCard',
    'CompassCard': 'MeridianCard',
    'PulseCard': 'FlareCard',
    'ExtractedClaims': 'FacetCard',
    'SimilarClaims': 'LatticeCard',
}

# UI display text renames
display_renames = {
    # Engine display names
    'Trace — cross-references': 'Lens — cross-references',
    'Trace — fact': 'Lens — fact',
    'Signal — evidence': 'Spectrum — evidence',
    'Signal — credibility': 'Spectrum — credibility',
    'Anchor — blockchain': 'Crystal — blockchain',
    'Compass — political': 'Meridian — political',
    'Pulse — coordination': 'Flare — coordination',
    'Counterfactual — alternative': 'Mirror — alternative',
    # Feature display names
    'Transparency Score': 'Clarity Score',
    'transparency_score': 'clarity_score',
    'transparencyScore': 'clarityScore',
    'Reading mode': 'Loupe',
    'Pre-publish check': 'Polish',
    'Source comparison matrix': 'Kaleidoscope',
    'Narrative arc': 'Arc',
    'Technique fingerprinting': 'Imprint',
    'Claim lifecycle': 'Thread',
    'Trust network': 'Chorus',
    'bias profile': 'Reflect',
    'Your bias profile': 'Reflect',
    'Decision Journal': 'Ledger',
    'Decision journal': 'Ledger',
    'Reader Memory': 'Recall',
    'Reader memory': 'Recall',
    'Community notes': 'Marginalia',
    'Community signal': 'Chorus',
    'Radar feeds': 'Scope feeds',
    'Radar': 'Scope',
    # Page/route renames
    "'/topics'": "'/observatory'",
    '"/topics"': '"/observatory"',
    "'/fingerprint'": "'/imprint'",
    '"/fingerprint"': '"/imprint"',
    "'/lifecycle'": "'/thread'",
    '"/lifecycle"': '"/thread"',
    "'/bookmarklet'": "'/aperture'",
    '"/bookmarklet"': '"/aperture"',
    "'/badge'": "'/seal'",
    '"/badge"': '"/seal"',
    'href="/topics"': 'href="/observatory"',
    'href="/fingerprint"': 'href="/imprint"',
    'href="/lifecycle"': 'href="/thread"',
    'href="/bookmarklet"': 'href="/aperture"',
    'href="/badge"': 'href="/seal"',
    "href='/topics'": "href='/observatory'",
    # Navigation labels
    "'Topics'": "'Observatory'",
    'label: \'Topics\'': 'label: \'Observatory\'',
    '>Topics<': '>Observatory<',
    # Admin settings feature labels
    'Radar feeds': 'Scope feeds',
    'Decision journal': 'Ledger',
    'Reader memory': 'Recall',
    'Compass (political)': 'Meridian (political)',
    'Pulse (coordination)': 'Flare (coordination)',
    'Counterfactual view': 'Mirror view',
    'Claim extraction': 'Facet extraction',
}

files = glob.glob('src/**/*.tsx', recursive=True) + glob.glob('src/**/*.ts', recursive=True)
total_changes = 0

for filepath in files:
    try:
        content = open(filepath).read()
        original = content
        
        # Apply import renames first (most specific)
        for old, new in import_renames.items():
            content = content.replace(old, new)
        
        # Apply component name renames
        for old, new in component_renames.items():
            # Only replace whole words to avoid partial matches
            content = re.sub(rf'\b{old}\b', new, content)
        
        # Apply display text renames
        for old, new in display_renames.items():
            content = content.replace(old, new)
        
        if content != original:
            open(filepath, 'w').write(content)
            total_changes += 1
    except Exception as e:
        print(f'  ⚠️ {filepath}: {e}')

print(f'✅ Updated {total_changes} frontend files')
PYEOF

echo ""
echo "================================"
echo "Phase 4: Update backend display names"
echo "================================"

cd /mnt/d/Startup\ Ideas/Dissekt

python3 << 'PYEOF'
import glob

# Backend display name changes (shown in API responses + Telegram)
display_renames = {
    'Transparency Score': 'Clarity Score',
    'transparency_score': 'clarity_score',
    'DISSEKT — INFORMATION TRANSPARENCY': 'DISSEKT — CLARITY REPORT',
    'Radar feeds': 'Scope feeds',
    'Decision Journal': 'Ledger',
    'Reader Memory': 'Recall',
    'Community notes': 'Marginalia',
    'Community signal': 'Chorus',
}

files = glob.glob('app/**/*.py', recursive=True)
total = 0

for filepath in files:
    try:
        content = open(filepath).read()
        original = content
        for old, new in display_renames.items():
            content = content.replace(old, new)
        if content != original:
            open(filepath, 'w').write(content)
            total += 1
    except: pass

print(f'✅ Updated {total} backend files')
PYEOF

echo ""
echo "================================"
echo "Phase 5: Update SiteHeader nav"
echo "================================"

cd /mnt/d/Startup\ Ideas/Dissekt/dissekt-web

python3 << 'PYEOF'
content = open('src/components/SiteHeader.tsx').read()

content = content.replace(
    "{ href: '/topics', label: 'Topics' }",
    "{ href: '/observatory', label: 'Observatory' }"
)
# Fix any that already got renamed by the global pass
content = content.replace(
    "{ href: '/observatory', label: 'Observatory' }",
    "{ href: '/observatory', label: 'Observatory' }"
)

open('src/components/SiteHeader.tsx', 'w').write(content)
print('✅ SiteHeader: Topics → Observatory')
PYEOF

echo ""
echo "================================"
echo "Phase 6: Update SiteFooter links"
echo "================================"

python3 << 'PYEOF'
content = open('src/components/SiteFooter.tsx').read()

renames = {
    '>Topics<': '>Observatory<',
    '>Bookmarklet<': '>Aperture<',
    '>Embed badge<': '>Seal<',
    '>Fingerprint<': '>Imprint<',
    '>Claim lifecycle<': '>Thread<',
}

for old, new in renames.items():
    content = content.replace(old, new)

open('src/components/SiteFooter.tsx', 'w').write(content)
print('✅ SiteFooter: all links renamed')
PYEOF

echo ""
echo "================================"
echo "Phase 7: Update landing page engine names"
echo "================================"

python3 << 'PYEOF'
content = open('src/components/LandingPage.tsx').read()

renames = {
    "name: 'Trace'": "name: 'Lens'",
    "name: 'Signal'": "name: 'Spectrum'",
    "name: 'Compass'": "name: 'Meridian'",
    "name: 'Radar'": "name: 'Scope'",
    "name: 'Claim Graph'": "name: 'Lattice'",
    "name: 'Counterfactual'": "name: 'Mirror'",
    "name: 'Pulse'": "name: 'Flare'",
    "name: 'Claims'": "name: 'Facet'",
    "name: 'Anchor'": "name: 'Crystal'",
    "'Cross-references": "'Focuses on cross-references",
    "Trace finds cross-references": "Lens finds cross-references",
    "Signal scores evidence": "Spectrum scores evidence",
    "Compass checks political": "Meridian checks political",
}

for old, new in renames.items():
    content = content.replace(old, new)

open('src/components/LandingPage.tsx', 'w').write(content)
print('✅ Landing page: engine names updated')
PYEOF

echo ""
echo "================================"
echo "Phase 8: Update admin settings labels"
echo "================================"

python3 << 'PYEOF'
content = open('src/app/admin/page.tsx').read()

renames = {
    "'Radar'": "'Scope'",
    "'Radar feeds'": "'Scope feeds'",
    "'Reader memory'": "'Recall'",
    "'Decision journal'": "'Ledger'",
    "'Compass (political)'": "'Meridian (political)'",
    "'Pulse (coordination)'": "'Flare (coordination)'",
    "'Counterfactual view'": "'Mirror view'",
    "'Claim extraction'": "'Facet extraction'",
    "radar_enabled": "scope_enabled",
    "Radar feeds enabled": "Scope feeds enabled",
}

for old, new in renames.items():
    content = content.replace(old, new)

open('src/app/admin/page.tsx', 'w').write(content)
print('✅ Admin page: settings labels updated')
PYEOF

echo ""
echo "================================"
echo "Phase 9: Verify no broken imports"
echo "================================"

python3 << 'PYEOF'
import glob, re

broken = []
for filepath in glob.glob('src/**/*.tsx', recursive=True):
    content = open(filepath).read()
    imports = re.findall(r"from '(@/components/\w+)'", content)
    for imp in imports:
        comp_name = imp.split('/')[-1]
        comp_path = f"src/components/{comp_name}.tsx"
        if not __import__('os').path.exists(comp_path):
            broken.append(f"  {filepath}: imports {imp} but {comp_path} doesn't exist")

if broken:
    print(f'⚠️ {len(broken)} potentially broken imports:')
    for b in broken:
        print(b)
else:
    print('✅ All imports verified')
PYEOF

echo ""
echo "================================"
echo "✅ RENAME COMPLETE"
echo "================================"
echo ""
echo "  Engines: Prism, Lens, Spectrum, Crystal, Lattice, Scope, Facet, Iris, Meridian, Flare, Mirror"
echo "  Features: Clarity Score, Loupe, Polish, Kaleidoscope, Arc, Imprint, Thread, Chorus, Reflect, Ledger, Recall, Marginalia, Seal, Aperture, Dispatch"  
echo "  Pages: /observatory, /imprint, /thread, /aperture, /seal"
echo ""
echo "npm run build"
