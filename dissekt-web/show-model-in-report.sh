#!/bin/bash
# Run from: /mnt/d/Startup Ideas/Dissekt/dissekt-web
# Adds an "Analyzed with [model]" badge to the analysis report header row
set -e

python3 << 'PYEOF'
content = open('src/components/AnalysisResult.tsx').read()

if 'model_used' not in content:
    # Add a model badge in the top-left metadata row, next to the language badge
    old = '''          {lang && lang !== 'en' && (
            <span style={{ fontSize: 11, padding: '3px 10px', borderRadius: 6, background: '#dbeafe', color: '#1e40af', fontWeight: 500 }}>
              Detected: {langName}
            </span>
          )}
          <a href="/help" style={{ fontSize: 11, color: '#888', textDecoration: 'none' }}>What do these mean?</a>'''

    new = '''          {lang && lang !== 'en' && (
            <span style={{ fontSize: 11, padding: '3px 10px', borderRadius: 6, background: '#dbeafe', color: '#1e40af', fontWeight: 500 }}>
              Detected: {langName}
            </span>
          )}
          {data.prism?.model_used && data.prism.model_used !== 'error' && (
            <span title="Model used for this analysis" style={{ fontSize: 11, padding: '3px 10px', borderRadius: 6, background: '#f0fdfa', color: '#0d9488', fontWeight: 500, display: 'flex', alignItems: 'center', gap: 4 }}>
              <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="3" width="18" height="18" rx="2"/><path d="M9 9h6v6H9z"/><path d="M9 1v2M15 1v2M9 21v2M15 21v2M1 9h2M1 15h2M21 9h2M21 15h2"/></svg>
              {data.prism.model_used}
            </span>
          )}
          <a href="/help" style={{ fontSize: 11, color: '#888', textDecoration: 'none' }}>What do these mean?</a>'''

    content = content.replace(old, new)
    open('src/components/AnalysisResult.tsx', 'w').write(content)
    print('✅ Added model badge to analysis report header')
else:
    print('  model badge already present')
PYEOF

echo ""
echo "Verify:"
grep -n "model_used" src/components/AnalysisResult.tsx
echo ""
echo "Run: rm -rf .next && npm run build"
