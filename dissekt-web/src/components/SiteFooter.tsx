'use client';
import { useState, useEffect } from 'react';

export default function SiteFooter() {
  const [isInvited, setIsInvited] = useState(false);
  useEffect(() => {
    if (typeof window !== 'undefined') {
      const invited = localStorage.getItem('dissekt_tier') === 'member';
      const admin = localStorage.getItem('dissekt_admin') === 'true';
      setIsInvited(invited || admin);
    }
  }, []);
  return (
    <footer style={{ background: '#f0fdfa', borderTop: '0.5px solid #ccfbf1', marginTop: 'auto' }}>
      <div className="dissekt-footer-inner" style={{ maxWidth: 1100, margin: '0 auto', padding: '14px 24px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 8 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 11, color: '#5f8a84' }}>
          <div style={{ width: 16, height: 16, background: '#0d9488', borderRadius: 4, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
            <svg width="8" height="8" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
          </div>
          <span>© 2026 Dissekt · Munich · Beta</span>
        </div>
        <div className="dissekt-footer-links" style={{ display: 'flex', gap: 14, fontSize: 11, flexWrap: 'wrap' }}>
          {isInvited && (<>
          <a href="https://discord.gg/Bkv4zpmdJD" target="_blank" rel="noopener" title="Join our Discord" style={{ display: 'flex', alignItems: 'center', gap: 4, color: '#5f8a84', textDecoration: 'none' }}>
            <svg width="13" height="13" viewBox="0 0 24 24" fill="currentColor"><path d="M20.317 4.37a19.79 19.79 0 0 0-4.885-1.515.074.074 0 0 0-.079.037c-.21.375-.444.864-.608 1.25a18.27 18.27 0 0 0-5.487 0 12.64 12.64 0 0 0-.617-1.25.077.077 0 0 0-.079-.037A19.736 19.736 0 0 0 3.677 4.37a.07.07 0 0 0-.032.027C.533 9.046-.32 13.58.099 18.057a.082.082 0 0 0 .031.057 19.9 19.9 0 0 0 5.993 3.03.078.078 0 0 0 .084-.028c.462-.63.874-1.295 1.226-1.994a.076.076 0 0 0-.041-.106 13.1 13.1 0 0 1-1.872-.892.077.077 0 0 1-.008-.128 10.2 10.2 0 0 0 .372-.292.074.074 0 0 1 .077-.01c3.928 1.793 8.18 1.793 12.062 0a.074.074 0 0 1 .078.009c.12.098.246.198.373.292a.077.077 0 0 1-.006.127 12.3 12.3 0 0 1-1.873.893.077.077 0 0 0-.041.107c.36.698.772 1.362 1.225 1.993a.076.076 0 0 0 .084.028 19.84 19.84 0 0 0 6.002-3.03.077.077 0 0 0 .032-.054c.5-5.177-.838-9.674-3.549-13.66a.061.061 0 0 0-.031-.03zM8.02 15.33c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.956-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.956 2.418-2.157 2.418zm7.975 0c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.955-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.946 2.418-2.157 2.418z"/></svg>Discord
          </a>
          </>)}
          <a href="/help" style={{ color: '#5f8a84', textDecoration: 'none' }}>Help</a>
          <a href="/feedback" style={{ color: '#5f8a84', textDecoration: 'none' }}>Feedback</a>
          <a href="/contact" style={{ color: '#5f8a84', textDecoration: 'none' }}>Contact</a>
          {isInvited && <a href="/docs" style={{ color: '#5f8a84', textDecoration: 'none' }}>API</a>}
          <a href="/privacy" style={{ color: '#5f8a84', textDecoration: 'none' }}>Privacy</a>
          {isInvited && <a href="/suggest" style={{ color: '#5f8a84', textDecoration: 'none' }}>Suggest source</a>}
          <a href="/terms" style={{ color: '#5f8a84', textDecoration: 'none' }}>Terms</a>
        </div>
      </div>
    </footer>
  );
}
