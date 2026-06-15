'use client';
import { useState, useEffect } from 'react';

const MARKETS = ['india', 'us', 'germany', 'uk', 'international', 'substack'];
const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';
const ADMIN_KEY = 'dissekt-sambit-2026';

export default function FeedsTab() {
  const [feeds, setFeeds] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [adding, setAdding] = useState(false);
  const [newFeed, setNewFeed] = useState({ name: '', url: '', market: 'international' });
  const [editId, setEditId] = useState<number | null>(null);
  const [editData, setEditData] = useState<any>({});

  const load = async () => {
    setLoading(true);
    try {
      const res = await fetch(`${API_URL}/api/admin/feeds`);
      const data = await res.json();
      setFeeds(data.feeds || []);
    } catch {} finally { setLoading(false); }
  };

  useEffect(() => { load(); }, []);

  const post = async (body: any) => {
    const res = await fetch(`${API_URL}/api/admin/feeds`, {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ ...body, adminKey: ADMIN_KEY }),
    });
    const data = await res.json();
    if (data.feeds) setFeeds(data.feeds);
    return data;
  };

  const addFeed = async () => {
    if (!newFeed.name || !newFeed.url) return;
    await post({ action: 'add', ...newFeed });
    setNewFeed({ name: '', url: '', market: 'international' });
    setAdding(false);
  };

  const saveEdit = async () => {
    await post({ action: 'update', id: editId, ...editData });
    setEditId(null);
  };

  const del = async (id: number) => {
    if (!confirm('Remove this feed?')) return;
    await post({ action: 'delete', id });
  };

  const toggle = async (id: number, active: boolean) => {
    await post({ action: 'toggle', id, active: !active });
  };

  // Group by market
  const byMarket: Record<string, any[]> = {};
  feeds.forEach(f => { (byMarket[f.market] = byMarket[f.market] || []).push(f); });

  if (loading) return <div style={{ padding: 20, textAlign: 'center', color: '#888' }}>Loading feeds...</div>;

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
        <div>
          <div style={{ fontSize: 14, fontWeight: 600, color: '#1a1a1a' }}>Scope feeds ({feeds.length})</div>
          <div style={{ fontSize: 11, color: '#888' }}>RSS sources monitored by the news feed. Changes apply live.</div>
        </div>
        <button onClick={() => setAdding(!adding)} style={{ fontSize: 11, padding: '6px 14px', background: '#0d9488', color: '#fff', border: 'none', borderRadius: 6, cursor: 'pointer', fontWeight: 600 }}>
          {adding ? 'Cancel' : '+ Add feed'}
        </button>
      </div>

      {/* Add form */}
      {adding && (
        <div style={{ display: 'flex', gap: 6, marginBottom: 12, padding: 12, background: '#f8fafa', borderRadius: 8, flexWrap: 'wrap' }}>
          <input placeholder="Name (e.g. BBC News)" value={newFeed.name} onChange={e => setNewFeed({ ...newFeed, name: e.target.value })} style={{ flex: '1 1 140px', padding: '7px 10px', border: '0.5px solid #e5eaea', borderRadius: 5, fontSize: 12, outline: 'none' }} />
          <input placeholder="RSS URL" value={newFeed.url} onChange={e => setNewFeed({ ...newFeed, url: e.target.value })} style={{ flex: '2 1 240px', padding: '7px 10px', border: '0.5px solid #e5eaea', borderRadius: 5, fontSize: 12, outline: 'none' }} />
          <select value={newFeed.market} onChange={e => setNewFeed({ ...newFeed, market: e.target.value })} style={{ padding: '7px 10px', border: '0.5px solid #e5eaea', borderRadius: 5, fontSize: 12 }}>
            {MARKETS.map(m => <option key={m} value={m}>{m}</option>)}
          </select>
          <button onClick={addFeed} style={{ padding: '7px 16px', background: '#0d9488', color: '#fff', border: 'none', borderRadius: 5, fontSize: 12, fontWeight: 600, cursor: 'pointer' }}>Save</button>
        </div>
      )}

      {/* Feeds grouped by market */}
      {MARKETS.filter(m => byMarket[m]?.length).map(market => (
        <div key={market} style={{ marginBottom: 14 }}>
          <div style={{ fontSize: 11, fontWeight: 600, color: '#888', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: 6 }}>{market} ({byMarket[market].length})</div>
          {byMarket[market].map(f => (
            <div key={f.id} style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '8px 12px', background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 8, marginBottom: 4, opacity: f.active ? 1 : 0.5 }}>
              {editId === f.id ? (
                <>
                  <input value={editData.name} onChange={e => setEditData({ ...editData, name: e.target.value })} style={{ flex: '1 1 120px', padding: '5px 8px', border: '0.5px solid #e5eaea', borderRadius: 4, fontSize: 12 }} />
                  <input value={editData.url} onChange={e => setEditData({ ...editData, url: e.target.value })} style={{ flex: '2 1 200px', padding: '5px 8px', border: '0.5px solid #e5eaea', borderRadius: 4, fontSize: 11 }} />
                  <select value={editData.market} onChange={e => setEditData({ ...editData, market: e.target.value })} style={{ padding: '5px', border: '0.5px solid #e5eaea', borderRadius: 4, fontSize: 11 }}>
                    {MARKETS.map(m => <option key={m} value={m}>{m}</option>)}
                  </select>
                  <button onClick={saveEdit} style={{ fontSize: 10, padding: '4px 10px', background: '#0d9488', color: '#fff', border: 'none', borderRadius: 4, cursor: 'pointer' }}>Save</button>
                  <button onClick={() => setEditId(null)} style={{ fontSize: 10, padding: '4px 10px', background: '#f0f0ee', color: '#888', border: 'none', borderRadius: 4, cursor: 'pointer' }}>Cancel</button>
                </>
              ) : (
                <>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontSize: 12, fontWeight: 600, color: '#1a1a1a' }}>{f.name}</div>
                    <a href={f.url} target="_blank" rel="noopener" style={{ fontSize: 10, color: '#0d9488', textDecoration: 'none', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', display: 'block' }}>{f.url}</a>
                  </div>
                  <button onClick={() => toggle(f.id, f.active)} title={f.active ? 'Active' : 'Disabled'} style={{ fontSize: 14, padding: '2px 6px', background: 'none', border: 'none', cursor: 'pointer' }}>{f.active ? '🟢' : '⚪'}</button>
                  <button onClick={() => { setEditId(f.id); setEditData({ name: f.name, url: f.url, market: f.market }); }} style={{ fontSize: 10, padding: '4px 8px', background: '#eff6ff', color: '#2563eb', border: 'none', borderRadius: 4, cursor: 'pointer' }}>Edit</button>
                  <button onClick={() => del(f.id)} style={{ fontSize: 10, padding: '4px 8px', background: '#fef2f2', color: '#dc2626', border: 'none', borderRadius: 4, cursor: 'pointer' }}>Remove</button>
                </>
              )}
            </div>
          ))}
        </div>
      ))}
    </div>
  );
}
