'use client';

export default function SiteHeader({ active }: { active?: string }) {
  const links = [
    { href: '/analyze', label: 'Analyze' },
    { href: '/topics', label: 'Topics' },
    { href: '/compare', label: 'Compare' },
    { href: '/docs', label: 'API' },
    { href: '/help', label: 'Help' },
  ];

  return (
    <nav style={{ background: '#fff', borderBottom: '1px solid #e5e5e5', position: 'sticky', top: 0, zIndex: 30 }}>
      <div style={{ maxWidth: 1100, margin: '0 auto', padding: '10px 24px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <a href="/" style={{ display: 'flex', alignItems: 'center', gap: 10, textDecoration: 'none', color: 'inherit' }}>
          <div style={{ width: 28, height: 28, background: '#7c3aed', borderRadius: 7, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
          </div>
          <span style={{ fontWeight: 700, fontSize: 16 }}>Dissekt</span>
          <span style={{ fontSize: 9, fontWeight: 700, color: '#7c3aed', background: '#f3e8ff', padding: '2px 6px', borderRadius: 4, letterSpacing: '0.05em' }}>BETA</span>
        </a>

        <div style={{ display: 'flex', alignItems: 'center', gap: 18 }}>
          {links.map(l => (
            <a key={l.href} href={l.href} className="nav-link"
              style={{ fontSize: 13, color: active === l.label ? '#7c3aed' : '#555', textDecoration: 'none', fontWeight: active === l.label ? 600 : 500 }}>
              {l.label}
            </a>
          ))}
          <a href="/invite" style={{ fontSize: 13, color: '#7c3aed', textDecoration: 'none', border: '1px solid #ddd6fe', borderRadius: 8, padding: '5px 14px', fontWeight: 600, background: '#faf5ff' }}>
            Get access
          </a>
        </div>
      </div>
    </nav>
  );
}
