#!/usr/bin/env python3

import hashlib
import urllib.parse
import urllib.request
import json
import sys
from pathlib import Path

CACHE_DIR = (
    Path.home()
    / ".cache"
    / "steambanners"
)

LOGO_DIR = CACHE_DIR / "logos"
HERO_DIR = CACHE_DIR / "heroes"

KEY_FILE = (
    Path.home()
    / ".config"
    / "steambanners"
    / "steamgriddb.key"
)

API_BASE = (
    "https://www.steamgriddb.com/api/v2"
)

def find_heroic_cache():
    candidates = [
        (
            Path.home()
            / ".var"
            / "app"
            / "com.heroicgameslauncher.hgl"
            / "config"
            / "heroic"
            / "store_cache"
        ),
        (
            Path.home()
            / ".config"
            / "heroic"
            / "store_cache"
        ),
    ]

    for candidate in candidates:
        if candidate.is_dir():
            return candidate

    return None


def load_json(path):
    try:
        return json.loads(
            path.read_text(
                encoding="utf-8"
            )
        )

    except Exception as error:
        print(
            f"Could not read {path}: {error}",
            file=sys.stderr
        )

        return {}

def artwork_cache_key(
    store,
    app_name
):
    identity = (
        f"heroic:{store}:{app_name}"
    )

    digest = hashlib.sha256(
        identity.encode("utf-8")
    ).hexdigest()[:20]

    return (
        f"heroic_{store}_{digest}"
    )


def download_cached_artwork(
    url,
    store,
    app_name,
    target_dir
):
    if not url:
        return ""

    try:
        parsed = urllib.parse.urlparse(
            url
        )

        if parsed.scheme not in [
            "http",
            "https"
        ]:
            return ""

        suffix = Path(
            parsed.path
        ).suffix.lower()

        if suffix not in [
            ".jpg",
            ".jpeg",
            ".png",
            ".webp"
        ]:
            suffix = ".jpg"

        cache_key = artwork_cache_key(
            store,
            app_name
        )

        target_dir.mkdir(
            parents=True,
            exist_ok=True
        )

        output = (
            target_dir
            / f"{cache_key}{suffix}"
        )

        if (
            output.exists()
            and output.stat().st_size > 0
        ):
            return str(output)

        request = urllib.request.Request(
            url,
            headers={
                "User-Agent":
                "Steam-Banners/0.2"
            }
        )

        with urllib.request.urlopen(
            request,
            timeout=20
        ) as response:
            content_type = (
                response.headers.get(
                    "Content-Type",
                    ""
                )
            )

            if (
                content_type
                and not content_type.startswith(
                    "image/"
                )
            ):
                return ""

            image_data = response.read()

        if not image_data:
            return ""

        temporary = output.with_suffix(
            output.suffix + ".tmp"
        )

        temporary.write_bytes(
            image_data
        )

        temporary.replace(
            output
        )

        return str(output)

    except Exception as error:
        print(
            f"Could not cache Heroic artwork "
            f"for {store}:{app_name}: "
            f"{error}",
            file=sys.stderr
        )

        return ""

def load_api_key():
    try:
        key = KEY_FILE.read_text(
            encoding="utf-8"
        ).strip()

        return key if key else None

    except Exception:
        return None


def sgdb_request(url, api_key):
    request = urllib.request.Request(
        url,
        headers={
            "Authorization":
                f"Bearer {api_key}",
            "User-Agent":
                "Steam-Banners/0.2",
        },
    )

    with urllib.request.urlopen(
        request,
        timeout=15,
    ) as response:
        return json.loads(
            response.read().decode(
                "utf-8"
            )
        )


def find_sgdb_game_id(
    title,
    api_key
):
    if not title or not api_key:
        return None

    try:
        encoded = urllib.parse.quote(
            title,
            safe=""
        )

        data = sgdb_request(
            f"{API_BASE}/search/"
            f"autocomplete/{encoded}",
            api_key
        )

        wanted = title.casefold()

        for item in data.get(
            "data",
            []
        ):
            name = str(
                item.get("name") or ""
            )

            if name.casefold() == wanted:
                return item.get("id")

    except Exception as error:
        print(
            f"SteamGridDB search failed "
            f"for {title}: {error}",
            file=sys.stderr
        )

    return None


def get_sgdb_hero_url(
    sgdb_id,
    api_key
):
    if not sgdb_id:
        return ""

    try:
        data = sgdb_request(
            f"{API_BASE}/heroes/game/"
            f"{sgdb_id}?limit=10",
            api_key
        )

        for item in data.get(
            "data",
            []
        ):
            url = item.get("url")

            if url:
                return url

    except Exception as error:
        print(
            f"SteamGridDB hero lookup "
            f"failed for {sgdb_id}: "
            f"{error}",
            file=sys.stderr
        )

    return ""


