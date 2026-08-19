#!/usr/bin/env python3

import json
import shutil
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

STEAM_ASSET_BASE = (
    "https://cdn.cloudflare.steamstatic.com/steam/apps"
)


def load_api_key():
    try:
        key = KEY_FILE.read_text().strip()
        return key if key else None

    except Exception:
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
            "User-Agent": "Steam-Banners/0.2"
        }
    )

    with urllib.request.urlopen(
        request,
        timeout=15
    ) as response:
        return json.loads(
            response.read().decode("utf-8")
        )


def get_sgdb_game_id(appid, api_key):
    if not api_key:
        return None

    try:
        data = api_request(
            f"{API_BASE}/games/steam/{appid}",
            api_key
        )

        if data.get("success") and data.get("data"):
            return data["data"]["id"]

    except Exception as e:
        print(
            f"SteamGridDB game lookup failed "
            f"for {appid}: {e}",
            file=sys.stderr
        )

    return None


def get_logo_url(sgdb_id, api_key):
    if not sgdb_id or not api_key:
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
            f"SteamGridDB logo request failed "
            f"for game {sgdb_id}: {e}",
            file=sys.stderr
        )

    return None


def get_hero_url(sgdb_id, api_key):
    if not sgdb_id or not api_key:
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
            f"SteamGridDB hero request failed "
            f"for game {sgdb_id}: {e}",
            file=sys.stderr
        )

    return None


def get_steam_hero_url(appid):
    if not appid:
        return None

    return (
        f"{STEAM_ASSET_BASE}/"
        f"{appid}/library_hero.jpg"
    )


def steam_library_cache_roots():
    candidates = [
        Path.home()
        / ".local/share/Steam/appcache/librarycache",

        Path.home()
        / ".steam/steam/appcache/librarycache",

        Path.home()
        / ".var/app/com.valvesoftware.Steam"
        / ".local/share/Steam/appcache/librarycache",
    ]

    result = []

    for path in candidates:
        if path.exists() and path not in result:
            result.append(path)

    return result


def find_local_steam_hero(appid):
    """
    Find Steam's locally cached Library Hero.

    Steam may store it directly under:

        librarycache/<appid>/library_hero.jpg

    or inside a hash directory:

        librarycache/<appid>/<hash>/library_hero.jpg
    """

    if not appid:
        return None

    valid_suffixes = {
        ".jpg",
        ".jpeg",
        ".png",
        ".webp"
    }

    for cache_root in steam_library_cache_roots():
        app_dir = cache_root / str(appid)

        if not app_dir.exists():
            continue

        candidates = []

        try:
            for path in app_dir.rglob("library_hero.*"):
                if not path.is_file():
                    continue

                if path.suffix.lower() not in valid_suffixes:
                    continue

                # Do not use blurred variants.
                if "blur" in path.name.lower():
                    continue

                candidates.append(path)

        except Exception as e:
            print(
                f"Could not inspect Steam cache "
                f"for {appid}: {e}",
                file=sys.stderr
            )
            continue

        if not candidates:
            continue

        # Prefer the normal top-level file if one exists.
        candidates.sort(
            key=lambda path: (
                len(path.relative_to(app_dir).parts),
                str(path)
            )
        )

        return candidates[0]

    return None


def download_bytes(url):
    request = urllib.request.Request(
        url,
        headers={
            "User-Agent": "Steam-Banners/0.2"
        }
    )

    with urllib.request.urlopen(
        request,
        timeout=30
    ) as response:
        return response.read()


