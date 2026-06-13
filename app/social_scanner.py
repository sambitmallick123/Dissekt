"""
Social media scanners for Reddit, YouTube, Substack, Bluesky, Mastodon.
Each returns extracted text suitable for Prism analysis.
"""
import httpx
import logging
import re

logger = logging.getLogger("dissekt.social")


async def scan_reddit(url: str) -> dict:
    """Extract Reddit post/comment text from a URL or subreddit RSS."""
    try:
        # Reddit JSON trick: append .json to any reddit URL
        json_url = url.rstrip('/') + '.json' if 'reddit.com' in url else url
        if not json_url.endswith('.json'):
            json_url += '.json'
        
        async with httpx.AsyncClient(timeout=15, headers={"User-Agent": "Dissekt/1.0"}) as client:
            res = await client.get(json_url)
            data = res.json()
        
        # Single post
        if isinstance(data, list) and len(data) >= 1:
            post = data[0]["data"]["children"][0]["data"]
            title = post.get("title", "")
            selftext = post.get("selftext", "")
            subreddit = post.get("subreddit", "")
            score = post.get("score", 0)
            
            # Get top comments
            comments = []
            if len(data) >= 2:
                for child in data[1]["data"]["children"][:10]:
                    if child["kind"] == "t1":
                        comments.append(child["data"].get("body", ""))
            
            full_text = f"{title}\n\n{selftext}\n\n" + "\n".join(comments[:5])
            return {
                "source": "reddit",
                "subreddit": subreddit,
                "title": title,
                "text": full_text.strip(),
                "score": score,
                "comments": len(comments),
                "url": url,
            }
        return {"source": "reddit", "text": "", "error": "Could not parse Reddit data"}
    except Exception as e:
        logger.warning(f"Reddit scan failed: {e}")
        return {"source": "reddit", "text": "", "error": str(e)}


async def scan_youtube(url: str) -> dict:
    """Extract YouTube video transcript using yt-dlp."""
    try:
        import subprocess, json, tempfile, os
        
        # Extract video ID
        vid_id = ""
        if "youtu.be/" in url:
            vid_id = url.split("youtu.be/")[1].split("?")[0]
        elif "v=" in url:
            vid_id = url.split("v=")[1].split("&")[0]
        
        # Try to get subtitles via yt-dlp
        with tempfile.TemporaryDirectory() as tmp:
            sub_path = os.path.join(tmp, "subs")
            result = subprocess.run([
                "yt-dlp", "--skip-download", "--write-auto-sub", "--sub-lang", "en",
                "--sub-format", "json3", "-o", sub_path, url
            ], capture_output=True, text=True, timeout=30)
            
            # Find the subtitle file
            transcript = ""
            for f in os.listdir(tmp):
                if f.endswith(".json3") or f.endswith(".vtt") or f.endswith(".srt"):
                    content = open(os.path.join(tmp, f)).read()
                    if f.endswith(".json3"):
                        try:
                            subs = json.loads(content)
                            transcript = " ".join(
                                seg.get("segs", [{}])[0].get("utf8", "")
                                for seg in subs.get("events", [])
                                if seg.get("segs")
                            )
                        except:
                            transcript = content
                    else:
                        # Strip VTT/SRT timestamps
                        lines = content.split("\n")
                        transcript = " ".join(
                            l for l in lines
                            if l.strip() and not re.match(r'^\d', l) and '-->' not in l and l.strip() != 'WEBVTT'
                        )
            
            if not transcript:
                # Fallback: get title + description
                info_result = subprocess.run(
                    ["yt-dlp", "--skip-download", "--print", "%(title)s|||%(description)s", url],
                    capture_output=True, text=True, timeout=15
                )
                parts = info_result.stdout.strip().split("|||")
                transcript = f"{parts[0]}\n\n{parts[1] if len(parts) > 1 else ''}"
        
        return {
            "source": "youtube",
            "video_id": vid_id,
            "text": transcript.strip()[:10000],  # Cap at 10K chars
            "url": url,
        }
    except FileNotFoundError:
        return {"source": "youtube", "text": "", "error": "yt-dlp not installed. Run: pip install yt-dlp"}
    except Exception as e:
        logger.warning(f"YouTube scan failed: {e}")
        return {"source": "youtube", "text": "", "error": str(e)}


