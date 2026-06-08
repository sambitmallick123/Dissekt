const API_URL = "https://dissekt-api.up.railway.app";
const WEB_URL = "https://dissekt.info";

// Create context menus on install
chrome.runtime.onInstalled.addListener(() => {
  chrome.contextMenus.create({
    id: "dissekt-analyze",
    title: "🛡️ Analyze with Dissekt",
    contexts: ["selection"]
  });

  chrome.contextMenus.create({
    id: "dissekt-analyze-link",
    title: "🛡️ Analyze this link with Dissekt",
    contexts: ["link"]
  });

  chrome.contextMenus.create({
    id: "dissekt-analyze-page",
    title: "🛡️ Analyze this page with Dissekt",
    contexts: ["page"]
  });
});

// Save report to Supabase via the web app
async function saveReport(data, content) {
  const reportId = data.id || data.blockchain?.content_hash?.slice(0, 12) || Date.now().toString(36);
  try {
    await fetch(`${WEB_URL}/api/report`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        id: reportId,
        analysis: data,
        input_content: (content || "").slice(0, 500),
        mode: "brief"
      }),
    });
  } catch (e) {
    console.warn("Report save failed:", e);
  }
  return reportId;
}

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
    try {
      chrome.tabs.sendMessage(tab.id, {
        type: "dissekt-error",
        message: "Select more text to analyze (minimum 10 characters)."
      });
    } catch (e) {}
    return;
  }

  // Show loading overlay
  try {
    chrome.tabs.sendMessage(tab.id, { type: "dissekt-loading", content: content.slice(0, 100) });
  } catch (e) {}

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

    // Save report to Supabase so "Full report" link works
    const reportId = await saveReport(data, content);

    // Store result for popup
    await chrome.storage.local.set({
      lastResult: data,
      lastContent: content.slice(0, 200),
      lastTime: new Date().toISOString(),
      lastReportId: reportId
    });

    // Send result to content script
    try {
      chrome.tabs.sendMessage(tab.id, {
        type: "dissekt-result",
        data,
        content: content.slice(0, 200),
        reportId
      });
    } catch (e) {}

  } catch (error) {
    try {
      chrome.tabs.sendMessage(tab.id, {
        type: "dissekt-error",
        message: error.message || "Analysis failed. Try again."
      });
    } catch (e) {}
  }
});

// Handle messages from popup
chrome.runtime.onMessage.addListener((msg, sender, sendResponse) => {
  if (msg.type === "get-last-result") {
    chrome.storage.local.get(["lastResult", "lastContent", "lastTime", "lastReportId"], (data) => {
      sendResponse(data);
    });
    return true;
  }
});