def get_sgdb_logo_url(
    sgdb_id,
    api_key
):
    if not sgdb_id:
        return ""

    try:
        data = sgdb_request(
            f"{API_BASE}/logos/game/"
            f"{sgdb_id}?limit=10",
            api_key
        )

        logos = data.get(
            "data",
            []
        )

        def priority(item):
            style = item.get(
                "style",
                ""
            )

            width = item.get(
                "width",
                0
            )

            height = item.get(
                "height",
                0
            )

            ratio = (
                width / height
                if width > 0
                and height > 0
                else 0
            )

            return (
                0
                if style == "official"
                else 1,
                0
                if ratio >= 2.0
                else 1,
            )

        logos.sort(
            key=priority
        )

        for item in logos:
            url = item.get("url")

            if url:
                return url

    except Exception as error:
        print(
            f"SteamGridDB logo lookup "
            f"failed for {sgdb_id}: "
            f"{error}",
            file=sys.stderr
        )

    return ""

def normalize_game(
    game,
    store,
    runner
):
    app_name = game.get("app_name")
    title = game.get("title")

    if not app_name or not title:
        return None

    install = game.get("install")

    if not isinstance(install, dict):
        install = {}

    if install.get("is_dlc") is True:
        return None

    logo_url = (
        game.get("art_logo")
        or ""
    )

    hero_url = (
        game.get("art_background")
        or ""
    )

    logo_path = download_cached_artwork(
        logo_url,
        store,
        app_name,
        LOGO_DIR
    )

    hero_path = download_cached_artwork(
        hero_url,
        store,
        app_name,
        HERO_DIR
    )

    if not logo_path or not hero_path:
        api_key = load_api_key()

        sgdb_id = find_sgdb_game_id(
            title,
            api_key
        )

        if sgdb_id:
            if not hero_path:
                sgdb_hero_url = (
                    get_sgdb_hero_url(
                        sgdb_id,
                        api_key
                    )
                )

                if sgdb_hero_url:
                    hero_path = (
                        download_cached_artwork(
                            sgdb_hero_url,
                            store,
                            app_name,
                            HERO_DIR
                        )
                    )

                    if hero_path:
                        hero_url = (
                            sgdb_hero_url
                        )

            if not logo_path:
                sgdb_logo_url = (
                    get_sgdb_logo_url(
                        sgdb_id,
                        api_key
                    )
                )

                if sgdb_logo_url:
                    logo_path = (
                        download_cached_artwork(
                            sgdb_logo_url,
                            store,
                            app_name,
                            LOGO_DIR
                        )
                    )

                    if logo_path:
                        logo_url = (
                            sgdb_logo_url
                        )

    return {
        "gameId": (
            f"heroic:{store}:{app_name}"
        ),
        "provider": "heroic",
        "store": store,
        "providerId": app_name,
        "name": title,
        "runner": (
            game.get("runner")
            or runner
        ),
        "installed": True,
        "installPath": (
            install.get("install_path")
            or ""
        ),
        "executable": (
            install.get("executable")
            or ""
        ),
        "cover": (
            game.get("art_cover")
            or ""
        ),
        "square": (
            game.get("art_square")
            or ""
        ),
        "logo": logo_path,
        "hero": hero_path,
        "logoUrl": logo_url,
        "heroUrl": hero_url,
        "storeUrl": (
            game.get("store_url")
            or ""
        ),
    }


def scan_library_installed(
    cache_dir,
    filename,
    list_key,
    store,
    runner
):
    data = load_json(
        cache_dir / filename
    )

    games = []

    for game in data.get(
        list_key,
        []
    ):
        if not isinstance(game, dict):
            continue

        if game.get("is_installed") is not True:
            continue

        normalized = normalize_game(
            game,
            store,
            runner
        )

        if normalized:
            games.append(normalized)

    return games


def scan_gog(cache_dir):
    library_data = load_json(
        cache_dir / "gog_library.json"
    )

    install_data = load_json(
        cache_dir / "gog_install_info.json"
    )

    library_games = {}

    for game in library_data.get(
        "games",
        []
    ):
        if not isinstance(game, dict):
            continue

        app_name = game.get(
            "app_name"
        )

        if app_name:
            library_games[
                str(app_name)
            ] = game

    installed_ids = set()

    for key, value in install_data.items():
        if key == "__timestamp":
            continue

        if not isinstance(value, dict):
            continue

        game = value.get("game")

        if not isinstance(game, dict):
            continue

        app_name = game.get(
            "app_name"
        )

        if app_name:
            installed_ids.add(
                str(app_name)
            )

    games = []

    for app_name in installed_ids:
        game = library_games.get(
            app_name
        )

        if not game:
            continue

        normalized = normalize_game(
            game,
            "gog",
            "gog"
        )

        if normalized:
            games.append(normalized)

    return games


def main():
    cache_dir = find_heroic_cache()

    if cache_dir is None:
        print("[]")
        return

    games = []

    games.extend(
        scan_library_installed(
            cache_dir,
            "legendary_library.json",
            "library",
            "epic",
            "legendary"
        )
    )

    games.extend(
        scan_gog(
            cache_dir
        )
    )

    games.extend(
        scan_library_installed(
            cache_dir,
            "nile_library.json",
            "library",
            "amazon",
            "nile"
        )
    )

    games.sort(
        key=lambda game:
        game["name"].casefold()
    )

    print(
        json.dumps(
            games,
            ensure_ascii=False,
            indent=2
        )
    )


if __name__ == "__main__":
    main()
