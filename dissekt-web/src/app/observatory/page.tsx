import { redirect } from 'next/navigation';

// Constellation / Observatory is gated off. The component still lives in
// src/components/Constellation.tsx and the backend behind ENABLE_CONSTELLATION
// in app/main.py — flip both and restore this file from page.tsx.bak to revive.
export default function ObservatoryPage() {
  redirect('/');
}
