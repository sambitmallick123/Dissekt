'use client';
import { useEffect } from 'react';

export default function InviteRedirect() {
  useEffect(() => { window.location.replace('/signup'); }, []);
  return (
    <main style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: '60vh', color: '#888', fontSize: 14 }}>
      Redirecting to sign up…
    </main>
  );
}
