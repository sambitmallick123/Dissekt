import type { Metadata } from 'next';
import './responsive.css';
import './globals.css';

export const metadata: Metadata = {
  viewport: 'width=device-width, initial-scale=1, maximum-scale=5',
  title: 'Dissekt — See how information is constructed',
  description: 'Information transparency tool. Inspect how articles frame claims, what evidence supports them, and what context is missing.',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet" />
      </head>
      <body style={{ fontFamily: "'Inter', -apple-system, BlinkMacSystemFont, sans-serif" }}>
        {children}
      </body>
    </html>
  );
}
