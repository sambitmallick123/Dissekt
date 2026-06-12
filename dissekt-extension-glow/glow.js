(function() {
  const API = 'https://dissekt-api.up.railway.app';
  
  // Only run on article-like pages
  const article = document.querySelector('article') || document.querySelector('[role="article"]') || document.querySelector('.post-content, .article-body, .entry-content, .story-body');
  if (!article) return;
  
  const text = article.innerText;
  if (!text || text.length < 200) return;

  // Keyword patterns for passive detection (no API call needed)
  const patterns = {
    loaded: /\b(shocking|devastating|explosive|outrageous|disgusting|horrifying|sickening|unbelievable|terrifying|alarming)\b/gi,
    emotional: /\b(heartbreaking|tragic|beautiful|wonderful|amazing|terrible|horrible|incredible|unacceptable|shameful)\b/gi,
    authority: /\b(experts say|studies show|scientists confirm|officials report|according to sources|research proves|data shows)\b/gi,
    missing: /\b(always|never|everyone|nobody|all|none|completely|totally|absolutely|impossible|undeniable)\b/gi,
  };

  const classMap = { loaded: 'dissekt-glow-loaded', emotional: 'dissekt-glow-emotional', authority: 'dissekt-glow-authority', missing: 'dissekt-glow-missing' };
  const labelMap = { loaded: 'Loaded language', emotional: 'Emotional framing', authority: 'Appeal to authority', missing: 'Absolute language (possible missing context)' };

  // Walk text nodes and highlight matches
  const walker = document.createTreeWalker(article, NodeFilter.SHOW_TEXT, null);
  const nodes = [];
  while (walker.nextNode()) nodes.push(walker.currentNode);

  let totalHighlights = 0;

  nodes.forEach(node => {
    const parent = node.parentElement;
    if (!parent || parent.tagName === 'SCRIPT' || parent.tagName === 'STYLE' || parent.classList.contains('dissekt-glow-loaded')) return;

    let html = node.textContent;
    let changed = false;

    for (const [type, regex] of Object.entries(patterns)) {
      const cls = classMap[type];
      const label = labelMap[type];
      html = html.replace(regex, (match) => {
        changed = true;
        totalHighlights++;
        return `<span class="${cls}" data-dissekt-tip="${label}: '${match}'">${match}</span>`;
      });
    }

    if (changed) {
      const span = document.createElement('span');
      span.innerHTML = html;
      parent.replaceChild(span, node);
    }
  });

  if (totalHighlights === 0) return;

  // Add floating bar
  const bar = document.createElement('div');
  bar.className = 'dissekt-glow-bar';
  bar.innerHTML = `<div style="width:20px;height:20px;background:#0d9488;border-radius:5px;display:flex;align-items:center;justify-content:center"><svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.5"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg></div><span>${totalHighlights} signals</span><a href="https://dissekt.info/analyze?url=${encodeURIComponent(window.location.href)}" target="_blank" style="color:#0d9488;text-decoration:none;font-weight:600;font-size:11px;">Full analysis →</a>`;
  document.body.appendChild(bar);

  // Tooltip on hover
  let tooltip = null;
  document.addEventListener('mouseover', (e) => {
    const el = e.target.closest('[data-dissekt-tip]');
    if (el) {
      if (!tooltip) {
        tooltip = document.createElement('div');
        tooltip.className = 'dissekt-glow-tooltip';
        document.body.appendChild(tooltip);
      }
      tooltip.textContent = el.getAttribute('data-dissekt-tip');
      const rect = el.getBoundingClientRect();
      tooltip.style.top = (rect.top + window.scrollY - 30) + 'px';
      tooltip.style.left = rect.left + 'px';
      tooltip.style.display = 'block';
    } else if (tooltip) {
      tooltip.style.display = 'none';
    }
  });
})();
