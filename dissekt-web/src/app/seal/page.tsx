'use client';
import SiteHeader from '@/components/SiteHeader';
import SiteFooter from '@/components/SiteFooter';

export default function BadgePage() {
  const embedCode = '<script src="https://dissekt.info/badge.js" data-url="YOUR_ARTICLE_URL"></script>';
  const autoCode = '<script src="https://dissekt.info/badge.js"></script>';

  return (
    <main style={{ minHeight: '100vh', background: '#f8fafa' }}>
      <SiteHeader />
      <div style={{ maxWidth: 700, margin: '0 auto', padding: '32px 24px' }}>
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 4 }}>🏷️ Embeddable Transparency Badge</h1>
        <p style={{ fontSize: 13, color: '#888', marginBottom: 24 }}>Add a live Dissekt transparency score to any article on your site.</p>

        <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 24 }}>
          <h2 style={{ fontSize: 16, fontWeight: 600, marginBottom: 12 }}>Quick start</h2>
          <p style={{ fontSize: 13, color: '#555', marginBottom: 12 }}>Add this script tag where you want the badge to appear:</p>
          
          <div style={{ background: '#1a1a1a', borderRadius: 8, padding: '12px 16px', marginBottom: 16 }}>
            <code style={{ fontSize: 12, color: '#5eead4', fontFamily: 'monospace' }}>{autoCode}</code>
          </div>
          
          <p style={{ fontSize: 12, color: '#888', marginBottom: 16 }}>This auto-detects the current page URL. To specify a URL:</p>
          
          <div style={{ background: '#1a1a1a', borderRadius: 8, padding: '12px 16px', marginBottom: 16 }}>
            <code style={{ fontSize: 11, color: '#5eead4', fontFamily: 'monospace', wordBreak: 'break-all' }}>{embedCode}</code>
          </div>

          <h2 style={{ fontSize: 16, fontWeight: 600, marginBottom: 8, marginTop: 20 }}>What it shows</h2>
          <div style={{ display: 'inline-flex', alignItems: 'center', gap: 8, padding: '6px 12px', borderRadius: 8, border: '1px solid #e5eaea', background: '#fff', fontSize: 12 }}>
            <div style={{ width: 20, height: 20, background: '#0d9488', borderRadius: 5, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
            </div>
            <span style={{ fontWeight: 600, color: '#16a34a' }}>78</span>
            <span style={{ color: '#888' }}>High transparency</span>
            <span style={{ color: '#0d9488', fontSize: 10 }}>by Dissekt</span>
          </div>
          <p style={{ fontSize: 12, color: '#888', marginTop: 8 }}>Clicking the badge opens the full analysis on dissekt.info.</p>

          <h2 style={{ fontSize: 16, fontWeight: 600, marginBottom: 8, marginTop: 20 }}>Why add it</h2>
          <div style={{ fontSize: 13, color: '#555', lineHeight: 1.8 }}>
            Signals editorial transparency to your readers. Shows you have nothing to hide. Every badge links back to a full Dissekt analysis — building trust in your content.
          </div>
        </div>
      </div>
      <SiteFooter />
    </main>
  );
}
