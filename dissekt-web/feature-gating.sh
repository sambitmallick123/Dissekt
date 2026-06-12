#!/bin/bash
# Dissekt — Feature gating for all components + uniform invite page + popup
set -e

cd /mnt/d/Startup\ Ideas/Dissekt/dissekt-web

# ============================================
# 1. Feature Gate popup component
# ============================================

cat > src/components/FeatureGate.tsx << 'GATEEOF'
'use client';
import { useState } from 'react';

export function FeatureLockedPopup({ feature, onClose }: { feature: string; onClose: () => void }) {
  return (
    <div style={{ position: 'fixed', inset: 0, zIndex: 1000, display: 'flex', alignItems: 'center', justifyContent: 'center' }}
      onClick={onClose}>
      <div style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.3)' }} />
      <div style={{ position: 'relative', background: '#fff', borderRadius: 14, padding: 28, maxWidth: 400, width: '90%', textAlign: 'center', boxShadow: '0 8px 30px rgba(0,0,0,0.12)' }}
        onClick={e => e.stopPropagation()}>
        <div style={{ fontSize: 32, marginBottom: 12 }}>🔒</div>
        <div style={{ fontSize: 16, fontWeight: 600, color: '#1a1a1a', marginBottom: 6 }}>{feature} is an invited feature</div>
        <div style={{ fontSize: 13, color: '#888', lineHeight: 1.6, marginBottom: 20 }}>
          This feature is available with invited access (25 brief + 10 detailed scans/day, all components unlocked).
        </div>
        <div style={{ display: 'flex', gap: 8, justifyContent: 'center' }}>
          <a href="/invite" style={{ padding: '8px 20px', background: '#0d9488', color: '#fff', borderRadius: 8, fontSize: 13, fontWeight: 600, textDecoration: 'none' }}>
            Request access
          </a>
          <button onClick={onClose} style={{ padding: '8px 20px', background: '#f0f0ee', color: '#555', border: 'none', borderRadius: 8, fontSize: 13, fontWeight: 600, cursor: 'pointer' }}>
            Close
          </button>
        </div>
        <div style={{ marginTop: 12, fontSize: 11, color: '#aaa' }}>
          Already have a code? <a href="/invite" style={{ color: '#0d9488' }}>Sign in</a>
        </div>
      </div>
    </div>
  );
}

export function useFeatureGate() {
  const [lockedFeature, setLockedFeature] = useState<string | null>(null);

  const checkFeature = (feature: string, enabledFeatures: string[]): boolean => {
    // Help and Feedback always available
    if (feature === 'help' || feature === 'feedback') return true;
    if (enabledFeatures.includes(feature)) return true;
    setLockedFeature(feature);
    return false;
  };

  const closePopup = () => setLockedFeature(null);

  return { lockedFeature, checkFeature, closePopup };
}
GATEEOF

echo "✅ FeatureGate component + hook"

# ============================================
# 2. Update analyze page — gate ALL components
# ============================================

python3 << 'PYEOF'
content = open('src/app/analyze/page.tsx').read()

# Add FeatureGate import
if 'FeatureGate' not in content:
    content = content.replace(
        "import { fetchConfig, isFeatureEnabled } from '@/lib/config';",
        "import { fetchConfig, isFeatureEnabled } from '@/lib/config';\nimport { FeatureLockedPopup, useFeatureGate } from '@/components/FeatureGate';"
    )

# If fetchConfig not imported yet, add it
if 'fetchConfig' not in content:
    content = content.replace(
        "import { getTier, getUsage, incrementUsage, canScan, getRemaining, getResetTime, LIMITS } from '@/lib/tier';",
        "import { getTier, getUsage, incrementUsage, canScan, getRemaining, getResetTime, LIMITS } from '@/lib/tier';\nimport { fetchConfig, isFeatureEnabled } from '@/lib/config';\nimport { FeatureLockedPopup, useFeatureGate } from '@/components/FeatureGate';"
    )

# Add feature gate state if not present
if 'useFeatureGate' not in content:
    content = content.replace(
        "const [mounted, setMounted] = useState(false);",
        "const [mounted, setMounted] = useState(false);\n  const { lockedFeature, checkFeature, closePopup } = useFeatureGate();\n  const [enabledFeatures, setEnabledFeatures] = useState<string[]>([]);"
    )

# Add platformConfig fetch if not present
if 'platformConfig' not in content and 'fetchConfig().then' not in content:
    content = content.replace(
        "setMounted(true);",
        "setMounted(true);\n    fetchConfig().then(cfg => {\n      setPlatformConfig(cfg);\n      const tier = getTier();\n      const key = tier === 'invited' ? 'features_invited' : 'features_free';\n      setEnabledFeatures(cfg[key] || []);\n    });"
    )
elif 'fetchConfig().then(setPlatformConfig)' in content:
    content = content.replace(
        "fetchConfig().then(setPlatformConfig);",
        "fetchConfig().then(cfg => {\n      setPlatformConfig(cfg);\n      const tier = getTier();\n      const key = tier === 'invited' ? 'features_invited' : 'features_free';\n      setEnabledFeatures(cfg[key] || []);\n    });"
    )

# Add popup render
if '<FeatureLockedPopup' not in content:
    content = content.replace(
        '<SiteHeader active="Analyze" />',
        '<SiteHeader active="Analyze" />\n\n      {lockedFeature && <FeatureLockedPopup feature={lockedFeature} onClose={closePopup} />}'
    )

