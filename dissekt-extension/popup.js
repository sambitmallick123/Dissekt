chrome.runtime.sendMessage({ type: "get-last-result" }, (data) => {
  if (!data || !data.lastResult) return;

  const result = data.lastResult;
  const techs = result.prism?.techniques?.length || 0;
  const fcs = result.trace?.fact_checks?.length || 0;
  const maxConf = (result.prism?.techniques || []).reduce((max, t) => Math.max(max, t.confidence || 0), 0);
  let score = (techs > 0 ? Math.round(maxConf * 40) : 0) + Math.min(fcs * 4, 30) + (fcs >= 3 ? 10 : 0);
  score = Math.min(score, 100);
  const scoreColor = score >= 70 ? "#dc2626" : score >= 40 ? "#d97706" : "#16a34a";
  const reportId = data.lastReportId || result.id || result.blockchain?.content_hash?.slice(0, 12) || "";

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
