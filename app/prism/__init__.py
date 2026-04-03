"""Dissekt Prism — Manipulation Analysis Engine."""
from app.prism.heuristics import run_all_heuristics, HeuristicResult
from app.prism.llm import route_and_analyze
from app.prism.techniques import TECHNIQUES, TECHNIQUE_BY_NAME
