'use client';
import { useState, useEffect } from 'react';

interface HistoryItem {
  id: string;
  input: string;
  score: number;
  techniques: number;
  mode: string;
  time: string;
}

function getHistory(): HistoryItem[] {
  if (typeof window === 'undefined') return [];
  try {
    return JSON.parse(localStorage.getItem('dissekt_history') || '[]');
  } catch { return []; }
}

export function addToHistory(item: HistoryItem) {
  if (typeof window === 'undefined') return;
  const history = getHistory();
  // Dedupe by id
  const filtered = history.filter(h => h.id !== item.id);
  filtered.unshift(item);
  // Keep last 50
  localStorage.setItem('dissekt_history', JSON.stringify(filtered.slice(0, 50)));
}

export default function ScanHistory({ onReanalyze }: { onReanalyze: (input: string) => void }) {
  const [items, setItems] = useState<HistoryItem[]>([]);
  const [expanded, setExpanded] = useState(false);

  useEffect(() => { setItems(getHistory()); }, []);

  if (items.length === 0) return null;

  const visible = expanded ? items : items.slice(0, 5);
  const scoreColor = (s: number) => s >= 70 ? '#dc2626' : s >= 40 ? '#d97706' : '#16a34a';

  return (
    <div style={{ marginBottom: 20 }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
        <div>
          <div style={{ fontSize: 14, fontWeight: 600, color: '#404040' }}>🕐 Recent scans</div>
          <div style={{ fontSize: 11, color: '#888' }}>{items.length} scans saved locally</div>
        </div>
        {items.length > 5 && (
          <button onClick={() => setExpanded(!expanded)} style={{ fontSize: 11, color: '#7c3aed', background: 'none', border: 'none', cursor: 'pointer', fontWeight: 500 }}>
            {expanded ? 'Show less' : `Show all ${items.length}`}
          </button>
        )}
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
        {visible.map((item, i) => (
          <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '8px 12px', background: '#fff', border: '1px solid #e5e5e5', borderRadius: 8 }}>
            <div style={{ width: 32, height: 32, borderRadius: 8, background: '#f8f8f6', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 13, fontWeight: 700, color: scoreColor(item.score), flexShrink: 0 }}>
              {item.score}
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 12, fontWeight: 500, color: '#1a1a1a', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{item.input}</div>
              <div style={{ fontSize: 10, color: '#aaa' }}>
                {item.techniques} techniques · {item.mode} · {new Date(item.time).toLocaleString(undefined, { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })}
              </div>
            </div>
            <div style={{ display: 'flex', gap: 6, flexShrink: 0 }}>
              <a href={`/report/${item.id}`} style={{ fontSize: 10, color: '#2563eb', textDecoration: 'none', padding: '3px 8px', background: '#eff6ff', borderRadius: 4, fontWeight: 500 }}>View</a>
              <button onClick={() => onReanalyze(item.input)} style={{ fontSize: 10, color: '#7c3aed', background: '#f3e8ff', border: 'none', borderRadius: 4, padding: '3px 8px', cursor: 'pointer', fontWeight: 500 }}>Rescan</button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
