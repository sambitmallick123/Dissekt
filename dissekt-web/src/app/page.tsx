'use client';
import LandingPage from '@/components/LandingPage';

export default function Home() {
  return (
    <LandingPage
      onTryFree={() => window.location.href = '/analyze'}
      onSignIn={() => window.location.href = '/invite'}
    />
  );
}
