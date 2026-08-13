# Evaluation findings — Dissekt scoring engine

Corpus: 11 items, 6 genres (reporting 2, satire 2, activism 3, academic 2,
opinion 1, press_release 1). Heuristics + scoring only; no LLM technique
detection in this pass.

## 1. Attribution heuristics are wire-report detectors

`compute_completeness.sources` and `compute_diversity` both measure sourcing by
counting reported-speech verbs (`said`, `according to`, `reported`, `stated`,
`confirmed`, `cited`).

Attribution verbs found, by item: only 3 of 11 registered any.
- reporting (2/2): 5 and 7 occurrences
- satire (1/2): 2 occurrences — fabricated quotes from a fictional official
- academic, activism, opinion, press_release (0/7): none

Consequence: academic abstracts scored `sources=0.00` and `diversity=0.35`
against `sources=1.00`, `diversity=0.52–0.56` for wire copy. Two of the ten
scoring metrics respond almost exclusively to one genre's conventions.

Corollary: the only non-journalism item to score on sourcing did so with
invented attribution. Fabricated quotes are indistinguishable from real ones
under these heuristics.

## 2. Satire scores at the top of the corpus

Highest clarity in the set (0.760) and highest intent (0.966) went to a
satirical article — above both wire reports. Consistent with the stated
positioning (construction, not truth: satire is built like clean reporting),
but it means fabricated content can receive the highest transparency score the
system awards. Needs to be stated in the product, not just defended after.

## 3. Genre detection: 1 of 11 correct

`detect_genre` classified 10 of 11 items as `news_article`. The only success
was a press release containing the literal phrase. The function matches on
labels ("opinion", "editorial") that appear in page chrome rather than body
text. Currently inert — `GENRE_BASELINES` became dead code when the toxicity
signal was removed — but it ships.

## 4. Score range is narrow

All 11 items fell between 0.514 and 0.760 clarity — 0.25 of a 1.0 scale, all
within the "Moderate/High" bands. Genre separation exists but is compressed.
