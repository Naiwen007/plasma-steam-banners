#!/usr/bin/env python3

import json
import subprocess
import sys
import urllib.parse
import urllib.request
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
ORIGINAL_SCANNER = SCRIPT_DIR / "steam_scan_original.py"

DATA_DIR = SCRIPT_DIR.parent / "data"
LOGO_DIR = DATA_DIR / "logos"
HERO_DIR = DATA_DIR / "heroes"

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


def api_request(url, api_key):
    request = urllib.request.Request(
        url,
        headers={
            "Authorization": f"Bearer {api_key}",
            "User-Agent": "Steam-Banners/0.1"
        }
    )

    with urllib.request.urlopen(request, timeout=15) as response:
        return json.loads(response.read().decode("utf-8"))


def get_sgdb_game_id(appid, api_key):
    try:
        data = api_request(
            f"{API_BASE}/games/steam/{appid}",
            api_key
        )

        if data.get("success") and data.get("data"):
            return data["data"]["id"]

    except Exception as e:
        print(
            f"SteamGridDB game lookup failed for {appid}: {e}",
            file=sys.stderr
        )

    return None


def get_logo_url(sgdb_id, api_key):
    if not sgdb_id:
        return None

    try:
        params = urllib.parse.urlencode({
            "limit": "1"
        })

        data = api_request(
            f"{API_BASE}/logos/game/{sgdb_id}?{params}",
            api_key
        )

        if data.get("success") and data.get("data"):
            return data["data"][0].get("url")

    except Exception as e:
        print(
            f"SteamGridDB logo request failed for game {sgdb_id}: {e}",
            file=sys.stderr
        )

    return None


def get_hero_url(sgdb_id, api_key):
    if not sgdb_id:
        return None

    try:
        params = urllib.parse.urlencode({
            "limit": "1"
        })

        data = api_request(
            f"{API_BASE}/heroes/game/{sgdb_id}?{params}",
            api_key
        )

        if data.get("success") and data.get("data"):
            return data["data"][0].get("url")

    except Exception as e:
        print(
            f"SteamGridDB hero request failed for game {sgdb_id}: {e}",
            file=sys.stderr
        )

    return None


def download_image(url, appid, target_dir):
    if not url:
        return None

    target_dir.mkdir(parents=True, exist_ok=True)

    suffix = Path(
        urllib.parse.urlparse(url).path
    ).suffix.lower()

    if suffix not in [".jpg", ".jpeg", ".png", ".webp"]:
        suffix = ".jpg"

    output = target_dir / f"{appid}{suffix}"

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

        print(
            json.dumps(
                games,
                ensure_ascii=False
            )
        )

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

        sgdb_id = get_sgdb_game_id(appid, api_key)

        if not sgdb_id:
            continue

        logo_url = get_logo_url(sgdb_id, api_key)

        if logo_url:
            logo_path = download_image(
                logo_url,
                appid,
                LOGO_DIR
            )

            if logo_path:
                game["logo"] = logo_path
                game["logoUrl"] = logo_url

        hero_url = get_hero_url(sgdb_id, api_key)

        if hero_url:
            hero_path = download_image(
                hero_url,
                appid,
                HERO_DIR
            )

            if hero_path:
                game["hero"] = hero_path
                game["heroUrl"] = hero_url

    print(
        json.dumps(
            games,
            ensure_ascii=False
        )
    )


if __name__ == "__main__":
    main()
