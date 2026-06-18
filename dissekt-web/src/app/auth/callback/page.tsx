'use client';
import { useEffect, useState } from 'react';
import { supabase } from '@/lib/supabase';

export default function AuthCallback() {
  const [msg, setMsg] = useState('Confirming…');

  useEffect(() => {
    // Supabase client (detectSessionInUrl: true) auto-parses the #access_token
    // fragment and stores the session. We just wait for it, then route.
    const finish = async () => {
      // Give the client a tick to process the URL hash
      const { data } = await supabase.auth.getSession();
      if (data.session) {
        // Determine intent from the URL: signup vs recovery
        const hash = window.location.hash || '';
        if (hash.includes('type=recovery')) {
          window.location.replace('/auth/reset-password');
        } else {
          window.location.replace('/dashboard');
        }
      } else {
        // Listen briefly in case the session is still being set
        const { data: sub } = supabase.auth.onAuthStateChange((_e, session) => {
          if (session) {
            const hash = window.location.hash || '';
            window.location.replace(hash.includes('type=recovery') ? '/auth/reset-password' : '/dashboard');
          }
        });
        // Fallback after 3s
        setTimeout(() => {
          setMsg('This link may have expired. Please sign in or request a new link.');
          sub.subscription.unsubscribe();
        }, 3000);
      }
    };
    finish();
  }, []);

  return (
    <main style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', minHeight: '60vh', gap: 12 }}>
      <div style={{ fontSize: 14, color: '#888' }}>{msg}</div>
      {msg.includes('expired') && (
        <a href="/login" style={{ color: '#0d9488', fontSize: 13, textDecoration: 'none', fontWeight: 600 }}>Go to sign in</a>
      )}
    </main>
  );
}
