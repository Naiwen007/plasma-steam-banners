#!/usr/bin/env python3

import argparse
import json
import shutil
from pathlib import Path


CACHE_DIR = Path.home() / ".cache" / "steambanners"

LOGO_DIR = CACHE_DIR / "logos"
HERO_DIR = CACHE_DIR / "heroes"

METADATA_FILE = CACHE_DIR / "game_metadata.json"


def directory_size(path):
    if not path.exists():
        return 0

    total = 0

    for item in path.rglob("*"):
        try:
            if item.is_file():
                total += item.stat().st_size
        except OSError:
            pass

    return total


def file_size(path):
    try:
        if path.exists() and path.is_file():
            return path.stat().st_size
    except OSError:
        pass

    return 0


def file_count(path):
    if not path.exists():
        return 0

    count = 0

    for item in path.rglob("*"):
        try:
            if item.is_file():
                count += 1
        except OSError:
            pass

    return count


def get_status():
    logo_size = directory_size(LOGO_DIR)
    hero_size = directory_size(HERO_DIR)
    metadata_size = file_size(METADATA_FILE)

    logo_count = file_count(LOGO_DIR)
    hero_count = file_count(HERO_DIR)

    artwork_size = (
        logo_size
        + hero_size
    )

    return {
        "success": True,

        "artwork": {
            "size": artwork_size,
            "files": (
                logo_count
                + hero_count
            ),
            "logos": {
                "size": logo_size,
                "files": logo_count
            },
            "heroes": {
                "size": hero_size,
                "files": hero_count
            }
        },

        "metadata": {
            "size": metadata_size,
            "exists": METADATA_FILE.exists()
        },

        "total_size": (
            artwork_size
            + metadata_size
        )
    }


def clear_directory(path):
    if path.exists():
        shutil.rmtree(path)

    path.mkdir(
        parents=True,
        exist_ok=True
    )


def clear_artwork():
    clear_directory(LOGO_DIR)
    clear_directory(HERO_DIR)

    return {
        "success": True,
        "cleared": "artwork"
    }


def clear_metadata():
    if METADATA_FILE.exists():
        METADATA_FILE.unlink()

    return {
        "success": True,
        "cleared": "metadata"
    }


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "command",
        choices=[
            "status",
            "clear-artwork",
            "clear-metadata"
        ]
    )

    return parser.parse_args()


def main():
    args = parse_args()

    try:
        if args.command == "status":
            result = get_status()

        elif args.command == "clear-artwork":
            result = clear_artwork()

        elif args.command == "clear-metadata":
            result = clear_metadata()

        else:
            raise RuntimeError(
                "Unknown cache command."
            )

        print(
            json.dumps(
                result,
                ensure_ascii=False
            )
        )

    except Exception as error:
        print(
            json.dumps({
                "success": False,
                "error": str(error)
            })
        )


if __name__ == "__main__":
    main()
