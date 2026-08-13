#!/usr/bin/env python3

import json
import os
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
    Returns every Steam library path.
    """

    libraries = []

    vdf = steam_root / "steamapps/libraryfolders.vdf"

    with open(vdf, encoding="utf-8", errors="ignore") as f:

        current_path = None

        for line in f:

            m = re.search(r'"path"\s+"([^"]+)"', line)

            if m:
                current_path = Path(m.group(1))

                if current_path.exists():
                    libraries.append(current_path)

    return libraries


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
        return

    libraries = find_libraries(steam)

    games = scan_games(libraries)

    data_dir = Path.home() / ".cache/com.new.steambanners"

    data_dir.mkdir(
        parents=True,
        exist_ok=True
    )

    cache_file = data_dir / "games.json"

    with open(cache_file, "w", encoding="utf-8") as f:
        json.dump(
            games,
            f,
            indent=4,
            ensure_ascii=False
            )
    print(json.dumps(games, ensure_ascii=False))

if __name__ == "__main__":
    main()
