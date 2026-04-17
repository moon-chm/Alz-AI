LANGUAGE_MAP = {
    "Hindi": "hi",
    "Marathi": "mr",
    "Tamil": "ta",
    "Telugu": "te",
    "Kannada": "kn",
    "Gujarati": "gu",
    "Punjabi": "pa",
    "Bengali": "bn",
    "English": "en",
}

def get_gtts_language(language: str) -> str:
    return LANGUAGE_MAP.get(language, "hi")

def get_whisper_language(language: str) -> str:
    whisper_map = {**LANGUAGE_MAP, "Punjabi": "pa"}
    return whisper_map.get(language, "hi")
