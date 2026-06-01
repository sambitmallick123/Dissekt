"""Dissekt Claim Graph — Qdrant vector similarity search.

Every analysis gets embedded and stored. Enables:
- "Has a similar claim been analyzed before?"
- Narrative clustering over time
- Building the knowledge graph moat
"""
import logging
import hashlib
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams, PointStruct
from sentence_transformers import SentenceTransformer
from app.config import get_settings

logger = logging.getLogger("dissekt.claim_graph")

_model = None
_client = None
COLLECTION = "dissekt_claims"
VECTOR_SIZE = 384  # all-MiniLM-L6-v2


def _get_model():
    global _model
    if _model is None:
        _model = SentenceTransformer('all-MiniLM-L6-v2')
        logger.info("Sentence transformer loaded")
    return _model


def _get_client():
    global _client
    if _client is None:
        settings = get_settings()
        if not settings.qdrant_url:
            return None
        _client = QdrantClient(
            url=settings.qdrant_url,
            api_key=settings.qdrant_api_key,
        )
        try:
            _client.get_collection(COLLECTION)
        except Exception:
            _client.create_collection(
                collection_name=COLLECTION,
                vectors_config=VectorParams(size=VECTOR_SIZE, distance=Distance.COSINE),
            )
            logger.info(f"Created Qdrant collection: {COLLECTION}")
    return _client


async def store_analysis(text: str, analysis_id: str, metadata: dict) -> bool:
    """Store an analysis embedding in Qdrant."""
    client = _get_client()
    if client is None:
        return False

    try:
        model = _get_model()
        embedding = model.encode(text[:512]).tolist()

        point = PointStruct(
            id=hashlib.md5(analysis_id.encode()).hexdigest()[:16],
            vector=embedding,
            payload={
                "analysis_id": analysis_id,
                "text_preview": text[:200],
                "techniques": metadata.get("techniques", []),
                "source_bias": metadata.get("source_bias"),
                "timestamp": metadata.get("timestamp"),
            }
        )

        client.upsert(collection_name=COLLECTION, points=[point])
        return True
    except Exception as e:
        logger.error(f"Qdrant store failed: {e}")
        return False


async def find_similar(text: str, limit: int = 5) -> list[dict]:
    """Find similar past analyses."""
    client = _get_client()
    if client is None:
        return []

    try:
        model = _get_model()
        embedding = model.encode(text[:512]).tolist()

        results = client.search(
            collection_name=COLLECTION,
            query_vector=embedding,
            limit=limit,
            score_threshold=0.7,
        )

        return [
            {
                "analysis_id": r.payload.get("analysis_id"),
                "text_preview": r.payload.get("text_preview"),
                "similarity": round(r.score, 3),
                "techniques": r.payload.get("techniques", []),
            }
            for r in results
        ]
    except Exception as e:
        logger.error(f"Qdrant search failed: {e}")
        return []
