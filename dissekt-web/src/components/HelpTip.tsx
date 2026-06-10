'use client';
import { useState } from 'react';

export default function HelpTip({ text }: { text: string }) {
  const [show, setShow] = useState(false);

  return (
    <span style={{ position: 'relative', display: 'inline-flex', alignItems: 'center', marginLeft: 6 }}>
      <button
        onMouseEnter={() => setShow(true)}
        onMouseLeave={() => setShow(false)}
        onClick={() => setShow(!show)}
        style={{
          width: 16, height: 16, borderRadius: 8, border: '1px solid #d4d4d4',
          background: show ? '#0d9488' : '#f0f0ee', color: show ? '#fff' : '#888',
          fontSize: 10, fontWeight: 600, cursor: 'pointer', display: 'flex',
          alignItems: 'center', justifyContent: 'center', padding: 0, lineHeight: 1,
        }}
        aria-label="Help"
      >?</button>
      {show && (
        <div style={{
          position: 'absolute', bottom: 24, left: '50%', transform: 'translateX(-50%)',
          background: '#1a1a1a', color: '#fff', fontSize: 11, lineHeight: 1.5,
          padding: '8px 12px', borderRadius: 8, width: 240, zIndex: 50,
          boxShadow: '0 4px 16px rgba(0,0,0,0.15)', pointerEvents: 'none',
        }}>
          {text}
          <div style={{
            position: 'absolute', top: '100%', left: '50%', transform: 'translateX(-50%)',
            width: 0, height: 0, borderLeft: '6px solid transparent',
            borderRight: '6px solid transparent', borderTop: '6px solid #1a1a1a',
          }} />
        </div>
      )}
    </span>
  );
}
