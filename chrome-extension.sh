#!/bin/bash
# Dissekt Chrome Extension
# Creates a complete Chrome extension in dissekt-extension/
set -e

cd /mnt/d/Startup\ Ideas/Dissekt
mkdir -p dissekt-extension/icons

# ============================================
# manifest.json (Manifest V3)
# ============================================
cat > dissekt-extension/manifest.json << 'EOF'
{
  "manifest_version": 3,
  "name": "Dissekt — See the Playbook",
  "version": "1.0.0",
  "description": "Right-click any text to detect manipulation techniques, find fact-checks, and score source credibility. Don't get played.",
  "permissions": ["contextMenus", "activeTab", "storage"],
  "host_permissions": ["https://dissekt.info/*", "https://dissekt-api.up.railway.app/*"],
  "background": {
    "service_worker": "background.js"
  },
  "action": {
    "default_popup": "popup.html",
    "default_icon": {
      "16": "icons/icon16.png",
      "48": "icons/icon48.png",
      "128": "icons/icon128.png"
    }
  },
  "icons": {
    "16": "icons/icon16.png",
    "48": "icons/icon48.png",
    "128": "icons/icon128.png"
  },
  "content_scripts": [
    {
      "matches": ["<all_urls>"],
      "js": ["content.js"],
      "css": ["content.css"]
    }
  ]
}
EOF

# ============================================
# background.js — context menu + API calls
# ============================================
cat > dissekt-extension/background.js << 'BGEOF'
const API_URL = "https://dissekt-api.up.railway.app";
const WEB_URL = "https://dissekt.info";

// Create context menu on install
chrome.runtime.onInstalled.addListener(() => {
  chrome.contextMenus.create({
    id: "dissekt-analyze",
    title: "Analyze with Dissekt",
    contexts: ["selection"]
  });

  chrome.contextMenus.create({
    id: "dissekt-analyze-link",
    title: "Analyze this link with Dissekt",
    contexts: ["link"]
  });

  chrome.contextMenus.create({
    id: "dissekt-analyze-page",
    title: "Analyze this page with Dissekt",
    contexts: ["page"]
  });
});

// Handle context menu clicks
chrome.contextMenus.onClicked.addListener(async (info, tab) => {
  let content = "";

  if (info.menuItemId === "dissekt-analyze") {
    content = info.selectionText || "";
  } else if (info.menuItemId === "dissekt-analyze-link") {
    content = info.linkUrl || "";
  } else if (info.menuItemId === "dissekt-analyze-page") {
    content = tab.url || "";
  }

  if (!content || content.length < 10) {
    chrome.tabs.sendMessage(tab.id, {
      type: "dissekt-error",
      message: "Select more text to analyze (minimum 10 characters)."
    });
    return;
  }

  // Show loading overlay
  chrome.tabs.sendMessage(tab.id, { type: "dissekt-loading", content: content.slice(0, 100) });

  try {
    const response = await fetch(`${API_URL}/api/scan`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ content, mode: "brief" }),
    });

    if (!response.ok) {
      const err = await response.json();
      throw new Error(err.detail || "Analysis failed");
    }

    const data = await response.json();

    // Store result for popup
    await chrome.storage.local.set({
      lastResult: data,
      lastContent: content.slice(0, 200),
      lastTime: new Date().toISOString()
    });

    // Send result to content script for overlay
    chrome.tabs.sendMessage(tab.id, { type: "dissekt-result", data, content: content.slice(0, 200) });

  } catch (error) {
    chrome.tabs.sendMessage(tab.id, {
      type: "dissekt-error",
      message: error.message || "Analysis failed. Try again."
    });
  }
});

// Handle messages from popup
chrome.runtime.onMessage.addListener((msg, sender, sendResponse) => {
  if (msg.type === "get-last-result") {
    chrome.storage.local.get(["lastResult", "lastContent", "lastTime"], (data) => {
      sendResponse(data);
    });
    return true;
  }
});
BGEOF

# ============================================
# content.js — overlay on the page
# ============================================
cat > dissekt-extension/content.js << 'CSEOF'
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

