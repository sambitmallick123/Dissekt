"""Dissekt Anchor — Blockchain evidence chain.

Creates OpenTimestamps proofs for every analysis.
SHA-256 hash → OTS calendar → Bitcoin blockchain.
"""
import hashlib
import logging
import time
import base64
import httpx

logger = logging.getLogger("dissekt.anchor")

OTS_CALENDAR = "https://a.pool.opentimestamps.org/digest"


async def create_timestamp(content_hash: str) -> dict:
    """Submit hash to OpenTimestamps calendar server.

    Returns: OTS proof bytes (base64 encoded).
    Full Bitcoin confirmation takes ~1 hour.
    """
    try:
        hash_bytes = bytes.fromhex(content_hash)

        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.post(
                OTS_CALENDAR,
                content=hash_bytes,
                headers={"Content-Type": "application/octet-stream"},
            )

            if resp.status_code == 200:
                proof = base64.b64encode(resp.content).decode()
                return {
                    "content_hash": content_hash,
                    "timestamp": str(int(time.time())),
                    "proof_status": "pending_confirmation",
                    "ots_proof": proof,
                    "calendar_url": OTS_CALENDAR,
                }
            else:
                logger.warning(f"OTS calendar returned {resp.status_code}")
                return _fallback_proof(content_hash)
    except Exception as e:
        logger.error(f"OTS submission failed: {e}")
        return _fallback_proof(content_hash)


def _fallback_proof(content_hash: str) -> dict:
    """Fallback: just return the hash without OTS proof."""
    return {
        "content_hash": content_hash,
        "timestamp": str(int(time.time())),
        "proof_status": "pending",
        "ots_proof": None,
    }
