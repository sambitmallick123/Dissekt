'use client';

export default function SiteFooter() {
  return (
    <footer style={{ background: '#f0fdfa', borderTop: '0.5px solid #ccfbf1', marginTop: 40 }}>
      <div className="dissekt-footer-inner" style={{ maxWidth: 1100, margin: '0 auto', padding: '14px 24px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 11, color: '#5f8a84' }}>
          <div style={{ width: 16, height: 16, background: '#0d9488', borderRadius: 4, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
            <svg width="8" height="8" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
          </div>
          <span>© 2026 Dissekt · Munich · Beta</span>
        </div>
        <div className="dissekt-footer-links" style={{ display: 'flex', gap: 14, fontSize: 11 }}>
          <a href="/help" style={{ color: '#5f8a84', textDecoration: 'none' }}>Help</a>
          <a href="/feedback" style={{ color: '#5f8a84', textDecoration: 'none' }}>Feedback</a>
          <a href="/contact" style={{ color: '#5f8a84', textDecoration: 'none' }}>Contact</a>
          <a href="/docs" style={{ color: '#5f8a84', textDecoration: 'none' }}>API</a>
          <a href="/privacy" style={{ color: '#5f8a84', textDecoration: 'none' }}>Privacy</a>
          <a href="/terms" style={{ color: '#5f8a84', textDecoration: 'none' }}>Terms</a>
        </div>
      </div>
    </footer>
  );
}
