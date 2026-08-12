# Removing the toxicity signal (Aug 2026)

Detoxify fed `compute_tone` via a genre-baseline subtraction: values below the
baseline (0.06 for news_article) clamp to zero and contribute nothing.

Sensitivity sweep, holding all other inputs fixed:

| raw toxicity | clarity | tone  |
|--------------|---------|-------|
| 0.00         | 0.6650  | 0.450 |
| 0.05         | 0.6650  | 0.450 |
| 0.10         | 0.6630  | 0.437 |
| 0.20         | 0.6570  | 0.405 |
| 0.40         | 0.6440  | 0.341 |
| 0.80         | 0.6100  | 0.214 |

Observed Detoxify output on news content sat below 0.05, so the signal was
inert on the product's primary input class while costing a 440MB model load,
torch, and transformers. Removed. Tone weights (hostility 0.40, sentiment 0.30)
were left unchanged so the edit is behaviour-preserving rather than a silent
re-scaling.
