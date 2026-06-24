'use client';
import SiteHeader from '@/components/SiteHeader';
import SiteFooter from '@/components/SiteFooter';

export default function TermsPage() {
  return (
    <main style={{ flex: 1, background: '#fafaf8' }}>
      <SiteHeader />
      <div style={{ maxWidth: 800, margin: '0 auto', padding: '32px 16px' }}>
        <h1 style={{ fontSize: 24, fontWeight: 700, marginBottom: 4 }}>Terms of Service</h1>
        <p style={{ fontSize: 13, color: '#888', marginBottom: 24 }}>Last updated: June 24, 2026 · Beta</p>

        <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: '24px 28px', fontSize: 13, color: '#404040', lineHeight: 1.8 }}>
          <div style={{ padding: '10px 14px', background: '#fffbeb', border: '1px solid #fde68a', borderRadius: 8, marginBottom: 20 }}>
            <strong>⚠️ Beta Notice:</strong> Dissekt is in beta and under active development. Features may change, break, or be removed without notice. Analysis results are provided as-is for informational purposes.
          </div>

          <h2 style={{ fontSize: 16, fontWeight: 600, marginTop: 0, marginBottom: 8 }}>1. Acceptance</h2>
          <p>By using Dissekt, you agree to these terms. If you disagree, please do not use the service.</p>

          <h2 style={{ fontSize: 16, fontWeight: 600, marginTop: 20, marginBottom: 8 }}>2. The service</h2>
          <p>Dissekt is an information transparency tool that analyzes content for manipulation techniques, cross-references existing fact-checks, and scores source credibility. It produces a Clarity Score and related analysis across several features: single scans of text, URLs, or images; keyword topic analysis of recent coverage; side-by-side comparison; a Chrome extension; and a Telegram bot. Dissekt does NOT determine whether content is true or false. It provides analytical perspectives to help you think critically.</p>

          <h2 style={{ fontSize: 16, fontWeight: 600, marginTop: 20, marginBottom: 8 }}>3. Nature of the analysis</h2>
          <p>All scores, technique detections, cross-references, and AI-generated reports are automated, probabilistic assessments. They may contain errors, omissions, or misclassifications. A high Clarity Score is not an endorsement and a low score is not a debunk. Dissekt is not a substitute for professional fact-checking, journalism, legal advice, or your own judgment. Do not rely solely on Dissekt for any important decision.</p>

          <h2 style={{ fontSize: 16, fontWeight: 600, marginTop: 20, marginBottom: 8 }}>4. Acceptable use</h2>
          <p>You agree not to: use the service for illegal purposes; attempt to overwhelm, probe, or attack our infrastructure; circumvent rate limits or access controls; scrape or resell our analysis at scale without permission; or use the service to harass, defame, or harm others. AI-generated reports are for your own use and must not be presented as independent factual verification.</p>

          <h2 style={{ fontSize: 16, fontWeight: 600, marginTop: 20, marginBottom: 8 }}>5. Access tiers</h2>
          <p>Free tier provides limited daily scans (3 brief + 1 detailed, resetting at 00:00 GMT) with no account required. A free member account provides expanded limits (25 brief + 10 detailed per day) and access to all member features, including Compare, your Dashboard, and API access. Brief and detailed scans are counted separately; keyword topic analyses count as one scan of the chosen depth. Limits may change as the service evolves.</p>

          <h2 style={{ fontSize: 16, fontWeight: 600, marginTop: 20, marginBottom: 8 }}>6. Accounts</h2>
          <p>You are responsible for keeping your account credentials secure and for activity under your account. You may request deletion of your account and associated data at any time (see the Privacy Policy). We may suspend accounts that violate these terms.</p>

          <h2 style={{ fontSize: 16, fontWeight: 600, marginTop: 20, marginBottom: 8 }}>7. Intellectual property</h2>
          <p>You retain rights to content you submit. By submitting content, you grant us a limited license to process it for analysis. Analysis outputs and scan metadata may be stored to provide features like shareable reports and your saved scan history.</p>

          <h2 style={{ fontSize: 16, fontWeight: 600, marginTop: 20, marginBottom: 8 }}>8. Third-party services</h2>
          <p>Dissekt relies on third-party providers to process content (including AI model providers and search services). Your submitted content may be processed by these providers solely to deliver the analysis. See the Privacy Policy for details.</p>

          <h2 style={{ fontSize: 16, fontWeight: 600, marginTop: 20, marginBottom: 8 }}>9. Disclaimers</h2>
          <p>THE SERVICE IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND. We do not guarantee accuracy, availability, or fitness for any purpose. We are not liable for any damages arising from use of the service.</p>

          <h2 style={{ fontSize: 16, fontWeight: 600, marginTop: 20, marginBottom: 8 }}>10. Changes</h2>
          <p>We may modify these terms or the service at any time. Continued use after changes constitutes acceptance.</p>

          <h2 style={{ fontSize: 16, fontWeight: 600, marginTop: 20, marginBottom: 8 }}>11. Contact</h2>
          <p>Questions: <a href="mailto:sambitmallick123@gmail.com" style={{ color: '#0d9488' }}>sambitmallick123@gmail.com</a> · Operator: Sambit Mallick, Munich, Germany</p>
        </div>
      </div>
      <SiteFooter />
    </main>
  );
}
