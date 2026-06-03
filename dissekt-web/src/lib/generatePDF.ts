import jsPDF from 'jspdf';

interface AnalysisData {
  prism: any;
  trace: any;
  signal: any;
  blockchain: any;
  analysis_time_ms: number;
  cached: boolean;
  extracted_text?: string;
}

export function generateAnalysisPDF(data: AnalysisData, inputContent: string) {
  const doc = new jsPDF({ orientation: 'portrait', unit: 'mm', format: 'a4' });
  const W = 210;
  const margin = 18;
  const contentW = W - margin * 2;
  let y = margin;

  const purple = [124, 58, 237];
  const red = [220, 38, 38];
  const blue = [37, 99, 235];
  const amber = [217, 119, 6];
  const green = [5, 150, 105];
  const gray = [136, 136, 136];
  const darkGray = [64, 64, 64];
  const black = [26, 26, 26];
  const lightBg = [245, 245, 244];

  // Helper: add new page if needed
  const checkPage = (needed: number) => {
    if (y + needed > 280) { doc.addPage(); y = margin; }
  };

  // Helper: draw colored rectangle
  const drawRect = (x: number, yPos: number, w: number, h: number, color: number[], fill = true) => {
    doc.setFillColor(color[0], color[1], color[2]);
    if (fill) doc.rect(x, yPos, w, h, 'F');
  };

  // Helper: draw rounded rect
  const drawRoundRect = (x: number, yPos: number, w: number, h: number, r: number, color: number[]) => {
    doc.setFillColor(color[0], color[1], color[2]);
    doc.roundedRect(x, yPos, w, h, r, r, 'F');
  };

  // ========== HEADER ==========
  drawRect(0, 0, W, 36, purple);
  doc.setTextColor(255, 255, 255);
  doc.setFontSize(20);
  doc.setFont('helvetica', 'bold');
  doc.text('DISSEKT', margin, 16);
  doc.setFontSize(9);
  doc.setFont('helvetica', 'normal');
  doc.text('Threat Intelligence Report', margin, 23);
  doc.setFontSize(8);
  doc.text(new Date().toLocaleString('en-GB', { dateStyle: 'full', timeStyle: 'short' }), W - margin, 16, { align: 'right' });
  doc.text(`Analysis time: ${(data.analysis_time_ms / 1000).toFixed(1)}s · Model: ${data.prism?.model_used || 'N/A'}`, W - margin, 23, { align: 'right' });
  y = 44;

  // ========== INPUT CONTENT ==========
  doc.setTextColor(gray[0], gray[1], gray[2]);
  doc.setFontSize(8);
  doc.setFont('helvetica', 'bold');
  doc.text('ANALYZED CONTENT', margin, y);
  y += 5;
  drawRoundRect(margin, y, contentW, 16, 2, lightBg);
  doc.setTextColor(darkGray[0], darkGray[1], darkGray[2]);
  doc.setFontSize(9);
  doc.setFont('helvetica', 'normal');
  const truncated = inputContent.length > 200 ? inputContent.slice(0, 200) + '...' : inputContent;
  const inputLines = doc.splitTextToSize(truncated, contentW - 8);
  doc.text(inputLines.slice(0, 2), margin + 4, y + 6);
  y += 22;

  // ========== THREAT SCORE ==========
  const techniques = data.prism?.techniques?.length || 0;
  const fcs = data.trace?.fact_checks?.length || 0;
  const tox = data.signal?.toxicity_score || 0;
  const maxConf = data.prism?.techniques?.reduce((max: number, t: any) => Math.max(max, t.confidence || 0), 0) || 0;
  let score = (techniques > 0 ? Math.round(maxConf * 40) : 0) + Math.min(fcs * 4, 30) + Math.round(tox * 20) + (fcs >= 3 ? 10 : 0);
  score = Math.min(score, 100);
  const scoreColor = score >= 70 ? red : score >= 40 ? amber : green;
  const scoreLabel = score >= 70 ? 'HIGH RISK' : score >= 40 ? 'MEDIUM RISK' : 'LOW RISK';

  drawRoundRect(margin, y, contentW, 24, 2, [255, 255, 255]);
  doc.setDrawColor(230, 230, 230);
  doc.roundedRect(margin, y, contentW, 24, 2, 2, 'S');

  // Score circle
  doc.setFillColor(scoreColor[0], scoreColor[1], scoreColor[2]);
  doc.circle(margin + 14, y + 12, 10, 'F');
  doc.setTextColor(255, 255, 255);
  doc.setFontSize(14);
  doc.setFont('helvetica', 'bold');
  doc.text(String(score), margin + 14, y + 14.5, { align: 'center' });

  // Score label
  doc.setTextColor(scoreColor[0], scoreColor[1], scoreColor[2]);
  doc.setFontSize(11);
  doc.text(scoreLabel, margin + 30, y + 10);
  doc.setTextColor(gray[0], gray[1], gray[2]);
  doc.setFontSize(8);
  doc.setFont('helvetica', 'normal');
  doc.text(`${techniques} technique${techniques !== 1 ? 's' : ''} · ${fcs} fact-check${fcs !== 1 ? 's' : ''} · Toxicity ${(tox * 100).toFixed(1)}%`, margin + 30, y + 16);

  // Mode badge
  const mode = data.prism?.model_used?.includes('gpt') ? 'BRIEF' : 'DETAILED';
  const badgeX = W - margin - 22;
  drawRoundRect(badgeX, y + 7, 20, 8, 2, purple);
  doc.setTextColor(255, 255, 255);
  doc.setFontSize(7);
  doc.setFont('helvetica', 'bold');
  doc.text(mode, badgeX + 10, y + 12.5, { align: 'center' });

  y += 30;

  // ========== PRISM — TECHNIQUES ==========
  checkPage(40);
  doc.setTextColor(purple[0], purple[1], purple[2]);
  doc.setFontSize(8);
  doc.setFont('helvetica', 'bold');
  doc.text('PRISM — MANIPULATION TECHNIQUES', margin, y);
  doc.setTextColor(gray[0], gray[1], gray[2]);
  doc.setFont('helvetica', 'normal');
  doc.text(`${techniques} found`, W - margin, y, { align: 'right' });
  y += 5;

  if (data.prism?.techniques?.length > 0) {
    data.prism.techniques.forEach((t: any) => {
      checkPage(28);
      drawRoundRect(margin, y, contentW, 22, 2, [255, 255, 255]);
      doc.setDrawColor(230, 230, 230);
      doc.roundedRect(margin, y, contentW, 22, 2, 2, 'S');

      // Technique name + confidence
      doc.setTextColor(black[0], black[1], black[2]);
      doc.setFontSize(10);
      doc.setFont('helvetica', 'bold');
      const techName = t.name.replace(/_/g, ' ').replace(/\b\w/g, (c: string) => c.toUpperCase());
      doc.text(techName, margin + 4, y + 6);

      const conf = Math.round(t.confidence * 100);
      const confColor = conf >= 85 ? red : conf >= 70 ? amber : [234, 179, 8];
      doc.setTextColor(confColor[0], confColor[1], confColor[2]);
      doc.setFontSize(11);
      doc.text(`${conf}%`, W - margin - 4, y + 6, { align: 'right' });

      // Confidence bar
      drawRoundRect(margin + 4, y + 9, contentW - 8, 2.5, 1, lightBg);
      drawRoundRect(margin + 4, y + 9, (contentW - 8) * t.confidence, 2.5, 1, confColor);

      // Category badge
      doc.setFontSize(7);
      doc.setTextColor(purple[0], purple[1], purple[2]);
      doc.text((t.category || 'framing').replace(/_/g, ' ').toUpperCase(), margin + 4, y + 16);

      // Explanation
      doc.setTextColor(darkGray[0], darkGray[1], darkGray[2]);
      doc.setFontSize(8);
      doc.setFont('helvetica', 'normal');
      const expLines = doc.splitTextToSize(t.explanation || '', contentW - 50);
      doc.text(expLines[0] || '', margin + 30, y + 16);

      y += 26;
    });
  } else {
    drawRoundRect(margin, y, contentW, 12, 2, [240, 253, 244]);
    doc.setTextColor(green[0], green[1], green[2]);
    doc.setFontSize(9);
    doc.text('No manipulation techniques detected', margin + 4, y + 8);
    y += 16;
  }

  // Summary
  if (data.prism?.brief) {
    checkPage(20);
    drawRoundRect(margin, y, contentW, 18, 2, [250, 245, 255]);
    doc.setTextColor(purple[0], purple[1], purple[2]);
    doc.setFontSize(7);
    doc.setFont('helvetica', 'bold');
    doc.text('SUMMARY', margin + 4, y + 5);
    doc.setTextColor(darkGray[0], darkGray[1], darkGray[2]);
    doc.setFontSize(8);
    doc.setFont('helvetica', 'normal');
    const summaryLines = doc.splitTextToSize(data.prism.brief, contentW - 8);
    doc.text(summaryLines.slice(0, 3), margin + 4, y + 10);
    y += 22;
  }

  y += 4;

  // ========== TRACE — FACT-CHECKS ==========
  checkPage(30);
  doc.setTextColor(blue[0], blue[1], blue[2]);
  doc.setFontSize(8);
  doc.setFont('helvetica', 'bold');
  doc.text('TRACE — FACT-CHECKS & SOURCE ORIGINS', margin, y);
  doc.setTextColor(gray[0], gray[1], gray[2]);
  doc.setFont('helvetica', 'normal');
  doc.text(`${fcs} checks · ${data.trace?.spread_timeline?.length || 0} sources`, W - margin, y, { align: 'right' });
  y += 5;

  if (data.trace?.fact_checks?.length > 0) {
    // Table header
    drawRoundRect(margin, y, contentW, 7, 1, lightBg);
    doc.setTextColor(gray[0], gray[1], gray[2]);
    doc.setFontSize(7);
    doc.setFont('helvetica', 'bold');
    doc.text('PUBLISHER', margin + 4, y + 5);
    doc.text('TITLE', margin + 40, y + 5);
    doc.text('RATING', W - margin - 4, y + 5, { align: 'right' });
    y += 9;

    const maxFC = Math.min(data.trace.fact_checks.length, 8);
    for (let i = 0; i < maxFC; i++) {
      checkPage(8);
      const fc = data.trace.fact_checks[i];
      if (i % 2 === 0) drawRoundRect(margin, y - 1, contentW, 7, 0.5, [252, 252, 251]);

      doc.setTextColor(black[0], black[1], black[2]);
      doc.setFontSize(8);
      doc.setFont('helvetica', 'bold');
      doc.text((fc.publisher || '').slice(0, 20), margin + 4, y + 4);

      doc.setFont('helvetica', 'normal');
      doc.setTextColor(darkGray[0], darkGray[1], darkGray[2]);
      const titleTrunc = (fc.title || '').slice(0, 55) + ((fc.title || '').length > 55 ? '...' : '');
      doc.text(titleTrunc, margin + 40, y + 4);

      // Rating badge
      const rating = (fc.rating || '').toLowerCase();
      const rColor = rating.includes('false') ? red : rating.includes('true') ? green : amber;
      doc.setTextColor(rColor[0], rColor[1], rColor[2]);
      doc.setFont('helvetica', 'bold');
      doc.setFontSize(7);
      doc.text((fc.rating || 'N/A').toUpperCase(), W - margin - 4, y + 4, { align: 'right' });

      y += 7;
    }

    if (data.trace.fact_checks.length > 8) {
      doc.setTextColor(blue[0], blue[1], blue[2]);
      doc.setFontSize(8);
      doc.text(`+ ${data.trace.fact_checks.length - 8} more fact-checks`, margin + 4, y + 4);
      y += 8;
    }
  } else {
    doc.setTextColor(gray[0], gray[1], gray[2]);
    doc.setFontSize(9);
    doc.text('No existing fact-checks found', margin + 4, y + 4);
    y += 8;
  }

  y += 6;

  // ========== SIGNAL — CREDIBILITY ==========
  checkPage(30);
  doc.setTextColor(amber[0], amber[1], amber[2]);
  doc.setFontSize(8);
  doc.setFont('helvetica', 'bold');
  doc.text('SIGNAL — SOURCE CREDIBILITY & SENTIMENT', margin, y);
  y += 5;

  const signals = [
    { label: 'Source Bias', value: data.signal?.source_bias || 'Unknown' },
    { label: 'Factuality', value: data.signal?.source_factuality || 'Unknown' },
    { label: 'Sentiment', value: `${data.signal?.sentiment || 'neutral'} (${(data.signal?.sentiment_score || 0).toFixed(2)})` },
    { label: 'Toxicity', value: `${(tox * 100).toFixed(1)}%` },
  ];

  const cellW = contentW / 4;
  drawRoundRect(margin, y, contentW, 16, 2, [255, 255, 255]);
  doc.setDrawColor(230, 230, 230);
  doc.roundedRect(margin, y, contentW, 16, 2, 2, 'S');

  signals.forEach((s, i) => {
    const cx = margin + cellW * i + 4;
    doc.setTextColor(gray[0], gray[1], gray[2]);
    doc.setFontSize(7);
    doc.setFont('helvetica', 'bold');
    doc.text(s.label.toUpperCase(), cx, y + 5);
    doc.setTextColor(darkGray[0], darkGray[1], darkGray[2]);
    doc.setFontSize(9);
    doc.setFont('helvetica', 'normal');
    doc.text(String(s.value), cx, y + 12);
  });

  y += 22;

  // ========== METADATA & BLOCKCHAIN ==========
  checkPage(24);
  doc.setTextColor(gray[0], gray[1], gray[2]);
  doc.setFontSize(8);
  doc.setFont('helvetica', 'bold');
  doc.text('METADATA & EVIDENCE CHAIN', margin, y);
  y += 5;

  drawRoundRect(margin, y, contentW, 20, 2, lightBg);
  doc.setTextColor(darkGray[0], darkGray[1], darkGray[2]);
  doc.setFontSize(8);
  doc.setFont('helvetica', 'normal');
  doc.text(`Analysis time: ${(data.analysis_time_ms / 1000).toFixed(1)}s`, margin + 4, y + 6);
  doc.text(`Model: ${data.prism?.model_used || 'N/A'}`, margin + 60, y + 6);
  doc.text(`Cache: ${data.cached ? 'Hit' : 'Fresh'}`, margin + 110, y + 6);

  doc.setFontSize(7);
  doc.setTextColor(gray[0], gray[1], gray[2]);
  doc.text('SHA-256 Content Hash:', margin + 4, y + 13);
  doc.setFont('courier', 'normal');
  doc.setFontSize(7);
  doc.text(data.blockchain?.content_hash || 'N/A', margin + 38, y + 13);

  doc.setFont('helvetica', 'normal');
  doc.text(`Proof status: ${data.blockchain?.proof_status || 'pending'}`, margin + 4, y + 17);

  y += 26;

  // ========== FOOTER ==========
  const pageCount = doc.getNumberOfPages();
  for (let i = 1; i <= pageCount; i++) {
    doc.setPage(i);
    doc.setDrawColor(200, 200, 200);
    doc.line(margin, 287, W - margin, 287);
    doc.setTextColor(gray[0], gray[1], gray[2]);
    doc.setFontSize(7);
    doc.setFont('helvetica', 'normal');
    doc.text('Generated by Dissekt — dissekt.info', margin, 292);
    doc.text('Explanation, not verdicts.', W / 2, 292, { align: 'center' });
    doc.text(`Page ${i} of ${pageCount}`, W - margin, 292, { align: 'right' });
  }

  return doc;
}

