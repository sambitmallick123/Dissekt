'use client';
import SiteHeader from '@/components/SiteHeader';
import SiteFooter from '@/components/SiteFooter';

export default function BookmarkletPage() {
  const bookmarkletCode = "javascript:void(window.open('https://dissekt.info/analyze?url='+encodeURIComponent(window.location.href),'_blank'))";

  return (
    <main style={{ flex: 1, background: '#fafaf8' }}>
      <SiteHeader />
      <div style={{ maxWidth: 640, margin: '0 auto', padding: '48px 24px', textAlign: 'center' }}>
        <div style={{ fontSize: 32, marginBottom: 12 }}>🔖</div>
        <h1 style={{ fontSize: 24, fontWeight: 700, marginBottom: 8, color: '#1a1a1a' }}>One-click analyze</h1>
        <p style={{ fontSize: 14, color: '#888', marginBottom: 32, lineHeight: 1.6 }}>
          Drag the button below to your bookmarks bar. Then click it on any article to instantly analyze it with Dissekt.
        </p>

        <div style={{ marginBottom: 32 }}>
          <a href={bookmarkletCode} onClick={e => e.preventDefault()}
            draggable="true"
            style={{ display: 'inline-block', padding: '12px 28px', background: '#0d9488', color: '#fff', borderRadius: 10, fontSize: 15, fontWeight: 600, textDecoration: 'none', cursor: 'grab', boxShadow: '0 2px 8px rgba(13,148,136,0.3)' }}>
            📖 Analyze with Dissekt
          </a>
        </div>

        <div style={{ background: '#fff', border: '0.5px solid #e5eaea', borderRadius: 14, padding: 24, textAlign: 'left' }}>
          <h2 style={{ fontSize: 16, fontWeight: 600, marginBottom: 12 }}>How to install</h2>
          <div style={{ fontSize: 13, color: '#555', lineHeight: 2 }}>
            <strong>Desktop (Chrome, Firefox, Edge):</strong><br />
            1. Make sure your bookmarks bar is visible (Ctrl+Shift+B)<br />
            2. Drag the teal button above into your bookmarks bar<br />
            3. Visit any news article and click the bookmark<br />
            4. Dissekt opens with the article URL ready to analyze<br />
            <br />
            <strong>Mobile:</strong><br />
            1. Copy this URL and create a new bookmark with it:<br />
          </div>
          <div style={{ marginTop: 8, padding: '8px 12px', background: '#fafaf8', borderRadius: 6, fontSize: 11, color: '#555', wordBreak: 'break-all', fontFamily: 'monospace' }}>
            {bookmarkletCode}
          </div>
        </div>
      </div>
      <SiteFooter />
    </main>
  );
}
