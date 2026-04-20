from datetime import datetime, time
import pytz

def get_local_now(timezone_str: str) -> datetime:
    """Returns the current localized datetime for a given timezone string."""
    try:
        tz = pytz.timezone(timezone_str or "Asia/Kolkata")
    except:
        tz = pytz.timezone("Asia/Kolkata")
    return datetime.now(tz)

def get_local_date_str(timezone_str: str) -> str:
    """Returns the current localized date in YYYY-MM-DD format."""
    return get_local_now(timezone_str).strftime("%Y-%m-%d")

def is_time_reached(scheduled_time_str: str, timezone_str: str) -> bool:
    """
    Checks if a scheduled time (HH:MM) has been reached/passed in the given timezone.
    Used for Progressive Compliance.
    """
    now = get_local_now(timezone_str)
    try:
        hour, minute = map(int, scheduled_time_str.split(":"))
        scheduled = now.replace(hour=hour, minute=minute, second=0, microsecond=0)
        return now >= scheduled
    except Exception:
        return False
