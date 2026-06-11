import jsPDF from 'jspdf';

export function downloadPDF(data: any, inputContent: string) {
  const doc = new jsPDF({ orientation: 'portrait', unit: 'mm', format: 'a4' });
  const W = 210;
  const M = 16;
  const CW = W - M * 2;
  let y = M;

  const purple = [124, 58, 237];
  const red = [220, 38, 38];
  const blue = [37, 99, 235];
  const amber = [217, 119, 6];
  const green = [5, 150, 105];
  const gray = [120, 120, 120];
  const dark = [40, 40, 40];
  const black = [26, 26, 26];
  const bgLight = [245, 245, 244];
  const white = [255, 255, 255];

  const newPageIfNeeded = (need: number) => {
    if (y + need > 275) { doc.addPage(); y = M; }
  };

  const setColor = (c: number[]) => doc.setTextColor(c[0], c[1], c[2]);
  const fillRect = (x: number, yy: number, w: number, h: number, c: number[]) => {
    doc.setFillColor(c[0], c[1], c[2]); doc.rect(x, yy, w, h, 'F');
  };
  const fillRound = (x: number, yy: number, w: number, h: number, r: number, c: number[]) => {
    doc.setFillColor(c[0], c[1], c[2]); doc.roundedRect(x, yy, w, h, r, r, 'F');
  };
  const drawBorder = (x: number, yy: number, w: number, h: number) => {
    doc.setDrawColor(220, 220, 220); doc.roundedRect(x, yy, w, h, 2, 2, 'S');
  };
  const sectionHeader = (label: string, color: number[], right?: string) => {
    newPageIfNeeded(12);
    setColor(color);
    doc.setFontSize(9); doc.setFont('helvetica', 'bold');
    doc.text(label, M, y);
    if (right) { setColor(gray); doc.setFont('helvetica', 'normal'); doc.text(right, W - M, y, { align: 'right' }); }
    y += 2;
    doc.setDrawColor(color[0], color[1], color[2]); doc.setLineWidth(0.5);
    doc.line(M, y, W - M, y);
    y += 5;
  };

  // ========= HEADER =========
  fillRect(0, 0, W, 32, purple);
  setColor(white); doc.setFontSize(22); doc.setFont('helvetica', 'bold');
  doc.text('DISSEKT', M, 14);
  doc.setFontSize(9); doc.setFont('helvetica', 'normal');
  doc.text('Threat Intelligence Report', M, 20);
  doc.setFontSize(8);
  const dateStr = new Date().toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' });
  const timeStr = new Date().toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit' });
  doc.text(`${dateStr} at ${timeStr}`, W - M, 14, { align: 'right' });
  doc.text(`Model: ${data.prism?.model_used || 'N/A'} · Time: ${(data.analysis_time_ms / 1000).toFixed(1)}s · Cache: ${data.cached ? 'Hit' : 'Fresh'}`, W - M, 20, { align: 'right' });
  y = 40;

  // ========= ANALYZED CONTENT =========
  sectionHeader('ANALYZED CONTENT', dark);
  fillRound(M, y, CW, 14, 2, bgLight);
  setColor(dark); doc.setFontSize(9); doc.setFont('helvetica', 'normal');
  const inputLines = doc.splitTextToSize(inputContent || data.extracted_text || 'N/A', CW - 8);
  doc.text(inputLines.slice(0, 3), M + 4, y + 5);
  if (inputLines.length > 3) { setColor(gray); doc.text(`... (${inputContent.length} characters total)`, M + 4, y + 11); }
  y += 18;

  // ========= THREAT SCORE =========
  const techniques = data.prism?.techniques || [];
  const fcs = data.trace?.fact_checks || [];
  const tl = data.trace?.spread_timeline || [];
  const tox = data.signal?.toxicity_score || 0;
  const maxConf = techniques.reduce((max: number, t: any) => Math.max(max, t.confidence || 0), 0);
  let score = (techniques.length > 0 ? Math.round(maxConf * 40) : 0) + Math.min(fcs.length * 4, 30) + Math.round(tox * 20) + (fcs.length >= 3 ? 10 : 0);
  score = Math.min(score, 100);
  const scoreColor = score >= 70 ? red : score >= 40 ? amber : green;
  const scoreLabel = score >= 70 ? 'LOW TRANSPARENCY' : score >= 40 ? 'MODERATE' : 'HIGH TRANSPARENCY';

  newPageIfNeeded(22);
  fillRound(M, y, CW, 18, 2, white); drawBorder(M, y, CW, 18);

  // Score circle
  doc.setFillColor(scoreColor[0], scoreColor[1], scoreColor[2]);
  doc.circle(M + 12, y + 9, 8, 'F');
  setColor(white); doc.setFontSize(14); doc.setFont('helvetica', 'bold');
  doc.text(String(score), M + 12, y + 11.5, { align: 'center' });

  // Score text
  setColor(scoreColor); doc.setFontSize(12);
  doc.text(scoreLabel, M + 26, y + 8);
  setColor(gray); doc.setFontSize(8); doc.setFont('helvetica', 'normal');
  doc.text(`${techniques.length} techniques · ${fcs.length} fact-checks · ${tl.length} sources · Toxicity ${(tox * 100).toFixed(1)}%`, M + 26, y + 14);

  const mode = (data.prism?.model_used || '').includes('gpt') ? 'BRIEF' : 'DETAILED';
  fillRound(W - M - 18, y + 5, 16, 7, 2, purple);
  setColor(white); doc.setFontSize(7); doc.setFont('helvetica', 'bold');
  doc.text(mode, W - M - 10, y + 10, { align: 'center' });
  y += 24;

  // ========= PRISM — ALL TECHNIQUES =========
  sectionHeader('PRISM — MANIPULATION TECHNIQUES', purple, `${techniques.length} found`);

  if (techniques.length === 0) {
    fillRound(M, y, CW, 10, 2, [240, 253, 244]);
    setColor(green); doc.setFontSize(9); doc.text('✓ No manipulation techniques detected', M + 4, y + 7);
    y += 14;
  } else {
    techniques.forEach((t: any, idx: number) => {
      newPageIfNeeded(30);
      const conf = Math.round((t.confidence || 0) * 100);
      const confColor = conf >= 85 ? red : conf >= 70 ? amber : [234, 179, 8];

      fillRound(M, y, CW, 4, 0, white); drawBorder(M, y, CW, 4);

      // Name + confidence header
      setColor(black); doc.setFontSize(10); doc.setFont('helvetica', 'bold');
      const techName = (t.name || '').replace(/_/g, ' ').replace(/\b\w/g, (c: string) => c.toUpperCase());
      doc.text(`${idx + 1}. ${techName}`, M + 4, y + 6);

      setColor(confColor); doc.setFontSize(11);
      doc.text(`${conf}%`, W - M - 4, y + 6, { align: 'right' });

      y += 9;

      // Confidence bar
      fillRound(M + 4, y, CW - 8, 2.5, 1, bgLight);
      fillRound(M + 4, y, (CW - 8) * (t.confidence || 0), 2.5, 1, confColor);
      y += 5;

      // Category
      setColor(purple); doc.setFontSize(7); doc.setFont('helvetica', 'bold');
      doc.text(`Category: ${(t.category || 'framing').replace(/_/g, ' ').toUpperCase()}`, M + 4, y + 2);
      y += 5;

      // Full explanation
      if (t.explanation) {
        setColor(dark); doc.setFontSize(8); doc.setFont('helvetica', 'normal');
        const expLines = doc.splitTextToSize(t.explanation, CW - 8);
        expLines.forEach((line: string) => {
          newPageIfNeeded(5);
          doc.text(line, M + 4, y + 2);
          y += 4;
        });
      }

      // Evidence quote
      if (t.evidence) {
        newPageIfNeeded(8);
        fillRound(M + 4, y, CW - 8, 8, 1, [255, 251, 235]);
        doc.setDrawColor(254, 215, 170); doc.line(M + 4, y, M + 4, y + 8);
        setColor(gray); doc.setFontSize(8); doc.setFont('helvetica', 'italic');
        const evLines = doc.splitTextToSize(`"${t.evidence}"`, CW - 14);
        doc.text(evLines.slice(0, 2), M + 8, y + 4);
        y += 10;
      }

      y += 4;
    });
  }

  // Brief summary
  if (data.prism?.brief) {
    newPageIfNeeded(18);
    fillRound(M, y, CW, 4, 2, [250, 245, 255]);
    setColor(purple); doc.setFontSize(7); doc.setFont('helvetica', 'bold');
    doc.text('SUMMARY', M + 4, y + 5);
    y += 8;
    setColor(dark); doc.setFontSize(8); doc.setFont('helvetica', 'normal');
    const briefLines = doc.splitTextToSize(data.prism.brief, CW - 8);
    briefLines.forEach((line: string) => {
      newPageIfNeeded(5);
      doc.text(line, M + 4, y);
      y += 4;
    });
    y += 4;
  }

  // Detailed analysis
  if (data.prism?.detailed) {
    newPageIfNeeded(14);
    setColor(purple); doc.setFontSize(7); doc.setFont('helvetica', 'bold');
    doc.text('DETAILED ANALYSIS', M + 4, y);
    y += 5;
    setColor(dark); doc.setFontSize(8); doc.setFont('helvetica', 'normal');
    const detLines = doc.splitTextToSize(data.prism.detailed, CW - 8);
    detLines.forEach((line: string) => {
      newPageIfNeeded(5);
      doc.text(line, M + 4, y);
      y += 4;
    });
    y += 4;
  }

  // ========= TRACE — ALL FACT-CHECKS =========
  sectionHeader('TRACE — FACT-CHECKS', blue, `${fcs.length} checks · ${tl.length} sources`);

  if (fcs.length > 0) {
    // Table header
    fillRound(M, y, CW, 6, 1, bgLight);
    setColor(gray); doc.setFontSize(7); doc.setFont('helvetica', 'bold');
    doc.text('PUBLISHER', M + 4, y + 4);
    doc.text('TITLE', M + 40, y + 4);
    doc.text('RATING', W - M - 4, y + 4, { align: 'right' });
    y += 8;

    // ALL fact-checks (no limit)
    fcs.forEach((fc: any, i: number) => {
      newPageIfNeeded(8);
      if (i % 2 === 0) fillRound(M, y - 1, CW, 7, 0.5, [252, 252, 251]);

      setColor(black); doc.setFontSize(8); doc.setFont('helvetica', 'bold');
      doc.text((fc.publisher || '').slice(0, 18), M + 4, y + 4);

      doc.setFont('helvetica', 'normal'); setColor(dark);
      const title = (fc.title || '').slice(0, 60) + ((fc.title || '').length > 60 ? '...' : '');
      doc.text(title, M + 40, y + 4);

      const rating = (fc.rating || '').toLowerCase();
      const rColor = rating.includes('false') ? red : rating.includes('true') ? green : amber;
      setColor(rColor); doc.setFont('helvetica', 'bold'); doc.setFontSize(7);
      doc.text((fc.rating || 'N/A').toUpperCase(), W - M - 4, y + 4, { align: 'right' });

      // URL
      if (fc.url) {
        setColor([150, 150, 250]); doc.setFontSize(6); doc.setFont('helvetica', 'normal');
        doc.text(fc.url.slice(0, 80), M + 40, y + 7.5);
      }

      y += fc.url ? 10 : 7;
    });
  } else {
    setColor(gray); doc.setFontSize(9); doc.text('No existing fact-checks found.', M, y + 4);
    y += 8;
  }

  // Spread timeline
  if (tl.length > 0) {
    y += 4;
    newPageIfNeeded(12);
    setColor(blue); doc.setFontSize(8); doc.setFont('helvetica', 'bold');
    doc.text('SPREAD TIMELINE', M, y);
    y += 5;

    tl.forEach((s: any) => {
      newPageIfNeeded(8);
      setColor(dark); doc.setFontSize(8); doc.setFont('helvetica', 'bold');
      doc.text(`• ${s.platform || 'Web'}`, M + 4, y + 3);
      doc.setFont('helvetica', 'normal'); setColor(gray);
      const stitle = (s.title || '').slice(0, 70) + ((s.title || '').length > 70 ? '...' : '');
      doc.text(stitle, M + 25, y + 3);
      if (s.date) doc.text(s.date, W - M - 4, y + 3, { align: 'right' });
      if (s.url) {
        setColor([150, 150, 250]); doc.setFontSize(6);
        doc.text(s.url.slice(0, 90), M + 25, y + 6.5);
      }
      y += s.url ? 9 : 6;
    });
  }

  y += 4;

  // ========= SIGNAL — FULL CREDIBILITY =========
  sectionHeader('SIGNAL — SOURCE CREDIBILITY & SENTIMENT', amber);

  const signals = [
    { l: 'Source Bias', v: data.signal?.source_bias || 'Unknown' },
    { l: 'Factuality', v: data.signal?.source_factuality || 'Unknown' },
    { l: 'Sentiment', v: `${data.signal?.sentiment || 'neutral'} (${(data.signal?.sentiment_score || 0).toFixed(2)})` },
    { l: 'Toxicity', v: `${(tox * 100).toFixed(1)}%` },
  ];

  newPageIfNeeded(18);
  const cellW = CW / 4;
  fillRound(M, y, CW, 14, 2, white); drawBorder(M, y, CW, 14);
  signals.forEach((s, i) => {
    const cx = M + cellW * i + 4;
    setColor(gray); doc.setFontSize(7); doc.setFont('helvetica', 'bold');
    doc.text(s.l.toUpperCase(), cx, y + 5);
    setColor(dark); doc.setFontSize(9); doc.setFont('helvetica', 'normal');
    doc.text(String(s.v), cx, y + 11);
  });
  y += 18;

  // Toxicity breakdown
  if (data.signal?.toxicity_labels && Object.keys(data.signal.toxicity_labels).length > 0) {
    newPageIfNeeded(20);
    setColor(amber); doc.setFontSize(8); doc.setFont('helvetica', 'bold');
    doc.text('TOXICITY BREAKDOWN', M, y);
    y += 5;

    Object.entries(data.signal.toxicity_labels).forEach(([k, v]: [string, any]) => {
      newPageIfNeeded(6);
      setColor(dark); doc.setFontSize(8); doc.setFont('helvetica', 'normal');
      doc.text(k.replace(/_/g, ' '), M + 4, y + 3);

      // Mini bar
      fillRound(M + 40, y + 0.5, 40, 2.5, 1, bgLight);
      const barColor = v > 0.5 ? red : v > 0.2 ? amber : [200, 200, 200];
      fillRound(M + 40, y + 0.5, Math.max(40 * v, 1), 2.5, 1, barColor);

      setColor(dark); doc.setFont('helvetica', 'bold');
      doc.text(`${(v * 100).toFixed(1)}%`, M + 84, y + 3);
      y += 5;
    });
    y += 4;
  }

  // ========= METADATA & BLOCKCHAIN =========
  sectionHeader('METADATA & EVIDENCE CHAIN', dark);
  newPageIfNeeded(24);

  fillRound(M, y, CW, 22, 2, bgLight);
  setColor(dark); doc.setFontSize(8); doc.setFont('helvetica', 'normal');
  doc.text(`Analysis time: ${(data.analysis_time_ms / 1000).toFixed(1)}s`, M + 4, y + 5);
  doc.text(`Model: ${data.prism?.model_used || 'N/A'}`, M + 55, y + 5);
  doc.text(`Cache: ${data.cached ? 'Hit' : 'Fresh'}`, M + 105, y + 5);
  doc.text(`Heuristic only: ${data.prism?.heuristic_only ? 'Yes (€0)' : 'No'}`, M + 135, y + 5);

  setColor(gray); doc.setFontSize(7); doc.setFont('helvetica', 'bold');
  doc.text('SHA-256 CONTENT HASH', M + 4, y + 12);
  doc.setFont('courier', 'normal'); setColor(dark); doc.setFontSize(7);
  doc.text(data.blockchain?.content_hash || 'N/A', M + 4, y + 16);

  setColor(gray); doc.setFont('helvetica', 'bold');
  doc.text('PROOF STATUS', M + 4, y + 20);
  setColor(dark); doc.setFont('helvetica', 'normal');
  doc.text(data.blockchain?.proof_status || 'pending', M + 30, y + 20);

  y += 28;

  // ========= FOOTER ON ALL PAGES =========
  const pages = doc.getNumberOfPages();
  for (let i = 1; i <= pages; i++) {
    doc.setPage(i);
    doc.setDrawColor(200, 200, 200); doc.line(M, 287, W - M, 287);
    setColor(gray); doc.setFontSize(7); doc.setFont('helvetica', 'normal');
    doc.text('Generated by Dissekt — https://dissekt.info', M, 292);
    doc.text('Explanation, not verdicts.', W / 2, 292, { align: 'center' });
    doc.text(`Page ${i} of ${pages}`, W - M, 292, { align: 'right' });
  }

  const ts = new Date().toISOString().slice(0, 16).replace(/[T:]/g, '-');
  doc.save(`dissekt-report-${ts}.pdf`);
}
