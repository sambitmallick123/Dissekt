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
