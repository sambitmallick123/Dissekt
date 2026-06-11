// Dissekt Embeddable Badge
// Usage: <script src="https://dissekt.info/badge.js" data-url="ARTICLE_URL"></script>
(function() {
  var script = document.currentScript;
  var url = script.getAttribute('data-url') || window.location.href;
  var apiBase = 'https://dissekt-api.up.railway.app';

  var container = document.createElement('div');
  container.id = 'dissekt-badge';
  container.style.cssText = 'display:inline-flex;align-items:center;gap:8px;padding:6px 12px;border-radius:8px;border:1px solid #e5eaea;background:#fff;font-family:-apple-system,sans-serif;font-size:12px;cursor:pointer;';
  container.innerHTML = '<div style="width:20px;height:20px;background:#0d9488;border-radius:5px;display:flex;align-items:center;justify-content:center"><svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.5"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg></div><span style="color:#888">Analyzing...</span>';
  
  script.parentNode.insertBefore(container, script.nextSibling);

  fetch(apiBase + '/api/scan', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ content: url, mode: 'brief' })
  })
  .then(function(r) { return r.json(); })
  .then(function(data) {
    var techs = (data.prism && data.prism.techniques) || [];
    var maxConf = techs.reduce(function(m, t) { return Math.max(m, t.confidence || 0); }, 0);
    var raw = Math.min(
      (techs.length > 0 ? Math.round(maxConf * 40) : 0) +
      Math.min(((data.trace && data.trace.fact_checks) || []).length * 4, 30) +
      Math.round(((data.signal && data.signal.toxicity_score) || 0) * 20),
      100
    );
    var score = 100 - raw;
    var color = score <= 30 ? '#dc2626' : score <= 60 ? '#d97706' : '#16a34a';
    var label = score <= 30 ? 'Low' : score <= 60 ? 'Moderate' : 'High';

    container.innerHTML = '<div style="width:20px;height:20px;background:#0d9488;border-radius:5px;display:flex;align-items:center;justify-content:center"><svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.5"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg></div><span style="font-weight:600;color:' + color + '">' + score + '</span><span style="color:#888">' + label + ' transparency</span><span style="color:#0d9488;font-size:10px">by Dissekt</span>';
    container.onclick = function() { window.open('https://dissekt.info/analyze?url=' + encodeURIComponent(url), '_blank'); };
  })
  .catch(function() {
    container.innerHTML = '<div style="width:20px;height:20px;background:#0d9488;border-radius:5px;display:flex;align-items:center;justify-content:center"><svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.5"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg></div><span style="color:#888">Dissekt</span>';
    container.onclick = function() { window.open('https://dissekt.info', '_blank'); };
  });
})();