def normalize_logo(image_data, output):
    if Image is None:
        return False

    try:
        image = Image.open(
            BytesIO(image_data)
        ).convert("RGBA")

        alpha = image.getchannel("A")

        alpha_mask = alpha.point(
            lambda value: 255 if value > 8 else 0
        )

        bbox = alpha_mask.getbbox()

        if bbox:
            image = image.crop(bbox)

        if image.width <= 0 or image.height <= 0:
            return False

        padding_x = max(
            8,
            round(image.width * 0.05)
        )

        padding_y = max(
            8,
            round(image.height * 0.05)
        )

        canvas_width = (
            image.width + (padding_x * 2)
        )

        canvas_height = (
            image.height + (padding_y * 2)
        )

        canvas = Image.new(
            "RGBA",
            (
                canvas_width,
                canvas_height
            ),
            (0, 0, 0, 0)
        )

        canvas.alpha_composite(
            image,
            (
                padding_x,
                padding_y
            )
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

    output = LOGO_DIR / f"{appid}.png"

    if (
        output.exists()
        and output.stat().st_size > 0
    ):
        return str(output)

    try:
        image_data = download_bytes(url)

        if normalize_logo(
            image_data,
            output
        ):
            return str(output)

        suffix = Path(
            urllib.parse.urlparse(
                url
            ).path
        ).suffix.lower()

        if suffix not in [
            ".jpg",
            ".jpeg",
            ".png",
            ".webp"
        ]:
            suffix = ".png"

        fallback = (
            LOGO_DIR / f"{appid}{suffix}"
        )

        fallback.write_bytes(
            image_data
        )

        if Image is None:
            print(
                "Pillow is not installed; "
                "logo normalization was skipped.",
                file=sys.stderr
            )

        return str(fallback)

    except Exception as e:
        print(
            f"Logo download failed "
            f"for {appid}: {e}",
            file=sys.stderr
        )

        return None


def download_image(
    url,
    appid,
    target_dir
):
    if not url:
        return None

    target_dir.mkdir(
        parents=True,
        exist_ok=True
    )

    suffix = Path(
        urllib.parse.urlparse(
            url
        ).path
    ).suffix.lower()

    if suffix not in [
        ".jpg",
        ".jpeg",
        ".png",
        ".webp"
    ]:
        suffix = ".jpg"

    output = (
        target_dir / f"{appid}{suffix}"
    )

    if (
        output.exists()
        and output.stat().st_size > 0
    ):
        return str(output)

    try:
        image_data = download_bytes(
            url
        )

        output.write_bytes(
            image_data
        )

        return str(output)

    except Exception as e:
        print(
            f"Image download failed "
            f"for {appid}: {e}",
            file=sys.stderr
        )

        return None


def copy_local_steam_hero(appid):
    """
    Copy Steam's already cached Library Hero into the
    Steam Banners runtime artwork directory.
    """

    source = find_local_steam_hero(appid)

    if not source:
        return None

    HERO_DIR.mkdir(
        parents=True,
        exist_ok=True
    )

    suffix = source.suffix.lower()

    if suffix not in [
        ".jpg",
        ".jpeg",
        ".png",
        ".webp"
    ]:
        suffix = ".jpg"

    output = (
        HERO_DIR
        / f"{appid}_steam{suffix}"
    )

    if (
        output.exists()
        and output.stat().st_size > 0
    ):
        return str(output)

    try:
        shutil.copy2(
            source,
            output
        )

        return str(output)

    except Exception as e:
        print(
            f"Could not copy local Steam Hero "
            f"for {appid}: {e}",
            file=sys.stderr
        )

        return None


def download_steam_hero(appid):
    """
    Final fallback: try Steam's public CDN.
    """

    if not appid:
        return None

    HERO_DIR.mkdir(
        parents=True,
        exist_ok=True
    )

    output = (
        HERO_DIR / f"{appid}_steam.jpg"
    )

    if (
        output.exists()
        and output.stat().st_size > 0
    ):
        return str(output)

    url = get_steam_hero_url(
        appid
    )

    if not url:
        return None

    request = urllib.request.Request(
        url,
        headers={
            "User-Agent": "Steam-Banners/0.2"
        }
    )

    try:
        with urllib.request.urlopen(
            request,
            timeout=15
        ) as response:

            content_type = (
                response.headers.get(
                    "Content-Type",
                    ""
                )
            )

            if not content_type.startswith(
                "image/"
            ):
                return None

            image_data = response.read()

        if not image_data:
            return None

        output.write_bytes(
            image_data
        )

        return str(output)

    except Exception:
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
            "Steam artwork fallback will still be used.",
            file=sys.stderr
        )

    for index, game in enumerate(
        games,
        start=1
    ):
        appid = game.get(
            "appid"
        )

        name = game.get(
            "name",
            "Unknown"
        )

        print(
            f"Artwork: "
            f"{index}/{len(games)} - {name}",
            file=sys.stderr
        )

        if not appid:
            continue

        # ----------------------------------------------------
        # SteamGridDB lookup
        # ----------------------------------------------------

        sgdb_id = None

        if api_key:
            sgdb_id = get_sgdb_game_id(
                appid,
                api_key
            )

        # ----------------------------------------------------
        # LOGO
        #
        # SteamGridDB only for now.
        # ----------------------------------------------------

        if sgdb_id:
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
                    game["logo"] = (
                        logo_path
                    )

                    game["logoUrl"] = (
                        logo_url
                    )

                    game["logoSource"] = (
                        "steamgriddb"
                    )

        # ----------------------------------------------------
        # HERO
        #
        # Priority:
        #
        # 1. SteamGridDB Hero
        # 2. Local Steam librarycache
        # 3. Steam CDN
        # ----------------------------------------------------

        hero_path = None
        hero_url = None

        if sgdb_id:
            hero_url = get_hero_url(
                sgdb_id,
                api_key
            )

        # ----------------------------------------------------
        # 1. SteamGridDB Hero
        # ----------------------------------------------------

        if hero_url:
            hero_path = download_image(
                hero_url,
                appid,
                HERO_DIR
            )

            if hero_path:
                game["hero"] = (
                    hero_path
                )

                game["heroUrl"] = (
                    hero_url
                )

                game["heroSource"] = (
                    "steamgriddb"
                )

        # ----------------------------------------------------
        # 2. Local Steam librarycache
        # ----------------------------------------------------

        if not hero_path:
            local_steam_hero = (
                copy_local_steam_hero(
                    appid
                )
            )

            if local_steam_hero:
                hero_path = (
                    local_steam_hero
                )

                game["hero"] = (
                    local_steam_hero
                )

                game["heroSource"] = (
                    "steam-local"
                )

                print(
                    f"Local Steam Hero fallback: "
                    f"{name}",
                    file=sys.stderr
                )

        # ----------------------------------------------------
        # 3. Steam CDN
        # ----------------------------------------------------

        if not hero_path:
            steam_hero_path = (
                download_steam_hero(
                    appid
                )
            )

            if steam_hero_path:
                hero_path = (
                    steam_hero_path
                )

                game["hero"] = (
                    steam_hero_path
                )

                game["heroUrl"] = (
                    get_steam_hero_url(
                        appid
                    )
                )

                game["heroSource"] = (
                    "steam-cdn"
                )

                print(
                    f"Steam CDN Hero fallback: "
                    f"{name}",
                    file=sys.stderr
                )

    print(
        json.dumps(
            games,
            ensure_ascii=False
        )
    )


if __name__ == "__main__":
    main()
