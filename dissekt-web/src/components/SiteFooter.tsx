'use client';

export default function SiteFooter() {
  return (
    <footer style={{ background: '#fff', borderTop: '0.5px solid #e5eaea', marginTop: 40 }}>
      <div style={{ maxWidth: 1100, margin: '0 auto', padding: '24px', display: 'flex', flexWrap: 'wrap', justifyContent: 'space-between', alignItems: 'start', gap: 20 }}>
        <div style={{ maxWidth: 280 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
            <div style={{ width: 24, height: 24, background: '#0d9488', borderRadius: 6, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
            </div>
            <span style={{ fontWeight: 700, fontSize: 14, color: '#1a1a1a' }}>Dissekt</span>
            <span style={{ fontSize: 8, fontWeight: 700, color: '#0d9488', background: '#f0fdfa', padding: '1px 5px', borderRadius: 3 }}>BETA</span>
          </div>
          <p style={{ fontSize: 12, color: '#888', lineHeight: 1.6 }}>Information transparency and argument inspection. See how information is constructed.</p>
        </div>

        <div style={{ display: 'flex', gap: 40, flexWrap: 'wrap' }}>
          <div>
            <div style={{ fontSize: 11, fontWeight: 600, color: '#404040', textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 8 }}>Product</div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
              <a href="/analyze" style={{ fontSize: 12, color: '#888', textDecoration: 'none' }}>Analyze</a>
              <a href="/topics" style={{ fontSize: 12, color: '#888', textDecoration: 'none' }}>Topics</a>
              <a href="/compare" style={{ fontSize: 12, color: '#888', textDecoration: 'none' }}>Compare</a>
              <a href="/docs" style={{ fontSize: 12, color: '#888', textDecoration: 'none' }}>API</a>
            </div>
          </div>
          <div>
            <div style={{ fontSize: 11, fontWeight: 600, color: '#404040', textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 8 }}>Resources</div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
              <a href="/help" style={{ fontSize: 12, color: '#888', textDecoration: 'none' }}>How it works</a>
              <a href="/invite" style={{ fontSize: 12, color: '#888', textDecoration: 'none' }}>Get access</a>
              <a href="/feedback" style={{ fontSize: 12, color: '#888', textDecoration: 'none' }}>Feedback</a>
              <a href="/bookmarklet" style={{ fontSize: 12, color: '#888', textDecoration: 'none' }}>Bookmarklet</a>
              <a href="/contact" style={{ fontSize: 12, color: '#888', textDecoration: 'none' }}>Contact</a>
            </div>
          </div>
          <div>
            <div style={{ fontSize: 11, fontWeight: 600, color: '#404040', textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 8 }}>Legal</div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
              <a href="/privacy" style={{ fontSize: 12, color: '#888', textDecoration: 'none' }}>Privacy Policy</a>
              <a href="/terms" style={{ fontSize: 12, color: '#888', textDecoration: 'none' }}>Terms of Service</a>
              <a href="/disclaimer" style={{ fontSize: 12, color: '#888', textDecoration: 'none' }}>Data Disclaimer</a>
            </div>
          </div>
        </div>
      </div>
      <div style={{ borderTop: '0.5px solid #e5eaea', padding: '14px 24px', textAlign: 'center' }}>
        <p style={{ fontSize: 11, color: '#aaa' }}>© 2026 Dissekt · Built by Sambit Mallick · Munich, Germany · Beta — under active development</p>
      </div>
    </footer>
  );
}
