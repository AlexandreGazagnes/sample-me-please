"""
Lyrics scraper — reads utils/lyrics.json, fetches missing lyrics from AZLyrics,
cleans the text, and writes the result back.

JSON schema: list of dicts with keys: author, track_name, text

Dependencies:
    pip install requests beautifulsoup4

Usage:
    python utils/scraper.py
    python utils/scraper.py --json utils/lyrics.json
"""

import json
import re
import time
import argparse
from pathlib import Path

import requests
from bs4 import BeautifulSoup, Comment

ROOT      = Path(__file__).parent.parent
JSON_PATH = ROOT / "utils" / "lyrics.json"

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (X11; Linux x86_64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/122.0.0.0 Safari/537.36"
    )
}


# ── Helpers ───────────────────────────────────────────────────────────────────

def slugify(text: str) -> str:
    text = text.lower()
    text = re.sub(r"['\"]", "", text)
    text = re.sub(r"[^a-z0-9]+", "", text)
    return text


def build_url(author: str, track: str) -> str:
    return f"https://www.azlyrics.com/lyrics/{slugify(author)}/{slugify(track)}.html"


def fetch_lyrics(url: str) -> str | None:
    print(f"  → {url}")

    try:
        resp = requests.get(url, headers=HEADERS, timeout=15)
    except requests.RequestException as e:
        print(f"  ✗ request error: {e}")
        return None

    if resp.status_code != 200:
        print(f"  ✗ HTTP {resp.status_code}")
        return None

    soup = BeautifulSoup(resp.text, "html.parser")

    # AZLyrics marks the lyrics block with a comment just before it.
    # Find that comment, then take the next sibling div.
    comments = soup.find_all(string=lambda s: isinstance(s, Comment))
    for comment in comments:
        if "Usage of azlyrics.com content" in comment:
            lyrics_div = comment.find_next("div")
            if lyrics_div:
                return clean(lyrics_div.get_text(separator=" "))

    print("  ✗ lyrics marker not found")
    return None


def clean(text: str) -> str:
    text = re.sub(r"\[.*?\]", "", text)   # remove [Verse], [Chorus] tags
    text = re.sub(r"\s+", " ", text)      # collapse all whitespace / newlines
    return text.strip()


def save(data: list, json_path: Path) -> None:
    json_path.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")


# ── Main ──────────────────────────────────────────────────────────────────────

def main(json_path: Path) -> None:
    data = json.loads(json_path.read_text(encoding="utf-8"))

    updated = 0
    for entry in data:
        if entry.get("text"):
            print(f"skip: {entry['author']} — {entry['track_name']}")
            continue

        print(f"\n{entry['author']} — {entry['track_name']}")
        url  = entry.get("url") or build_url(entry["author"], entry["track_name"])
        text = fetch_lyrics(url)

        if text:
            entry["text"] = text
            updated += 1
            save(data, json_path)   # save immediately — don't lose progress on crash
            print(f"  ✓ saved ({len(text)} chars)")
        else:
            print("  ✗ not found — leaving empty")

        time.sleep(2)

    print(f"\nDone — {updated}/{len(data)} track(s) updated → {json_path}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Fetch missing lyrics into a JSON file.")
    parser.add_argument("--json", type=Path, default=JSON_PATH)
    args = parser.parse_args()
    main(args.json)
