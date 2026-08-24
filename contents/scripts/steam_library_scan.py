#!/usr/bin/env python3

import json
import re
from pathlib import Path


def find_steam_root():
    """
    Returns the Steam installation directory containing steamapps/.
    """

    candidates = [
        Path.home() / ".local/share/Steam",
        Path.home() / ".steam/steam",
        Path.home() / ".var/app/com.valvesoftware.Steam/.local/share/Steam",
    ]

    for path in candidates:
        if (path / "steamapps/libraryfolders.vdf").exists():
            return path

    return None


def parse_simple_vdf(filename):
    data = {}

    with open(filename, encoding="utf-8", errors="ignore") as f:
        inside_appstate = False

        for line in f:
            line = line.strip()

            if line == '"AppState"':
                inside_appstate = True
                continue

            if inside_appstate:

                if line.startswith("}"):
                    break

                match = re.match(r'"([^"]+)"\s+"([^"]*)"', line)

                if match:
                    key, value = match.groups()
                    data[key] = value

    return data


def find_libraries(steam_root):
    """
    Returns available and unavailable Steam library paths.
    """

    libraries = []
    unavailable_libraries = []

    vdf = steam_root / "steamapps/libraryfolders.vdf"

    with open(vdf, encoding="utf-8", errors="ignore") as f:

        for line in f:

            match = re.search(
                r'"path"\s+"([^"]+)"',
                line
            )

            if not match:
                continue

            library = Path(
                match.group(1)
            )

            if library.exists():
                if library not in libraries:
                    libraries.append(library)
            else:
                if library not in unavailable_libraries:
                    unavailable_libraries.append(
                        library
                    )

    return libraries, unavailable_libraries

def write_library_status(
    steam_root,
    libraries,
    unavailable_libraries
):
    cache_dir = (
        Path.home()
        / ".cache"
        / "steambanners"
    )

    cache_dir.mkdir(
        parents=True,
        exist_ok=True
    )

    status_file = (
        cache_dir
        / "library_status.json"
    )

    data = {
        "steam_found": steam_root is not None,
        "steam_root": (
            str(steam_root)
            if steam_root is not None
            else ""
        ),
        "available_libraries": [
            str(path)
            for path in libraries
        ],
        "unavailable_libraries": [
            str(path)
            for path in unavailable_libraries
        ],
    }

    status_file.write_text(
        json.dumps(
            data,
            indent=4,
            ensure_ascii=False
        )
        + "\n",
        encoding="utf-8"
    )

def scan_games(libraries):

    games = []

    for library in libraries:

        steamapps = library / "steamapps"

        if not steamapps.exists():
            continue

        for manifest in steamapps.glob("appmanifest_*.acf"):

            app = parse_simple_vdf(manifest)

            if "appid" not in app:
                continue

            name = app.get("name", "Unknown")

            ignored_keywords = [
                "Proton",
                "Steam Linux Runtime",
                "Steamworks Common Redistributables",
                "Steam Runtime",
                "Proton Experimental",
                "Proton Hotfix",
                "Steam Shader Pre-Caching",
                "SteamVR"
            ]

            if any(keyword.lower() in name.lower() for keyword in ignored_keywords):
                continue

            games.append(
                {
                    "appid": int(app["appid"]),
                    "name": name,
                    "library": str(library),
                    "manifest": str(manifest),
                }
            )

    games.sort(key=lambda g: g["name"].lower())

    return games


def main():

    steam = find_steam_root()

    if steam is None:
        write_library_status(
            None,
            [],
            []
        )

        print("[]")
        return

    libraries, unavailable_libraries = (
        find_libraries(steam)
    )

    write_library_status(
        steam,
        libraries,
        unavailable_libraries
    )

    games = scan_games(libraries)

    print(
        json.dumps(
            games,
            ensure_ascii=False
        )
    )

if __name__ == "__main__":
    main()
