'use client';
import SiteHeader from '@/components/SiteHeader';
import SiteFooter from '@/components/SiteFooter';

export default function PrivacyPage() {
  return (
    <main style={{ minHeight: '100vh', background: '#fafaf8' }}>
      <SiteHeader />

      <div style={{ maxWidth: 800, margin: '0 auto', padding: '32px 16px' }}>
        <h1 style={{ fontSize: 24, fontWeight: 700, marginBottom: 4 }}>Privacy Policy</h1>
        <p style={{ fontSize: 13, color: '#888', marginBottom: 24 }}>Last updated: June 9, 2026</p>

        <div style={{ background: '#fff', border: '1px solid #e5e5e5', borderRadius: 14, padding: '24px 28px', fontSize: 13, color: '#404040', lineHeight: 1.8 }}>
          <h2 style={{ fontSize: 16, fontWeight: 600, marginBottom: 8, marginTop: 0 }}>1. What Dissekt does</h2>
          <p>Dissekt is an information transparency tool that analyzes text, URLs, and images for manipulation techniques, cross-references existing fact-checks, and scores source credibility. It is available as a web application at dissekt.info and as a Chrome browser extension.</p>

          <h2 style={{ fontSize: 16, fontWeight: 600, marginBottom: 8, marginTop: 20 }}>2. Data we collect</h2>
          <p><strong>Content you submit for analysis:</strong> When you paste text, a URL, or upload an image, that content is sent to our analysis servers for processing. We do not store the full content permanently. A short preview (first 200 characters) may be stored alongside the analysis result for shareable reports.</p>
          <p><strong>Analysis results:</strong> The output of each analysis (techniques detected, cross-references found, scores) is stored in our database to enable shareable report links and the knowledge graph feature.</p>
          <p><strong>Feedback and corrections:</strong> If you submit feedback or use the 👍/👎 correction buttons, your input is stored to improve future analysis accuracy.</p>
          <p><strong>Ledger:</strong> If you mark content as Trust/Unsure/Reject, this is stored to enable the journal feature.</p>
          <p><strong>Usage data:</strong> We track the number of scans per day for rate limiting. No personal identifying information is collected.</p>

          <h2 style={{ fontSize: 16, fontWeight: 600, marginBottom: 8, marginTop: 20 }}>3. Chrome extension</h2>
          <p>The Dissekt Chrome extension allows you to right-click any text, link, or page to analyze it. When you use this feature:</p>
          <p>• The selected text or URL is sent to our analysis API ({'"'}https://dissekt-api.up.railway.app{'"'}) for processing.</p>
          <p>• The last analysis result is stored locally in Chrome{"'"}s storage (using the chrome.storage API) so it can be displayed in the extension popup.</p>
          <p>• No data is collected in the background. The extension only activates when you explicitly right-click and choose {'"'}Analyze with Dissekt.{'"'}</p>
          <p>• No browsing history, cookies, or personal data is accessed or collected.</p>

          <h2 style={{ fontSize: 16, fontWeight: 600, marginBottom: 8, marginTop: 20 }}>4. Third-party services</h2>
          <p>Dissekt uses the following third-party services to process your content:</p>
          <p>• <strong>OpenAI API</strong> (GPT-4o mini) — for Brief Mode analysis and claim extraction. Your submitted text is sent to OpenAI for processing. See <a href="https://openai.com/privacy" style={{ color: '#0d9488' }}>OpenAI Privacy Policy</a>.</p>
          <p>• <strong>Anthropic API</strong> (Claude) — for Detailed Mode analysis. See <a href="https://www.anthropic.com/privacy" style={{ color: '#0d9488' }}>Anthropic Privacy Policy</a>.</p>
          <p>• <strong>Google Fact Check API</strong> — for finding existing fact-checks. Only the claim text is sent.</p>
          <p>• <strong>Supabase</strong> — for storing reports, feedback, and corrections. Data is hosted in EU (Frankfurt).</p>
          <p>• <strong>Qdrant Cloud</strong> — for the knowledge graph. Text embeddings (not raw text) are stored for similarity search.</p>
          <p>Toxicity analysis (Detoxify), sentiment analysis (VADER), and source credibility scoring (MBFC) run entirely on our servers. No content is sent to external services for these features.</p>

          <h2 style={{ fontSize: 16, fontWeight: 600, marginBottom: 8, marginTop: 20 }}>5. Data retention</h2>
          <p>• Analysis reports are stored indefinitely to support shareable links.</p>
          <p>• Feedback and corrections are stored indefinitely to improve the system.</p>
          <p>• Chrome extension local storage can be cleared by the user at any time via Chrome settings.</p>

          <h2 style={{ fontSize: 16, fontWeight: 600, marginBottom: 8, marginTop: 20 }}>6. Data sharing</h2>
          <p>We do not sell, rent, or share your data with any third party for advertising or marketing purposes. Data is only shared with the third-party services listed above for the purpose of content analysis.</p>

          <h2 style={{ fontSize: 16, fontWeight: 600, marginBottom: 8, marginTop: 20 }}>7. Your rights</h2>
          <p>You can:</p>
          <p>• Request deletion of your data by contacting us at sambitmallick123@gmail.com</p>
          <p>• Clear Chrome extension local storage at any time</p>
          <p>• Use the service without creating an account</p>
          <p>If you are located in the EU, you have additional rights under GDPR including the right to access, rectify, and erase your personal data.</p>

          <h2 style={{ fontSize: 16, fontWeight: 600, marginBottom: 8, marginTop: 20 }}>8. Contact</h2>
          <p>For privacy questions or data deletion requests:</p>
          <p>Email: <a href="mailto:sambitmallick123@gmail.com" style={{ color: '#0d9488' }}>sambitmallick123@gmail.com</a></p>
          <p>Operator: Sambit Mallick, Munich, Germany</p>

          <h2 style={{ fontSize: 16, fontWeight: 600, marginBottom: 8, marginTop: 20 }}>9. Changes</h2>
          <p>We may update this policy from time to time. The latest version will always be available at <a href="https://dissekt.info/privacy" style={{ color: '#0d9488' }}>dissekt.info/privacy</a>.</p>
        </div>
      </div>
    <SiteFooter />
    </main>
  );
}
