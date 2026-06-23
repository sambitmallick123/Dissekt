'use client';
import { useState } from 'react';

// Detoxify sub-labels we surface (excluding the aggregate 'toxicity')
const TOX_LABELS: Record<string, string> = {
  severe_toxicity: 'Severe toxicity',
  obscene: 'Obscene language',
  threat: 'Threat',
  insult: 'Insult',
  identity_attack: 'Identity attack',
  sexual_explicit: 'Sexually explicit',
};

type Tag = { id: string; label: string; category: string; severity?: string; evidence?: string[]; explanation?: string };

export default function BiasTags({ data }: { data: any }) {
  const [open, setOpen] = useState<string | null>(null);

  const signals: Tag[] = Array.isArray(data?.bias_signals) ? data.bias_signals : [];

  // Build tags from Detoxify sub-labels above threshold
  const tox = data?.signal?.toxicity_labels || {};
  const toxTags: Tag[] = Object.entries(tox)
    .filter(([k, v]: any) => k !== 'toxicity' && typeof v === 'number' && v >= 0.5 && TOX_LABELS[k])
    .map(([k, v]: any) => ({
      id: `tox_${k}`, label: TOX_LABELS[k], category: 'toxicity', severity: 'warn',
      explanation: `Detoxify flagged this signal at ${Math.round(v * 100)}% confidence.`,
    }));

  const all = [...signals, ...toxTags];
  if (all.length === 0) return null;

  const palette = (sev?: string) =>
    sev === 'warn'
      ? { bg: '#fff7ed', border: '#fed7aa', color: '#9a3412' }
      : { bg: '#f1f5f9', border: '#e2e8f0', color: '#475569' };

  return (
    <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: 16, marginTop: 12 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 }}>
        <span style={{ fontSize: 13, fontWeight: 600, color: '#404040' }}>Representation &amp; language signals</span>
        <span style={{ fontSize: 11, color: '#aaa' }}>{all.length} observed</span>
      </div>
      <div style={{ fontSize: 11, color: '#999', marginBottom: 10 }}>
        Descriptive observations about the language — not a verdict. Tap a tag to see what triggered it.
      </div>
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>
        {all.map(t => {
          const p = palette(t.severity);
          const isOpen = open === t.id;
          return (
            <button key={t.id} onClick={() => setOpen(isOpen ? null : t.id)}
              style={{ padding: '4px 11px', borderRadius: 14, fontSize: 11.5, fontWeight: 500, cursor: 'pointer',
                background: p.bg, color: p.color, border: `0.5px solid ${p.border}` }}>
              {t.severity === 'warn' ? '⚠ ' : ''}{t.label}
            </button>
          );
        })}
      </div>
      {open && (() => {
        const t = all.find(x => x.id === open);
        if (!t) return null;
        return (
          <div style={{ marginTop: 10, padding: '10px 12px', background: '#f8fafc', border: '0.5px solid #e2e8f0', borderRadius: 8 }}>
            <div style={{ fontSize: 12, color: '#404040', lineHeight: 1.6 }}>{t.explanation}</div>
            {t.evidence && t.evidence.length > 0 && (
              <div style={{ marginTop: 6, display: 'flex', flexWrap: 'wrap', gap: 4 }}>
                {t.evidence.map((e, i) => (
                  <span key={i} style={{ fontSize: 11, fontFamily: 'monospace', padding: '1px 7px', borderRadius: 4, background: '#fff', border: '0.5px solid #e2e8f0', color: '#555' }}>{e}</span>
                ))}
              </div>
            )}
          </div>
        );
      })()}
    </div>
  );
}
