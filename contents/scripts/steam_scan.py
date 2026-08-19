#!/usr/bin/env python3

import argparse
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


# ============================================================
# COMMAND LINE
# ============================================================

def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--refresh-artwork",
        action="store_true",
        help=(
            "Query SteamGridDB and update artwork. "
            "Without this option only local/cache artwork is used."
        )
    )

    return parser.parse_args()


# ============================================================
# STEAMGRIDDB
# ============================================================

def load_api_key():
    try:
        key = KEY_FILE.read_text().strip()
        return key if key else None

    except Exception:
        return None


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


def get_logo_urls(sgdb_id, api_key):
    """
    Return SteamGridDB logo URLs ordered by closeness to a 16:9 canvas.
    """
    if not sgdb_id or not api_key:
        return []

    try:
        params = urllib.parse.urlencode({
            "limit": "10"
        })

        data = api_request(
            f"{API_BASE}/logos/game/{sgdb_id}?{params}",
            api_key
        )

        if data.get("success") and data.get("data"):
            logos = data["data"]

            target_ratio = 16 / 9

            def ratio_distance(item):
                width = item.get("width", 0)
                height = item.get("height", 0)

                if width <= 0 or height <= 0:
                    return 999

                ratio = width / height

                return abs(
                    ratio - target_ratio
                )

            logos.sort(
                key=ratio_distance
            )

            return [
                item.get("url")
                for item in logos
                if item.get("url")
            ]

    except Exception as e:
        print(
            f"SteamGridDB logo request failed "
            f"for game {sgdb_id}: {e}",
            file=sys.stderr
        )

    return []


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


# ============================================================
# INSTALLED STEAM GAMES
# ============================================================

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


# ============================================================
# STEAM LIBRARY CACHE
# ============================================================

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

                if "blur" in path.name.lower():
                    continue

                candidates.append(path)

        except Exception as e:
            print(
                f"Could not inspect Steam Hero cache "
                f"for {appid}: {e}",
                file=sys.stderr
            )
            continue

        if not candidates:
            continue

        candidates.sort(
            key=lambda path: (
                len(path.relative_to(app_dir).parts),
                str(path)
            )
        )

        return candidates[0]

    return None


def find_local_steam_logo(appid):
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
            for path in app_dir.rglob("logo.*"):
                if not path.is_file():
                    continue

                if path.suffix.lower() not in valid_suffixes:
                    continue

                candidates.append(path)

        except Exception as e:
            print(
                f"Could not inspect Steam Logo cache "
                f"for {appid}: {e}",
                file=sys.stderr
            )
            continue

        if not candidates:
            continue

        candidates.sort(
            key=lambda path: (
                len(path.relative_to(app_dir).parts),
                str(path)
            )
        )

        return candidates[0]

    return None


# ============================================================
# EXISTING STEAM BANNERS CACHE
# ============================================================

def find_cached_logo(appid):
    """
    Prefer existing SteamGridDB artwork over Steam fallback.
    """

    if not LOGO_DIR.exists():
        return None, None

    for suffix in [
        ".png",
        ".jpg",
        ".jpeg",
        ".webp"
    ]:
        sgdb_file = LOGO_DIR / f"{appid}{suffix}"

        if (
            sgdb_file.exists()
            and sgdb_file.stat().st_size > 0
        ):
            return str(sgdb_file), "steamgriddb-cache"

    for suffix in [
        ".png",
        ".jpg",
        ".jpeg",
        ".webp"
    ]:
        steam_file = LOGO_DIR / f"{appid}_steam{suffix}"

        if (
            steam_file.exists()
            and steam_file.stat().st_size > 0
        ):
            return str(steam_file), "steam-local-cache"

    return None, None


def find_cached_hero(appid):
    """
    Prefer existing SteamGridDB artwork over Steam fallback.
    """

    if not HERO_DIR.exists():
        return None, None

    # SteamGridDB files use <appid>.<ext>
    for suffix in [
        ".jpg",
        ".jpeg",
        ".png",
        ".webp"
    ]:
        sgdb_file = HERO_DIR / f"{appid}{suffix}"

        if (
            sgdb_file.exists()
            and sgdb_file.stat().st_size > 0
        ):
            return str(sgdb_file), "steamgriddb-cache"

    # Steam fallback files use <appid>_steam.<ext>
    for suffix in [
        ".jpg",
        ".jpeg",
        ".png",
        ".webp"
    ]:
        steam_file = HERO_DIR / f"{appid}_steam{suffix}"

        if (
            steam_file.exists()
            and steam_file.stat().st_size > 0
        ):
            return str(steam_file), "steam-cache"

    return None, None


# ============================================================
# IMAGE HELPERS
# ============================================================

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