export function downloadPDF(data: AnalysisData, inputContent: string) {
  const doc = generateAnalysisPDF(data, inputContent);
  const timestamp = new Date().toISOString().slice(0, 10);
  doc.save(`dissekt-report-${timestamp}.pdf`);
}

export function getShareText(data: AnalysisData): string {
  const techniques = data.prism?.techniques?.length || 0;
  const fcs = data.trace?.fact_checks?.length || 0;
  const tox = data.signal?.toxicity_score || 0;
  const maxConf = data.prism?.techniques?.reduce((max: number, t: any) => Math.max(max, t.confidence || 0), 0) || 0;
  let score = (techniques > 0 ? Math.round(maxConf * 40) : 0) + Math.min(fcs * 4, 30) + Math.round(tox * 20) + (fcs >= 3 ? 10 : 0);
  score = Math.min(score, 100);

  const techNames = data.prism?.techniques?.map((t: any) => t.name.replace(/_/g, ' ')).join(', ') || 'none';
  const topFC = data.trace?.fact_checks?.[0];

  let text = `🛡️ Dissekt Analysis Report\n`;
  text += `Threat Score: ${score}/100\n\n`;
  text += `Techniques found: ${techniques} (${techNames})\n`;
  text += `Fact-checks: ${fcs} found\n`;
  if (topFC) text += `Top result: ${topFC.publisher} — ${topFC.rating}\n`;
  text += `Toxicity: ${(tox * 100).toFixed(1)}%\n\n`;
  text += `Analyzed at dissekt.info`;
  return text;
}