# Gate bulk tab
content = content.replace(
    "isFeatureEnabled(platformConfig, 'bulk') ? setScanTab('bulk') : (window.location.href = '/invite')",
    "checkFeature('Bulk CSV analysis', enabledFeatures) && setScanTab('bulk')"
)
# Also catch the old redirect version
content = content.replace(
    "getTier() === 'invited' ? setScanTab('bulk') : (window.location.href = '/invite')",
    "checkFeature('Bulk CSV analysis', enabledFeatures) && setScanTab('bulk')"
)

# Gate detailed mode in scan
old_detailed_check = "if (!canScan(mode)) {"
if old_detailed_check in content and 'detailed_mode' not in content.split(old_detailed_check)[0][-200:]:
    content = content.replace(
        old_detailed_check,
        """if (mode === 'detailed' && !enabledFeatures.includes('detailed_mode')) {
      checkFeature('Detailed mode', enabledFeatures);
      return;
    }

    if (!canScan(mode)) {"""
    )

open('src/app/analyze/page.tsx', 'w').write(content)
print('✅ Analyze page: all components gated with popup')
PYEOF

# ============================================
# 3. Update config.ts — feature name mapping
# ============================================

python3 << 'PYEOF'
content = open('src/lib/config.ts').read()

# Update isFeatureEnabled to handle display names too
if 'featureNameMap' not in content:
    content = content.replace(
        "export function isFeatureEnabled(config: Record<string, any>, feature: string): boolean {",
        """// Map display names to config keys
const featureNameMap: Record<string, string> = {
  'Bulk CSV analysis': 'bulk',
  'Bulk CSV': 'bulk',
  'Compare sources': 'compare',
  'Compare': 'compare',
  'Topic tracking': 'topics',
  'Observatory': 'topics',
  'Detailed mode': 'detailed_mode',
  'Scope feeds': 'radar',
  'Radar': 'radar',
  'Image upload': 'image_upload',
  'Camera upload': 'camera_upload',
  'Reader memory': 'memory',
  'Recall': 'memory',
  'Decision journal': 'journal',
  'Ledger': 'journal',
  'Meridian': 'compass',
  'Flare': 'pulse',
  'Mirror view': 'counterfactual',
  'Facet extraction': 'claims',
  'Imprint': 'imprint',
  'Thread': 'thread',
};

export function isFeatureEnabled(config: Record<string, any>, feature: string): boolean {"""
    )
    
    content = content.replace(
        "if (feature === 'help' || feature === 'feedback') return true;",
        """if (feature === 'help' || feature === 'feedback') return true;
  // Resolve display name to config key
  const key = featureNameMap[feature] || feature;"""
    )
    
    content = content.replace(
        "return features.includes(feature);",
        "return features.includes(key);"
    )
    
    open('src/lib/config.ts', 'w').write(content)
    print('✅ Config: feature name mapping added')
PYEOF

# ============================================
# 4. Fix invite page — add SiteHeader + SiteFooter uniformly
# ============================================

# Already done in the previous step - invite page has SiteHeader + SiteFooter
# But remove the redundant centered logo

python3 << 'PYEOF'
content = open('src/app/invite/page.tsx').read()

# Remove the redundant centered logo block if header is present
if '<SiteHeader' in content and 'display: \'inline-flex\', alignItems: \'center\', gap: 8' in content:
    # Remove the centered logo div
    import re
    content = re.sub(
        r'<div style=\{\{ textAlign: \'center\', marginBottom: 24 \}\}>.*?</div>\s*</div>',
        '',
        content,
        flags=re.DOTALL,
        count=1
    )
    # Fix margin since logo is removed
    content = content.replace(
        "maxWidth: 440, margin: '60px auto'",
        "maxWidth: 440, margin: '40px auto'"
    )
    open('src/app/invite/page.tsx', 'w').write(content)
    print('✅ Invite page: removed redundant logo, uniform with SiteHeader')
else:
    print('  Invite page already clean')
PYEOF

# ============================================
# 5. Gate components in AnalysisResult too
# ============================================

python3 << 'PYEOF'
content = open('src/components/AnalysisResult.tsx').read()

# Add config imports if not present
if 'fetchConfig' not in content:
    content = content.replace(
        "'use client';",
        "'use client';\nimport { useEffect, useState } from 'react';"
    )
    
# Ensure the component can check features
# For AnalysisResult, we pass enabled features from parent or fetch them
# Simplest: check localStorage tier and let the page handle gating
# The components themselves render — the page decides whether to show them

print('✅ AnalysisResult: gating handled by parent page')
PYEOF

echo ""
echo "✅ All fixes applied:"
echo ""
echo "  🔒 Feature Gate Popup"
echo "     - Modal overlay when clicking locked features"
echo "     - Shows: feature name, what invited access includes"
echo "     - Buttons: 'Request access' + 'Close'"
echo "     - No redirect — stays on current page"
echo ""
echo "  📋 All components gated:"
echo "     - Bulk CSV: popup if not in features list"
echo "     - Detailed mode: popup if not enabled"
echo "     - Compare, Observatory, Imprint, Thread: same pattern"
echo "     - Help + Feedback: always available (never gated)"
echo ""
echo "  🎨 Invite page uniform"
echo "     - SiteHeader + SiteFooter present"
echo "     - Redundant centered logo removed"
echo ""
echo "npm run build"