def logo_has_transparent_background(image_data):
    """
    Return True when the image has enough real transparency to work
    as an overlay logo. Opaque rectangular artwork is rejected.
    """
    if Image is None:
        return True

    try:
        image = Image.open(
            BytesIO(image_data)
        ).convert("RGBA")

        alpha = image.getchannel("A")
        histogram = alpha.histogram()

        total_pixels = image.width * image.height

        if total_pixels <= 0:
            return False

        transparent_pixels = sum(
            histogram[:32]
        )

        transparent_ratio = (
            transparent_pixels / total_pixels
        )

        return transparent_ratio >= 0.02

    except Exception as e:
        print(
            f"Could not inspect logo transparency: {e}",
            file=sys.stderr
        )

        return False


def normalize_logo(image_data, output):
    if Image is None:
        return False

    try:
        image = Image.open(
            BytesIO(image_data)
        ).convert("RGBA")

        alpha = image.getchannel("A")

        alpha_mask = alpha.point(
            lambda value: 255 if value > 32 else 0
        )

        bbox = alpha_mask.getbbox()

        if bbox:
            image = image.crop(bbox)

        if image.width <= 0 or image.height <= 0:
            return False

        padding_x = max(
            4,
            round(image.width * 0.02)
        )

        padding_y = max(
            4,
            round(image.height * 0.02)
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


# ============================================================
# LOGOS
# ============================================================

def download_logo(url, appid, overwrite=False):
    if not url:
        return None

    LOGO_DIR.mkdir(
        parents=True,
        exist_ok=True
    )

    output = LOGO_DIR / f"{appid}.png"

    if (
        not overwrite
        and output.exists()
        and output.stat().st_size > 0
    ):
        return str(output)

    try:
        image_data = download_bytes(url)

        if not logo_has_transparent_background(
            image_data
        ):
            print(
                f"Rejected SteamGridDB Logo without enough transparency "
                f"for {appid}",
                file=sys.stderr
            )

            return None

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

        return str(fallback)

    except Exception as e:
        print(
            f"Logo download failed "
            f"for {appid}: {e}",
            file=sys.stderr
        )

        return None


def copy_local_steam_logo(appid):
    source = find_local_steam_logo(appid)

    if not source:
        return None

    LOGO_DIR.mkdir(
        parents=True,
        exist_ok=True
    )

    output = (
        LOGO_DIR
        / f"{appid}_steam.png"
    )

    if (
        output.exists()
        and output.stat().st_size > 0
    ):
        return str(output)

    try:
        image_data = source.read_bytes()

        if normalize_logo(
            image_data,
            output
        ):
            return str(output)

        suffix = source.suffix.lower()

        if suffix not in [
            ".jpg",
            ".jpeg",
            ".png",
            ".webp"
        ]:
            suffix = ".png"

        fallback = (
            LOGO_DIR
            / f"{appid}_steam{suffix}"
        )

        shutil.copy2(
            source,
            fallback
        )

        return str(fallback)

    except Exception as e:
        print(
            f"Could not process local Steam Logo "
            f"for {appid}: {e}",
            file=sys.stderr
        )

        return None


# ============================================================
# HEROES
# ============================================================

def normalize_hero(image_data, output, max_width=1280):
    """
    Cache hero artwork at a reasonable maximum width without upscaling.
    """
    if Image is None:
        return False

    try:
        image = Image.open(
            BytesIO(image_data)
        )

        # Never upscale smaller artwork
        if image.width <= max_width:
            output.write_bytes(image_data)
            return True

        new_height = round(
            image.height
            * max_width
            / image.width
        )

        image = image.resize(
            (
                max_width,
                new_height
            ),
            Image.Resampling.LANCZOS
        )

        suffix = output.suffix.lower()

        if suffix in [".jpg", ".jpeg"]:
            image = image.convert("RGB")

            image.save(
                output,
                format="JPEG",
                quality=88,
                optimize=True
            )

        elif suffix == ".webp":
            image.save(
                output,
                format="WEBP",
                quality=88,
                method=6
            )

        else:
            image.save(
                output,
                format="PNG",
                optimize=True
            )

        return True

    except Exception as e:
        print(
            f"Hero normalization failed: {e}",
            file=sys.stderr
        )

        return False


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

        if normalize_hero(
            image_data,
        output
        ):
            return str(output)

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
        image_data = source.read_bytes()

        if normalize_hero(
            image_data,
            output
        ):
            return str(output)

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


def get_steam_hero_url(appid):
    if not appid:
        return None

    return (
        f"{STEAM_ASSET_BASE}/"
        f"{appid}/library_hero.jpg"
    )


def download_steam_hero(appid):
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

    try:
        request = urllib.request.Request(
            url,
            headers={
                "User-Agent": "Steam-Banners/0.2"
            }
        )

        with urllib.request.urlopen(
            request,
            timeout=15
        ) as response:

            content_type = response.headers.get(
                "Content-Type",
                ""
            )

            if not content_type.startswith("image/"):
                return None

            image_data = response.read()

        if not image_data:
            return None

        if normalize_hero(
            image_data,
            output
        ):
            return str(output)

        output.write_bytes(
            image_data
        )

        return str(output)

    except Exception:
        return None


# ============================================================
# FAST LOCAL ARTWORK
# ============================================================

def apply_local_artwork(game):
    appid = game.get("appid")

    if not appid:
        return

    # --------------------------------------------------------
    # Logo
    # --------------------------------------------------------

    logo_path, logo_source = find_cached_logo(
        appid
    )

    if logo_path:
        game["logo"] = logo_path
        game["logoSource"] = logo_source

    else:
        local_logo = copy_local_steam_logo(
            appid
        )

        if local_logo:
            game["logo"] = local_logo
            game["logoSource"] = "steam-local"

    # --------------------------------------------------------
    # Hero
    # --------------------------------------------------------

    hero_path, hero_source = find_cached_hero(
        appid
    )

    if hero_path:
        game["hero"] = hero_path
        game["heroSource"] = hero_source

    else:
        local_hero = copy_local_steam_hero(
            appid
        )

        if local_hero:
            game["hero"] = local_hero
            game["heroSource"] = "steam-local"


# ============================================================
# FULL ARTWORK REFRESH
# ============================================================

def refresh_artwork(game, api_key):
    appid = game.get("appid")
    name = game.get("name", "Unknown")

    if not appid:
        return

    sgdb_id = None

    if api_key:
        sgdb_id = get_sgdb_game_id(
            appid,
            api_key
        )

    # ========================================================
    # LOGO
    # ========================================================

    logo_path = None

    if sgdb_id:
        logo_urls = get_logo_urls(
            sgdb_id,
            api_key
        )

        for logo_url in logo_urls:
            logo_path = download_logo(
                logo_url,
                appid,
                overwrite=True
            )

            if logo_path:
                game["logo"] = logo_path
                game["logoUrl"] = logo_url
                game["logoSource"] = "steamgriddb"
                break

    if not logo_path:
        # Remove stale SGDB Logo so startup cannot
        # pick an old rejected opaque image.
        for suffix in [
            ".png",
            ".jpg",
            ".jpeg",
            ".webp"
        ]:
            stale_logo = (
                LOGO_DIR
                / f"{appid}{suffix}"
            )

            if stale_logo.exists():
                try:
                    stale_logo.unlink()
                except OSError:
                    pass

    if not logo_path:
        local_logo = copy_local_steam_logo(
            appid
        )

        if local_logo:
            game["logo"] = local_logo
            game["logoSource"] = "steam-local"

            print(
                f"Local Steam Logo fallback: {name}",
                file=sys.stderr
            )

    # ========================================================
    # HERO
    # ========================================================

    hero_path = None

    if sgdb_id:
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
                game["heroSource"] = "steamgriddb"

    if not hero_path:
        local_hero = copy_local_steam_hero(
            appid
        )

        if local_hero:
            hero_path = local_hero

            game["hero"] = local_hero
            game["heroSource"] = "steam-local"

            print(
                f"Local Steam Hero fallback: {name}",
                file=sys.stderr
            )

    if not hero_path:
        cdn_hero = download_steam_hero(
            appid
        )

        if cdn_hero:
            game["hero"] = cdn_hero
            game["heroUrl"] = get_steam_hero_url(
                appid
            )
            game["heroSource"] = "steam-cdn"

            print(
                f"Steam CDN Hero fallback: {name}",
                file=sys.stderr
            )


# ============================================================
# MAIN
# ============================================================

def main():
    args = parse_args()

    games = run_original_scanner()

    if not games:
        print("[]")
        return

    api_key = load_api_key()

    if args.refresh_artwork:
        print(
            "### FULL ARTWORK REFRESH ###",
            file=sys.stderr
        )

    else:
        print(
            "### FAST LOCAL SCAN ###",
            file=sys.stderr
        )

    for index, game in enumerate(
        games,
        start=1
    ):
        name = game.get(
            "name",
            "Unknown"
        )

        print(
            f"{index}/{len(games)} - {name}",
            file=sys.stderr
        )

        if args.refresh_artwork:
            refresh_artwork(
                game,
                api_key
            )

        else:
            apply_local_artwork(
                game
            )

    print(
        json.dumps(
            games,
            ensure_ascii=False
        )
    )


if __name__ == "__main__":
    main()
