// Dissekt content script — shows analysis overlay on any webpage

let overlay = null;

function createOverlay() {
  if (overlay) overlay.remove();

  overlay = document.createElement("div");
  overlay.id = "dissekt-overlay";
  overlay.innerHTML = `<div id="dissekt-panel">
    <div id="dissekt-header">
      <div id="dissekt-logo">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.5"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
        <span>Dissekt</span>
      </div>
      <button id="dissekt-close">&times;</button>
    </div>
    <div id="dissekt-body">
      <div id="dissekt-loading">Analyzing...</div>
    </div>
  </div>`;

  document.body.appendChild(overlay);

  document.getElementById("dissekt-close").addEventListener("click", () => {
    overlay.remove();
    overlay = null;
  });

  overlay.addEventListener("click", (e) => {
    if (e.target === overlay) {
      overlay.remove();
      overlay = null;
    }
  });
}

function showLoading(content) {
  createOverlay();
  const body = document.getElementById("dissekt-body");
  body.innerHTML = `
    <div class="dissekt-loading-state">
      <div class="dissekt-spinner"></div>
      <div class="dissekt-loading-text">Analyzing content...</div>
      <div class="dissekt-loading-preview">${escapeHtml(content)}</div>
    </div>
  `;
}

function showResult(data, content, reportId) {
  if (!overlay) createOverlay();
  const body = document.getElementById("dissekt-body");

  const techs = data.prism?.techniques || [];
  const fcs = data.trace?.fact_checks || [];
  const tox = data.signal?.toxicity_score || 0;
  const maxConf = techs.reduce((max, t) => Math.max(max, t.confidence || 0), 0);
  let score = (techs.length > 0 ? Math.round(maxConf * 40) : 0) + Math.min(fcs.length * 4, 30) + Math.round(tox * 20) + (fcs.length >= 3 ? 10 : 0);
  score = Math.min(score, 100);

  const scoreColor = score >= 70 ? "#dc2626" : score >= 40 ? "#d97706" : "#16a34a";
  const scoreLabel = score >= 70 ? "HIGH RISK" : score >= 40 ? "MEDIUM" : "LOW RISK";

  let techsHtml = techs.length === 0
    ? '<div class="dissekt-clean">✓ No manipulation techniques detected</div>'
    : techs.map(t => {
        const conf = Math.round(t.confidence * 100);
        const barColor = conf >= 85 ? "#dc2626" : conf >= 70 ? "#d97706" : "#eab308";
        const name = t.name.replace(/_/g, " ").replace(/\b\w/g, c => c.toUpperCase());
        return `<div class="dissekt-tech">
          <div class="dissekt-tech-row">
            <span class="dissekt-tech-name">${escapeHtml(name)}</span>
            <span class="dissekt-tech-conf" style="color:${barColor}">${conf}%</span>
          </div>
          <div class="dissekt-bar-bg"><div class="dissekt-bar" style="width:${conf}%;background:${barColor}"></div></div>
          <div class="dissekt-tech-exp">${escapeHtml(t.explanation || "")}</div>
        </div>`;
      }).join("");

  let fcsHtml = fcs.length === 0
    ? '<div class="dissekt-no-fc">No existing cross-references found</div>'
    : fcs.slice(0, 4).map(fc => {
        const rating = (fc.rating || "").toLowerCase();
        const rColor = rating.includes("false") ? "#dc2626" : rating.includes("true") ? "#16a34a" : "#d97706";
        return `<div class="dissekt-fc">
          <div class="dissekt-fc-pub">${escapeHtml(fc.publisher || "")}</div>
          <div class="dissekt-fc-title">${escapeHtml((fc.title || "").slice(0, 60))}</div>
          <span class="dissekt-fc-badge" style="color:${rColor}">${escapeHtml(fc.rating || "N/A")}</span>
        </div>`;
      }).join("") + (fcs.length > 4 ? `<div class="dissekt-fc-more">+ ${fcs.length - 4} more</div>` : "");

  // reportId passed from background script

  body.innerHTML = `
    <div class="dissekt-content-preview">${escapeHtml(content)}</div>

    <div class="dissekt-score-row">
      <div class="dissekt-score-circle" style="border-color:${scoreColor}">
        <span class="dissekt-score-num" style="color:${scoreColor}">${score}</span>
      </div>
      <div class="dissekt-score-info">
        <div class="dissekt-score-label" style="color:${scoreColor}">${scoreLabel}</div>
        <div class="dissekt-score-meta">${techs.length} techniques · ${fcs.length} cross-references · ${(tox * 100).toFixed(1)}% toxicity</div>
      </div>
      <div class="dissekt-score-time">${(data.analysis_time_ms / 1000).toFixed(1)}s</div>
    </div>

    <div class="dissekt-section">
      <div class="dissekt-section-title">👁 Techniques</div>
      ${techsHtml}
    </div>

    ${data.prism?.brief ? `<div class="dissekt-summary">${escapeHtml(data.prism.brief)}</div>` : ""}

    <div class="dissekt-section">
      <div class="dissekt-section-title">🌐 Cross-references</div>
      ${fcsHtml}
    </div>

    <div class="dissekt-actions">
      <a href="https://dissekt.info/report/${reportId}" target="_blank" class="dissekt-btn-primary">Full report →</a>
      <a href="https://dissekt.info" target="_blank" class="dissekt-btn-secondary">Open Dissekt</a>
    </div>
  `;
}

function showError(message) {
  if (!overlay) createOverlay();
  const body = document.getElementById("dissekt-body");
  body.innerHTML = `
    <div class="dissekt-error">
      <div class="dissekt-error-icon">⚠️</div>
      <div class="dissekt-error-msg">${escapeHtml(message)}</div>
      <a href="https://dissekt.info" target="_blank" class="dissekt-btn-secondary">Try on dissekt.info</a>
    </div>
  `;
}

function escapeHtml(str) {
  const div = document.createElement("div");
  div.textContent = str;
  return div.innerHTML;
}

// Listen for messages from background script
chrome.runtime.onMessage.addListener((msg) => {
  if (msg.type === "dissekt-loading") showLoading(msg.content);
  if (msg.type === "dissekt-result") showResult(msg.data, msg.content, msg.reportId);
  if (msg.type === "dissekt-error") showError(msg.message);
});
