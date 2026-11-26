#!/usr/bin/env python3

import argparse
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

ARTWORK_SELECTIONS_FILE = (
    Path.home()
    / ".config"
    / "steambanners"
    / "artwork_selections.json"
)

API_BASE = (
    "https://www.steamgriddb.com/api/v2"
)

def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--list-artwork",
        nargs=2,
        metavar=("GAME_ID", "TITLE"),
        default=None,
        help=(
            "List SteamGridDB artwork "
            "for one Heroic game."
        )
    )

    parser.add_argument(
        "--select-artwork",
        nargs=5,
        metavar=(
            "GAME_ID",
            "STORE",
            "PROVIDER_ID",
            "TYPE",
            "URL"
        ),
        default=None,
        help=(
            "Save selected SteamGridDB "
            "artwork for one Heroic game."
        )
    )

    return parser.parse_args()

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

def get_sgdb_hero_urls(
    sgdb_id,
    api_key
):
    if not sgdb_id or not api_key:
        return []

    try:
        data = sgdb_request(
            f"{API_BASE}/heroes/game/"
            f"{sgdb_id}?limit=10",
            api_key
        )

        return [
            item.get("url")
            for item in data.get(
                "data",
                []
            )
            if item.get("url")
        ]

    except Exception as error:
        print(
            f"SteamGridDB hero lookup "
            f"failed for {sgdb_id}: "
            f"{error}",
            file=sys.stderr
        )

        return []


def get_sgdb_logo_urls(
    sgdb_id,
    api_key
):
    if not sgdb_id or not api_key:
        return []

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

        return [
            item.get("url")
            for item in logos
            if item.get("url")
        ]

    except Exception as error:
        print(
            f"SteamGridDB logo lookup "
            f"failed for {sgdb_id}: "
            f"{error}",
            file=sys.stderr
        )

        return []

def list_artwork_options(
    game_id,
    title
):
    api_key = load_api_key()

    if not api_key:
        return {
            "success": False,
            "error": (
                "SteamGridDB API key "
                "is not configured."
            )
        }

    sgdb_id = find_sgdb_game_id(
        title,
        api_key
    )

    if not sgdb_id:
        return {
            "success": False,
            "error": (
                "Game was not found "
                "on SteamGridDB."
            )
        }

    return {
        "success": True,
        "gameId": game_id,
        "title": title,
        "sgdb_id": sgdb_id,
        "logos": get_sgdb_logo_urls(
            sgdb_id,
            api_key
        ),
        "heroes": get_sgdb_hero_urls(
            sgdb_id,
            api_key
        ),
    }

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

def load_artwork_selections():
    try:
        data = json.loads(
            ARTWORK_SELECTIONS_FILE.read_text(
                encoding="utf-8"
            )
        )

        return (
            data
            if isinstance(data, dict)
            else {}
        )

    except FileNotFoundError:
        return {}

    except Exception as error:
        print(
            f"Could not load artwork "
            f"selections: {error}",
            file=sys.stderr
        )

        return {}


def save_artwork_selections(
    selections
):
    try:
        ARTWORK_SELECTIONS_FILE.parent.mkdir(
            parents=True,
            exist_ok=True
        )

        temporary = (
            ARTWORK_SELECTIONS_FILE
            .with_suffix(".tmp")
        )

        temporary.write_text(
            json.dumps(
                selections,
                ensure_ascii=False,
                indent=2
            ),
            encoding="utf-8"
        )

        temporary.replace(
            ARTWORK_SELECTIONS_FILE
        )

        return True

    except Exception as error:
        print(
            f"Could not save artwork "
            f"selections: {error}",
            file=sys.stderr
        )

        return False


def remove_heroic_artwork_variants(
    store,
    app_name,
    target_dir,
    keep_path=None
):
    cache_key = artwork_cache_key(
        store,
        app_name
    )

    keep = (
        Path(keep_path).resolve()
        if keep_path
        else None
    )

    for suffix in [
        ".jpg",
        ".jpeg",
        ".png",
        ".webp"
    ]:
        candidate = (
            target_dir
            / f"{cache_key}{suffix}"
        )

        if not candidate.exists():
            continue

        if (
            keep is not None
            and candidate.resolve() == keep
        ):
            continue

        try:
            candidate.unlink()

        except OSError:
            pass


def save_selected_artwork(
    game_id,
    store,
    app_name,
    artwork_type,
    url
):
    if artwork_type not in [
        "hero",
        "logo"
    ]:
        return {
            "success": False,
            "error": "Unknown artwork type."
        }

    if not game_id.startswith(
        "heroic:"
    ):
        return {
            "success": False,
            "error": "Invalid Heroic game ID."
        }

    parsed = urllib.parse.urlparse(
        url
    )

    hostname = (
        parsed.hostname or ""
    ).lower()

    if (
        parsed.scheme != "https"
        or not (
            hostname == "steamgriddb.com"
            or hostname.endswith(
                ".steamgriddb.com"
            )
        )
    ):
        return {
            "success": False,
            "error": (
                "Invalid SteamGridDB "
                "artwork URL."
            )
        }

    target_dir = (
        LOGO_DIR
        if artwork_type == "logo"
        else HERO_DIR
    )

    remove_heroic_artwork_variants(
        store,
        app_name,
        target_dir
    )

    path = download_cached_artwork(
        url,
        store,
        app_name,
        target_dir
    )

    if not path:
        return {
            "success": False,
            "error": (
                f"Could not save selected "
                f"{artwork_type}."
            )
        }

    selections = (
        load_artwork_selections()
    )

    game_selection = selections.get(
        game_id,
        {}
    )

    if not isinstance(
        game_selection,
        dict
    ):
        game_selection = {}

    game_selection[
        artwork_type
    ] = url

    selections[
        game_id
    ] = game_selection

    if not save_artwork_selections(
        selections
    ):
        return {
            "success": False,
            "error": (
                "Artwork was saved, but "
                "the selection could not "
                "be remembered."
            )
        }

    return {
        "success": True,
        "gameId": game_id,
        "type": artwork_type,
        "path": path,
        "url": url
    }

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

    game_id = (
        f"heroic:{store}:{app_name}"
    )

    selections = load_artwork_selections()

    game_selection = selections.get(
        game_id,
        {}
    )

    if not isinstance(
        game_selection,
        dict
    ):
        game_selection = {}

    manual_logo_url = (
        game_selection.get("logo")
        or ""
    )

    manual_hero_url = (
        game_selection.get("hero")
        or ""
    )

    manual_logo_selection = bool(
        manual_logo_url
    )

    manual_hero_selection = bool(
        manual_hero_url
    )

    logo_url = (
        manual_logo_url
        or game.get("art_logo")
        or ""
    )

    hero_url = (
        manual_hero_url
        or game.get("art_background")
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
        "gameId": game_id,
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
        "manualLogoSelection":
            manual_logo_selection,
        "manualHeroSelection":
            manual_hero_selection,
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
    args = parse_args()

    if args.select_artwork is not None:
        (
            game_id,
            store,
            provider_id,
            artwork_type,
            url
        ) = args.select_artwork

        result = save_selected_artwork(
            game_id,
            store,
            provider_id,
            artwork_type,
            url
        )

        print(
            json.dumps(
                result,
                ensure_ascii=False
            )
        )

        return

    if args.list_artwork is not None:
        game_id, title = (
            args.list_artwork
        )

        result = list_artwork_options(
            game_id,
            title
        )

        print(
            json.dumps(
                result,
                ensure_ascii=False
            )
        )

        return

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
