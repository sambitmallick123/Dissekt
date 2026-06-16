'use client';
import { useState, useEffect } from 'react';

export default function SiteFooter() {
  const [isInvited, setIsInvited] = useState(false);
  useEffect(() => {
    if (typeof window !== 'undefined') {
      const invited = localStorage.getItem('dissekt_tier') === 'invited';
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
          <a href="https://github.com/sambitmallick123/Dissekt" target="_blank" rel="noopener" title="GitHub" style={{ display: 'flex', alignItems: 'center', gap: 4, color: '#5f8a84', textDecoration: 'none' }}>
            <svg width="13" height="13" viewBox="0 0 24 24" fill="currentColor"><path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23A11.5 11.5 0 0 1 12 5.803c1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576C20.566 21.797 24 17.3 24 12c0-6.627-5.373-12-12-12z"/></svg>GitHub
          </a>
          </>)}
          <a href="/help" style={{ color: '#5f8a84', textDecoration: 'none' }}>Help</a>
          <a href="/feedback" style={{ color: '#5f8a84', textDecoration: 'none' }}>Feedback</a>
          <a href="/contact" style={{ color: '#5f8a84', textDecoration: 'none' }}>Contact</a>
          <a href="/docs" style={{ color: '#5f8a84', textDecoration: 'none' }}>API</a>
          <a href="/privacy" style={{ color: '#5f8a84', textDecoration: 'none' }}>Privacy</a>
          <a href="/suggest" style={{ color: '#5f8a84', textDecoration: 'none' }}>Suggest source</a>
          <a href="/terms" style={{ color: '#5f8a84', textDecoration: 'none' }}>Terms</a>
        </div>
      </div>
    </footer>
  );
}
