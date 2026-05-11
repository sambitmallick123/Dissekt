import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Dissekt — Explanation, not verdicts',
  description: 'Dissect manipulative content. Trace claims to their source. Export the evidence.',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="antialiased">{children}</body>
    </html>
  );
}
