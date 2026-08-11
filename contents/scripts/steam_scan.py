#!/usr/bin/env python3

import json
import os
import subprocess
import sys
import urllib.request
import urllib.parse
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
ORIGINAL_SCANNER = SCRIPT_DIR / "steam_scan_original.py"

DATA_DIR = SCRIPT_DIR.parent / "data"
BANNER_DIR = DATA_DIR / "banners"
KEY_FILE = Path.home() / ".config" / "steambanners" / "steamgriddb.key"

API_BASE = "https://www.steamgriddb.com/api/v2"


def load_api_key():
    try:
        return KEY_FILE.read_text().strip()
    except Exception as e:
        print(
            f"SteamGridDB API key could not be read: {e}",
            file=sys.stderr
        )
        return None


def run_original_scanner():
    try:
        result = subprocess.run(
            [sys.executable, str(ORIGINAL_SCANNER)],
            capture_output=True,
            text=True,
            check=True
        )

        return json.loads(result.stdout)

    except Exception as e:
        print(
            f"Original Steam scanner failed: {e}",
            file=sys.stderr
        )
        return []


def get_grid_url(appid, api_key):
    url = f"{API_BASE}/grids/steam/{appid}"

    params = urllib.parse.urlencode({
        "dimensions": "920x430,460x215",
        "limit": "1"
    })

    request = urllib.request.Request(
        f"{url}?{params}",
        headers={
            "Authorization": f"Bearer {api_key}",
            "User-Agent": "Steam-Banners/0.1"
        }
    )

    try:
        with urllib.request.urlopen(request, timeout=15) as response:
            data = json.loads(response.read().decode("utf-8"))

        if data.get("success") and data.get("data"):
            return data["data"][0].get("url")

    except Exception as e:
        print(
            f"SteamGridDB request failed for {appid}: {e}",
            file=sys.stderr
        )

    return None


def download_image(url, appid):
    if not url:
        return None

    BANNER_DIR.mkdir(parents=True, exist_ok=True)

    suffix = Path(
        urllib.parse.urlparse(url).path
    ).suffix.lower()

    if suffix not in [".jpg", ".jpeg", ".png", ".webp"]:
        suffix = ".jpg"

    output = BANNER_DIR / f"{appid}{suffix}"

    if output.exists() and output.stat().st_size > 0:
        return str(output)

    request = urllib.request.Request(
        url,
        headers={
            "User-Agent": "Steam-Banners/0.1"
        }
    )

    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            image_data = response.read()

        output.write_bytes(image_data)

        return str(output)

    except Exception as e:
        print(
            f"Image download failed for {appid}: {e}",
            file=sys.stderr
        )

        return None


def main():
    games = run_original_scanner()

    if not games:
        print("[]")
        return

    api_key = load_api_key()

    if not api_key:
        print(
            "SteamGridDB API key missing. Returning games without images.",
            file=sys.stderr
        )
        print(json.dumps(games, ensure_ascii=False))
        return

    for index, game in enumerate(games, start=1):
        appid = game.get("appid")
        name = game.get("name", "Unknown")

        print(
            f"SteamGridDB: {index}/{len(games)} - {name}",
            file=sys.stderr
        )

        if not appid:
            continue

        grid_url = get_grid_url(appid, api_key)

        if grid_url:
            image_path = download_image(grid_url, appid)

            if image_path:
                game["image"] = image_path
                game["imageUrl"] = grid_url

    print(
        json.dumps(
            games,
            ensure_ascii=False
        )
    )


if __name__ == "__main__":
    main()