function showResult(data, content) {
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
    ? '<div class="dissekt-no-fc">No existing fact-checks found</div>'
    : fcs.slice(0, 4).map(fc => {
        const rating = (fc.rating || "").toLowerCase();
        const rColor = rating.includes("false") ? "#dc2626" : rating.includes("true") ? "#16a34a" : "#d97706";
        return `<div class="dissekt-fc">
          <div class="dissekt-fc-pub">${escapeHtml(fc.publisher || "")}</div>
          <div class="dissekt-fc-title">${escapeHtml((fc.title || "").slice(0, 60))}</div>
          <span class="dissekt-fc-badge" style="color:${rColor}">${escapeHtml(fc.rating || "N/A")}</span>
        </div>`;
      }).join("") + (fcs.length > 4 ? `<div class="dissekt-fc-more">+ ${fcs.length - 4} more</div>` : "");

  const reportId = data.id || data.blockchain?.content_hash?.slice(0, 12) || "";

  body.innerHTML = `
    <div class="dissekt-content-preview">${escapeHtml(content)}</div>

    <div class="dissekt-score-row">
      <div class="dissekt-score-circle" style="border-color:${scoreColor}">
        <span class="dissekt-score-num" style="color:${scoreColor}">${score}</span>
      </div>
      <div class="dissekt-score-info">
        <div class="dissekt-score-label" style="color:${scoreColor}">${scoreLabel}</div>
        <div class="dissekt-score-meta">${techs.length} techniques · ${fcs.length} fact-checks · ${(tox * 100).toFixed(1)}% toxicity</div>
      </div>
      <div class="dissekt-score-time">${(data.analysis_time_ms / 1000).toFixed(1)}s</div>
    </div>

    <div class="dissekt-section">
      <div class="dissekt-section-title">👁 Techniques</div>
      ${techsHtml}
    </div>

    ${data.prism?.brief ? `<div class="dissekt-summary">${escapeHtml(data.prism.brief)}</div>` : ""}

    <div class="dissekt-section">
      <div class="dissekt-section-title">🌐 Fact-checks</div>
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
  if (msg.type === "dissekt-result") showResult(msg.data, msg.content);
  if (msg.type === "dissekt-error") showError(msg.message);
});
CSEOF

# ============================================
# content.css — overlay styles
# ============================================
cat > dissekt-extension/content.css << 'CSSEOF'
#dissekt-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.4);
  z-index: 2147483647;
  display: flex;
  align-items: flex-start;
  justify-content: flex-end;
  padding: 16px;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
}

#dissekt-panel {
  width: 380px;
  max-height: calc(100vh - 32px);
  background: #fff;
  border-radius: 14px;
  box-shadow: 0 8px 40px rgba(0,0,0,0.15);
  overflow-y: auto;
  animation: dissekt-slide 0.2s ease;
}

@keyframes dissekt-slide {
  from { transform: translateX(20px); opacity: 0; }
  to { transform: translateX(0); opacity: 1; }
}

#dissekt-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 16px;
  background: #7c3aed;
  border-radius: 14px 14px 0 0;
}

#dissekt-logo {
  display: flex;
  align-items: center;
  gap: 8px;
  color: white;
  font-weight: 600;
  font-size: 14px;
}

#dissekt-close {
  background: none;
  border: none;
  color: rgba(255,255,255,0.7);
  font-size: 20px;
  cursor: pointer;
  padding: 0 4px;
}

#dissekt-close:hover { color: white; }

#dissekt-body { padding: 14px 16px; }

.dissekt-loading-state { text-align: center; padding: 30px 0; }
.dissekt-spinner {
  width: 32px; height: 32px;
  border: 3px solid #f0f0ee;
  border-top-color: #7c3aed;
  border-radius: 50%;
  margin: 0 auto 10px;
  animation: dissekt-spin 0.8s linear infinite;
}
@keyframes dissekt-spin { to { transform: rotate(360deg); } }
.dissekt-loading-text { font-size: 13px; font-weight: 500; color: #404040; }
.dissekt-loading-preview { font-size: 11px; color: #888; margin-top: 6px; max-height: 40px; overflow: hidden; }

.dissekt-content-preview {
  font-size: 11px; color: #888; padding: 8px 10px;
  background: #f5f5f4; border-radius: 8px; margin-bottom: 12px;
  max-height: 48px; overflow: hidden; line-height: 1.5;
}

.dissekt-score-row {
  display: flex; align-items: center; gap: 12px;
  padding: 10px 12px; background: #fff; border: 1px solid #e5e5e5;
  border-radius: 10px; margin-bottom: 12px;
}

.dissekt-score-circle {
  width: 48px; height: 48px; border-radius: 50%;
  border: 3px solid; display: flex; align-items: center;
  justify-content: center; flex-shrink: 0;
}

.dissekt-score-num { font-size: 18px; font-weight: 700; }
.dissekt-score-info { flex: 1; }
.dissekt-score-label { font-size: 12px; font-weight: 700; }
.dissekt-score-meta { font-size: 10px; color: #888; margin-top: 2px; }
.dissekt-score-time { font-size: 10px; color: #aaa; }

.dissekt-section { margin-bottom: 12px; }
.dissekt-section-title { font-size: 12px; font-weight: 600; color: #404040; margin-bottom: 8px; }

.dissekt-tech {
  padding: 8px 10px; border: 1px solid #e5e5e5;
  border-radius: 8px; margin-bottom: 6px;
}
.dissekt-tech-row { display: flex; justify-content: space-between; align-items: center; margin-bottom: 4px; }
.dissekt-tech-name { font-size: 12px; font-weight: 600; }
.dissekt-tech-conf { font-size: 12px; font-weight: 700; }
.dissekt-bar-bg { height: 3px; background: #f0f0ee; border-radius: 2px; margin-bottom: 4px; }
.dissekt-bar { height: 100%; border-radius: 2px; }
.dissekt-tech-exp { font-size: 11px; color: #555; line-height: 1.5; }

.dissekt-clean { font-size: 12px; color: #16a34a; padding: 8px; background: #f0fdf4; border-radius: 8px; }

.dissekt-summary {
  font-size: 11px; color: #404040; line-height: 1.6;
  padding: 8px 10px; background: #faf5ff; border: 1px solid #ede9fe;
  border-radius: 8px; margin-bottom: 12px;
}

.dissekt-fc {
  display: flex; align-items: center; gap: 8px;
  padding: 6px 8px; border: 1px solid #e5e5e5;
  border-radius: 6px; margin-bottom: 4px; font-size: 11px;
}
.dissekt-fc-pub { font-weight: 600; flex-shrink: 0; }
.dissekt-fc-title { flex: 1; color: #555; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.dissekt-fc-badge { font-weight: 600; font-size: 10px; flex-shrink: 0; }
.dissekt-fc-more { font-size: 11px; color: #2563eb; text-align: center; margin-top: 4px; }
.dissekt-no-fc { font-size: 11px; color: #888; }

.dissekt-error { text-align: center; padding: 20px 0; }
.dissekt-error-icon { font-size: 28px; margin-bottom: 8px; }
.dissekt-error-msg { font-size: 13px; color: #404040; margin-bottom: 12px; }

.dissekt-actions {
  display: flex; gap: 8px; margin-top: 12px; padding-top: 12px;
  border-top: 1px solid #e5e5e5;
}

.dissekt-btn-primary {
  flex: 1; text-align: center; padding: 8px 0;
  background: #7c3aed; color: white !important; border-radius: 8px;
  font-size: 12px; font-weight: 600; text-decoration: none;
}

.dissekt-btn-secondary {
  flex: 1; text-align: center; padding: 8px 0;
  background: #fff; color: #7c3aed !important; border: 1px solid #e5e5e5;
  border-radius: 8px; font-size: 12px; font-weight: 500; text-decoration: none;
}

.dissekt-btn-primary:hover { background: #6d28d9; }
.dissekt-btn-secondary:hover { background: #faf5ff; }
CSSEOF

# ============================================
# popup.html — extension popup
# ============================================
cat > dissekt-extension/popup.html << 'POPEOF'
<!DOCTYPE html>
<html>
<head>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { width: 320px; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; }
    .header { background: #7c3aed; padding: 14px 16px; display: flex; align-items: center; gap: 8px; }
    .header svg { flex-shrink: 0; }
    .header span { color: white; font-weight: 600; font-size: 14px; }
    .body { padding: 14px 16px; }
    .empty { text-align: center; padding: 20px 0; color: #888; font-size: 13px; }
    .hint { font-size: 11px; color: #aaa; text-align: center; margin-top: 8px; line-height: 1.5; }
    .last { padding: 10px 12px; background: #f5f5f4; border-radius: 8px; margin-bottom: 10px; }
    .last-label { font-size: 10px; color: #888; text-transform: uppercase; letter-spacing: 0.06em; margin-bottom: 4px; }
    .last-text { font-size: 12px; color: #404040; line-height: 1.5; max-height: 60px; overflow: hidden; }
    .last-time { font-size: 10px; color: #aaa; margin-top: 4px; }
    .btn { display: block; width: 100%; padding: 10px; background: #7c3aed; color: white; border: none; border-radius: 8px; font-size: 13px; font-weight: 600; cursor: pointer; text-align: center; text-decoration: none; }
    .btn:hover { background: #6d28d9; }
    .btn-outline { background: white; color: #7c3aed; border: 1px solid #e5e5e5; margin-top: 8px; }
    .btn-outline:hover { background: #faf5ff; }
  </style>
</head>
<body>
  <div class="header">
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.5"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
    <span>Dissekt</span>
  </div>
  <div class="body" id="content">
    <div class="empty">
      <div style="font-size: 24px; margin-bottom: 8px;">👁</div>
      <div style="font-weight: 500; color: #404040; margin-bottom: 4px;">Select text, then right-click</div>
      <div class="hint">Highlight any text on a webpage, right-click, and choose "Analyze with Dissekt" to see the manipulation playbook.</div>
    </div>
    <a href="https://dissekt.info" target="_blank" class="btn" style="margin-top: 12px;">Open Dissekt</a>
  </div>
  <script src="popup.js"></script>
</body>
</html>
POPEOF

# ============================================
# popup.js — shows last result
# ============================================
cat > dissekt-extension/popup.js << 'PJEOF'
chrome.runtime.sendMessage({ type: "get-last-result" }, (data) => {
  if (!data || !data.lastResult) return;

  const result = data.lastResult;
  const techs = result.prism?.techniques?.length || 0;
  const fcs = result.trace?.fact_checks?.length || 0;
  const maxConf = (result.prism?.techniques || []).reduce((max, t) => Math.max(max, t.confidence || 0), 0);
  let score = (techs > 0 ? Math.round(maxConf * 40) : 0) + Math.min(fcs * 4, 30) + (fcs >= 3 ? 10 : 0);
  score = Math.min(score, 100);
  const scoreColor = score >= 70 ? "#dc2626" : score >= 40 ? "#d97706" : "#16a34a";
  const reportId = result.id || result.blockchain?.content_hash?.slice(0, 12) || "";

  const time = data.lastTime ? new Date(data.lastTime).toLocaleString(undefined, {
    month: "short", day: "numeric", hour: "2-digit", minute: "2-digit"
  }) : "";

  document.getElementById("content").innerHTML = `
    <div class="last">
      <div class="last-label">Last analysis</div>
      <div class="last-text">${escapeHtml(data.lastContent || "")}</div>
      <div class="last-time">${time}</div>
    </div>
    <div style="display:flex;align-items:center;gap:10px;margin-bottom:12px;padding:8px 10px;border:1px solid #e5e5e5;border-radius:8px;">
      <div style="width:36px;height:36px;border-radius:50%;border:3px solid ${scoreColor};display:flex;align-items:center;justify-content:center;">
        <span style="font-size:14px;font-weight:700;color:${scoreColor}">${score}</span>
      </div>
      <div>
        <div style="font-size:12px;font-weight:600;color:${scoreColor}">${score >= 70 ? "HIGH RISK" : score >= 40 ? "MEDIUM" : "LOW RISK"}</div>
        <div style="font-size:10px;color:#888">${techs} techniques · ${fcs} fact-checks</div>
      </div>
    </div>
    <a href="https://dissekt.info/report/${reportId}" target="_blank" class="btn">View full report →</a>
    <a href="https://dissekt.info" target="_blank" class="btn btn-outline">Open Dissekt</a>
  `;
});

function escapeHtml(str) {
  const div = document.createElement("div");
  div.textContent = str;
  return div.innerHTML;
}
PJEOF

# ============================================
# Generate simple SVG icons
# ============================================
python3 << 'ICONEOF'
import struct, zlib

def create_png(size, bg_color=(124, 58, 237)):
    """Create a simple purple shield icon as PNG."""
    width = height = size

    def make_pixel_data():
        rows = []
        for y in range(height):
            row = b'\x00'  # filter byte
            for x in range(width):
                # Simple shield shape
                cx, cy = width // 2, height // 2
                # Shield body
                dx = abs(x - cx) / (width * 0.35)
                dy = (y - height * 0.2) / (height * 0.65)
                in_shield = dx < 1 and 0 < dy < 1 and dx + dy * 0.3 < 1.1

                if in_shield:
                    row += bytes(bg_color) + b'\xff'
                else:
                    row += b'\x00\x00\x00\x00'
            rows.append(row)
        return b''.join(rows)

    pixel_data = make_pixel_data()
    compressed = zlib.compress(pixel_data)

    def chunk(chunk_type, data):
        c = chunk_type + data
        return struct.pack('>I', len(data)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)

    ihdr = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)
    png = b'\x89PNG\r\n\x1a\n'
    png += chunk(b'IHDR', ihdr)
    png += chunk(b'IDAT', compressed)
    png += chunk(b'IEND', b'')
    return png

for size in [16, 48, 128]:
    with open(f'dissekt-extension/icons/icon{size}.png', 'wb') as f:
        f.write(create_png(size))

print('✅ Icons generated')
ICONEOF

echo ""
echo "✅ Chrome extension created at dissekt-extension/"
echo ""
echo "To install:"
echo "  1. Open Chrome → chrome://extensions/"
echo "  2. Enable 'Developer mode' (top right)"
echo "  3. Click 'Load unpacked'"
echo "  4. Select the dissekt-extension/ folder"
echo ""
echo "To test:"
echo "  1. Go to any news article"
echo "  2. Select some text"
echo "  3. Right-click → 'Analyze with Dissekt'"
echo "  4. See results in slide-out panel"
echo ""
echo "Also works with:"
echo "  - Right-click a link → 'Analyze this link'"
echo "  - Right-click page → 'Analyze this page'"
echo "  - Click extension icon → see last analysis + open Dissekt"
