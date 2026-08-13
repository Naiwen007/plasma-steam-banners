#!/usr/bin/env python3

import json
import subprocess
import sys
import urllib.parse
import urllib.request
from io import BytesIO
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    Image = None


SCRIPT_DIR = Path(__file__).resolve().parent
ORIGINAL_SCANNER = SCRIPT_DIR / "steam_library_scan.py"

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
        return json.loads(
            response.read().decode("utf-8")
        )


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


def download_bytes(url):
    request = urllib.request.Request(
        url,
        headers={
            "User-Agent": "Steam-Banners/0.1"
        }
    )

    with urllib.request.urlopen(request, timeout=30) as response:
        return response.read()


def normalize_logo(image_data, output):
    if Image is None:
        return False

    try:
        image = Image.open(BytesIO(image_data)).convert("RGBA")

        # Trim almost-transparent outer pixels.
        alpha = image.getchannel("A")

        alpha_mask = alpha.point(
            lambda value: 255 if value > 8 else 0
        )

        bbox = alpha_mask.getbbox()

        if bbox:
            image = image.crop(bbox)

        if image.width <= 0 or image.height <= 0:
            return False

        # Add proportional transparent padding instead of forcing
        # every logo onto the same fixed-size canvas.
        padding_x = max(8, round(image.width * 0.05))
        padding_y = max(8, round(image.height * 0.05))

        canvas_width = image.width + (padding_x * 2)
        canvas_height = image.height + (padding_y * 2)

        canvas = Image.new(
            "RGBA",
            (canvas_width, canvas_height),
            (0, 0, 0, 0)
        )

        canvas.alpha_composite(
            image,
            (padding_x, padding_y)
        )

        canvas.save(
            output,
            format="PNG",
            optimize=True
        )

        return True

    except Exception as e:
        print(
            f"Logo normalization failed: {e}",
            file=sys.stderr
        )

        return False


def download_logo(url, appid):
    if not url:
        return None

    LOGO_DIR.mkdir(
        parents=True,
        exist_ok=True
    )

    # Normalized logos are always PNG.
    output = LOGO_DIR / f"{appid}.png"

    if output.exists() and output.stat().st_size > 0:
        return str(output)

    try:
        image_data = download_bytes(url)

        if normalize_logo(image_data, output):
            return str(output)

        # Pillow missing or normalization failed.
        # Fall back to the original SteamGridDB image.
        suffix = Path(
            urllib.parse.urlparse(url).path
        ).suffix.lower()

        if suffix not in [
            ".jpg",
            ".jpeg",
            ".png",
            ".webp"
        ]:
            suffix = ".png"

        fallback = LOGO_DIR / f"{appid}{suffix}"

        fallback.write_bytes(image_data)

        if Image is None:
            print(
                "Pillow is not installed; "
                "logo normalization was skipped.",
                file=sys.stderr
            )

        return str(fallback)

    except Exception as e:
        print(
            f"Logo download failed for {appid}: {e}",
            file=sys.stderr
        )

        return None


def download_image(url, appid, target_dir):
    if not url:
        return None

    target_dir.mkdir(
        parents=True,
        exist_ok=True
    )

    suffix = Path(
        urllib.parse.urlparse(url).path
    ).suffix.lower()

    if suffix not in [
        ".jpg",
        ".jpeg",
        ".png",
        ".webp"
    ]:
        suffix = ".jpg"

    output = target_dir / f"{appid}{suffix}"

    if output.exists() and output.stat().st_size > 0:
        return str(output)

    try:
        image_data = download_bytes(url)

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
            "SteamGridDB API key missing. "
            "Returning games without images.",
            file=sys.stderr
        )

        print(
            json.dumps(
                games,
                ensure_ascii=False
            )
        )

        return

    for index, game in enumerate(
        games,
        start=1
    ):
        appid = game.get("appid")
        name = game.get(
            "name",
            "Unknown"
        )

        print(
            f"SteamGridDB: "
            f"{index}/{len(games)} - {name}",
            file=sys.stderr
        )

        if not appid:
            continue

        sgdb_id = get_sgdb_game_id(
            appid,
            api_key
        )

        if not sgdb_id:
            continue

        logo_url = get_logo_url(
            sgdb_id,
            api_key
        )

        if logo_url:
            logo_path = download_logo(
                logo_url,
                appid
            )

            if logo_path:
                game["logo"] = logo_path
                game["logoUrl"] = logo_url

        hero_url = get_hero_url(
            sgdb_id,
            api_key
        )

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
