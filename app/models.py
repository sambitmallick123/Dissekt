"""Dissekt data models — API request and response schemas."""

from pydantic import BaseModel, Field
from typing import Optional
from enum import Enum
from datetime import datetime


# ============================================
# Enums
# ============================================

class AnalysisMode(str, Enum):
    brief = "brief"
    detailed = "detailed"


class InputType(str, Enum):
    url = "url"
    text = "text"
    image = "image"


class TechniqueCategory(str, Enum):
    framing = "framing"
    logical_fallacy = "logical_fallacy"
    credibility = "credibility"
    deflection = "deflection"


# ============================================
# Request Models
# ============================================

class ScanRequest(BaseModel):
    """Main input: user pastes a URL or text."""
    content: str = Field(default="", max_length=50000, description="URL or text to analyze")
    mode: AnalysisMode = Field(default=AnalysisMode.brief, description="brief or detailed")
    image: str | None = Field(default=None, description="Base64 data-URL of an image to analyze via vision")


# ============================================
# Response Models — Prism
# ============================================

class Technique(BaseModel):
    """A single manipulation technique detected."""
    name: str = Field(..., description="e.g. 'cherry-picking', 'emotional framing'")
    category: TechniqueCategory
    confidence: float = Field(..., ge=0.0, le=1.0)
    explanation: str = Field(..., description="Why this technique was identified")
    evidence: str = Field(default="", description="Specific text that triggered detection")


class PrismResult(BaseModel):
    """Output from the manipulation analysis engine."""
    techniques: list[Technique] = []
    brief: str = Field(default="", description="2-3 sentence summary")
    detailed: str = Field(default="", description="Full breakdown")
    model_used: str = Field(default="", description="Which LLM/heuristic produced this")
    heuristic_only: bool = Field(default=False, description="True if no LLM was called")


# ============================================
# Response Models — Trace
# ============================================

class FactCheck(BaseModel):
    """An existing fact-check found for this claim."""
    title: str
    publisher: str
    url: str
    rating: str = Field(default="", description="e.g. 'False', 'Mostly True', 'Misleading'")
    date: str = ""


class SourceAppearance(BaseModel):
    """A place where this claim appeared, ordered chronologically."""
    url: str
    title: str = ""
    date: str = ""
    platform: str = ""


class TraceResult(BaseModel):
    """Output from the source origin finder."""
    fact_checks: list[FactCheck] = []
    earliest_source: Optional[SourceAppearance] = None
    spread_timeline: list[SourceAppearance] = []
    check_worthiness: float = Field(default=0.0, ge=0.0, le=1.0)


# ============================================
# Response Models — Signal
# ============================================

class SignalResult(BaseModel):
    """Output from the bias/toxicity/emotion radar."""
    toxicity_score: float = Field(default=0.0, ge=0.0, le=1.0)
    toxicity_labels: dict[str, float] = Field(default_factory=dict)
    source_bias: Optional[str] = Field(default=None, description="e.g. 'left-center', 'right'")
    source_factuality: Optional[str] = Field(default=None, description="e.g. 'high', 'mixed'")
    primary_emotion: str = Field(default="neutral")
    emotion_scores: dict[str, float] = Field(default_factory=dict)
    sentiment: str = Field(default="neutral", description="positive/negative/neutral")
    sentiment_score: float = Field(default=0.0)


# ============================================
# Combined Response
# ============================================

class BlockchainProof(BaseModel):
    """Blockchain evidence timestamp."""
    content_hash: str
    timestamp: str
    proof_status: str = "pending"  # pending, anchored, verified


class FullAnalysis(BaseModel):
    """Complete analysis result combining all engines."""
    scoring: dict | None = None
    facet: dict | None = None
    id: str = ""
    input_type: InputType
    input_content: str = Field(default="", description="Original input (truncated for display)")
    extracted_text: str = Field(default="", description="Clean text extracted from URL")

    prism: PrismResult
    trace: TraceResult
    signal: SignalResult
    blockchain: Optional[BlockchainProof] = None

    compass: dict = Field(default_factory=dict, description="Political accountability data")
    pulse: dict = Field(default_factory=dict, description="Coordination detection signals")
    similar_claims: list[dict] = Field(default_factory=list, description="Similar past analyses from Qdrant")
    detected_language: str = Field(default="en", description="Detected input language")
    counterfactuals: list[dict] = Field(default_factory=list, description="Alternative framings for key claims")
    extracted_claims: list[dict] = Field(default_factory=list, description="Individual verifiable claims extracted")
    bias_signals: list[dict] = Field(default_factory=list, description="Descriptive representation/language tags")
    cached: bool = False
    analyzed_at: datetime = Field(default_factory=datetime.utcnow)
    analysis_time_ms: int = 0
