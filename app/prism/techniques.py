"""Dissekt — Manipulation technique taxonomy.

20 techniques across 4 categories. Each technique has:
- name: machine-readable identifier
- label: human-readable display name
- category: framing / logical_fallacy / credibility / deflection
- description: what it means (used in prompts and output)
- indicators: keywords/patterns that suggest this technique (used by heuristics)
"""

TECHNIQUES = [
    # === FRAMING ===
    {
        "name": "cherry_picking",
        "label": "Cherry-picking",
        "category": "framing",
        "description": "Selectively presenting data or facts that support a conclusion while ignoring contradicting evidence.",
        "indicators": ["only shows", "ignores", "fails to mention", "conveniently omits", "selected data"]
    },
    {
        "name": "missing_context",
        "label": "Missing context",
        "category": "framing",
        "description": "Presenting factually accurate information but omitting crucial context that changes the meaning.",
        "indicators": ["out of context", "without mentioning", "doesn't explain", "leaves out"]
    },
    {
        "name": "loaded_language",
        "label": "Loaded language",
        "category": "framing",
        "description": "Using emotionally charged words to influence perception rather than inform.",
        "indicators": []  # Detected by emotional word density heuristic
    },
    {
        "name": "emotional_framing",
        "label": "Emotional framing",
        "category": "framing",
        "description": "Structuring information to provoke fear, anger, outrage, or sympathy rather than rational analysis.",
        "indicators": ["shocking", "terrifying", "outrageous", "heartbreaking", "disgusting"]
    },
    {
        "name": "false_balance",
        "label": "False balance",
        "category": "framing",
        "description": "Presenting two sides as equally valid when evidence overwhelmingly supports one side.",
        "indicators": ["both sides", "some say", "debate", "controversy", "on the other hand"]
    },
    {
        "name": "selective_emphasis",
        "label": "Selective emphasis",
        "category": "framing",
        "description": "Highlighting minor or irrelevant details to distract from the main point.",
        "indicators": ["focuses on", "highlights", "emphasizes", "draws attention to"]
    },

    # === LOGICAL FALLACIES ===
    {
        "name": "straw_man",
        "label": "Straw man",
        "category": "logical_fallacy",
        "description": "Misrepresenting someone's argument to make it easier to attack.",
        "indicators": ["so you're saying", "what they really mean", "in other words"]
    },
    {
        "name": "false_equivalence",
        "label": "False equivalence",
        "category": "logical_fallacy",
        "description": "Equating two things that are not comparable in the relevant way.",
        "indicators": ["just like", "same as", "no different from", "equivalent to"]
    },
    {
        "name": "false_dichotomy",
        "label": "False dichotomy",
        "category": "logical_fallacy",
        "description": "Presenting only two options when more exist.",
        "indicators": ["either...or", "you're either", "only two choices", "if not...then"]
    },
    {
        "name": "slippery_slope",
        "label": "Slippery slope",
        "category": "logical_fallacy",
        "description": "Arguing that one event will inevitably lead to extreme consequences without evidence.",
        "indicators": ["will lead to", "next thing you know", "before you know it", "opens the door"]
    },
    {
        "name": "hasty_generalization",
        "label": "Hasty generalization",
        "category": "logical_fallacy",
        "description": "Drawing broad conclusions from limited evidence or examples.",
        "indicators": []  # Detected by absolute language scorer heuristic
    },
    {
        "name": "circular_reasoning",
        "label": "Circular reasoning",
        "category": "logical_fallacy",
        "description": "Using the conclusion as a premise — the argument assumes what it's trying to prove.",
        "indicators": ["because it is", "obviously", "it's clear that", "everyone knows"]
    },

    # === CREDIBILITY MANIPULATION ===
    {
        "name": "appeal_to_authority",
        "label": "Appeal to unnamed authority",
        "category": "credibility",
        "description": "Citing unnamed 'experts' or 'studies' without specific attribution.",
        "indicators": []  # Detected by authority phrase detector heuristic
    },
    {
        "name": "ad_hominem",
        "label": "Ad hominem",
        "category": "credibility",
        "description": "Attacking the person making the argument instead of the argument itself.",
        "indicators": ["they would say that", "of course they think", "what do you expect from"]
    },
    {
        "name": "appeal_to_nature",
        "label": "Appeal to nature",
        "category": "credibility",
        "description": "Arguing that something is good because it's 'natural' or bad because it's 'artificial'.",
        "indicators": ["natural", "organic", "artificial", "synthetic", "chemical", "unnatural"]
    },
    {
        "name": "bandwagon",
        "label": "Bandwagon / appeal to popularity",
        "category": "credibility",
        "description": "Arguing something is true or good because many people believe or do it.",
        "indicators": ["everyone knows", "most people", "millions of", "growing number", "mainstream"]
    },
    {
        "name": "tu_quoque",
        "label": "Tu quoque (you too)",
        "category": "credibility",
        "description": "Deflecting criticism by pointing out the critic's own flaws.",
        "indicators": ["but you also", "what about when you", "they did the same", "hypocrite"]
    },

    # === DEFLECTION ===
    {
        "name": "whataboutism",
        "label": "Whataboutism",
        "category": "deflection",
        "description": "Responding to criticism by pointing to a different issue entirely.",
        "indicators": ["what about", "but what about", "why don't you talk about", "but they"]
    },
    {
        "name": "red_herring",
        "label": "Red herring",
        "category": "deflection",
        "description": "Introducing an irrelevant topic to divert attention from the original issue.",
        "indicators": ["the real issue is", "what we should be talking about", "more importantly"]
    },
    {
        "name": "appeal_to_emotion",
        "label": "Appeal to emotion (fear/anger/pity)",
        "category": "deflection",
        "description": "Bypassing rational argument by directly triggering emotional responses.",
        "indicators": ["think of the children", "imagine if", "how would you feel", "are you not angry"]
    },
]

# Build lookup dicts
TECHNIQUE_BY_NAME = {t["name"]: t for t in TECHNIQUES}
TECHNIQUE_NAMES = [t["name"] for t in TECHNIQUES]
CATEGORIES = ["framing", "logical_fallacy", "credibility", "deflection"]