async def scan_bluesky(url: str) -> dict:
    """Extract Bluesky post text via public API."""
    try:
        # Parse handle and rkey from URL: bsky.app/profile/handle/post/rkey
        parts = url.split("/")
        handle = ""
        rkey = ""
        for i, p in enumerate(parts):
            if p == "profile" and i + 1 < len(parts):
                handle = parts[i + 1]
            if p == "post" and i + 1 < len(parts):
                rkey = parts[i + 1]
        
        if not handle or not rkey:
            return {"source": "bluesky", "text": "", "error": "Could not parse Bluesky URL"}
        
        # Resolve DID
        async with httpx.AsyncClient(timeout=10) as client:
            did_res = await client.get(f"https://bsky.social/xrpc/com.atproto.identity.resolveHandle?handle={handle}")
            did = did_res.json().get("did", "")
            
            if did:
                uri = f"at://{did}/app.bsky.feed.post/{rkey}"
                thread_res = await client.get(f"https://bsky.social/xrpc/app.bsky.feed.getPostThread?uri={uri}&depth=3")
                thread = thread_res.json()
                
                post = thread.get("thread", {}).get("post", {})
                text = post.get("record", {}).get("text", "")
                author = post.get("author", {}).get("displayName", handle)
                
                # Get replies
                replies_text = []
                for reply in thread.get("thread", {}).get("replies", [])[:5]:
                    rt = reply.get("post", {}).get("record", {}).get("text", "")
                    if rt:
                        replies_text.append(rt)
                
                full_text = f"{author}: {text}\n\nReplies:\n" + "\n".join(replies_text)
                return {"source": "bluesky", "handle": handle, "text": full_text.strip(), "url": url}
        
        return {"source": "bluesky", "text": "", "error": "Could not fetch post"}
    except Exception as e:
        logger.warning(f"Bluesky scan failed: {e}")
        return {"source": "bluesky", "text": "", "error": str(e)}


async def scan_mastodon(url: str) -> dict:
    """Extract Mastodon post text via public API."""
    try:
        # Parse instance and status ID from URL: instance/@user/statusid
        parts = url.split("/")
        instance = f"{parts[0]}//{parts[2]}" if len(parts) > 2 else ""
        status_id = parts[-1] if parts[-1].isdigit() else ""
        
        if not instance or not status_id:
            return {"source": "mastodon", "text": "", "error": "Could not parse Mastodon URL"}
        
        async with httpx.AsyncClient(timeout=10) as client:
            res = await client.get(f"{instance}/api/v1/statuses/{status_id}")
            data = res.json()
            
            # Strip HTML tags
            content = re.sub(r'<[^>]+>', '', data.get("content", ""))
            author = data.get("account", {}).get("display_name", "")
            
            # Get replies
            ctx_res = await client.get(f"{instance}/api/v1/statuses/{status_id}/context")
            ctx = ctx_res.json()
            replies = [re.sub(r'<[^>]+>', '', r.get("content", "")) for r in ctx.get("descendants", [])[:5]]
            
            full_text = f"{author}: {content}\n\nReplies:\n" + "\n".join(replies)
            return {"source": "mastodon", "instance": instance, "text": full_text.strip(), "url": url}
    except Exception as e:
        logger.warning(f"Mastodon scan failed: {e}")
        return {"source": "mastodon", "text": "", "error": str(e)}


async def scan_substack(url: str) -> dict:
    """Extract Substack article. Trafilatura handles this well, so we just tag it."""
    return {"source": "substack", "text": "", "url": url, "use_beacon": True}


async def detect_and_extract(url: str) -> dict:
    """Auto-detect social platform and extract content."""
    url_lower = url.lower()
    
    if "reddit.com" in url_lower or "redd.it" in url_lower:
        return await scan_reddit(url)
    elif "youtube.com" in url_lower or "youtu.be" in url_lower:
        return await scan_youtube(url)
    elif "bsky.app" in url_lower or "bsky.social" in url_lower:
        return await scan_bluesky(url)
    elif "mastodon" in url_lower or "/@" in url_lower:
        return await scan_mastodon(url)
    elif "substack.com" in url_lower:
        return await scan_substack(url)
    
    return {"source": "web", "text": "", "use_beacon": True}
