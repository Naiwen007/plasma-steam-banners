#!/usr/bin/env python3

import json
import re
import sys
import urllib.request
from pathlib import Path


REPOSITORY = "Naiwen007/plasma-steam-banners"

API_URL = (
    "https://api.github.com/repos/"
    f"{REPOSITORY}/releases/latest"
)

ROOT_DIR = Path(__file__).resolve().parents[2]
METADATA_FILE = ROOT_DIR / "metadata.json"


def version_tuple(version):
    match = re.match(
        r"^v?(\d+)\.(\d+)\.(\d+)",
        version.strip()
    )

    if not match:
        raise ValueError(
            f"Invalid version: {version}"
        )

    return tuple(
        int(part)
        for part in match.groups()
    )


def read_installed_version():
    data = json.loads(
        METADATA_FILE.read_text(
            encoding="utf-8"
        )
    )

    return data["KPlugin"]["Version"]


def get_latest_release():
    request = urllib.request.Request(
        API_URL,
        headers={
            "Accept": "application/vnd.github+json",
            "User-Agent": "Steam-Banners-Updater"
        }
    )

    with urllib.request.urlopen(
        request,
        timeout=15
    ) as response:
        return json.loads(
            response.read().decode("utf-8")
        )


def find_release_asset(release, version):
    expected_name = (
        f"plasma-steam-banners-{version}.tar.gz"
    )

    assets = release.get("assets", [])

    for asset in assets:
        if asset.get("name") == expected_name:
            return asset

    for asset in assets:
        if asset.get("name", "").endswith(".tar.gz"):
            return asset

    return None


def main():
    try:
        installed = read_installed_version()

        release = get_latest_release()

        latest = release.get(
            "tag_name",
            ""
        ).lstrip("v")

        if not latest:
            raise RuntimeError(
                "GitHub release has no version tag."
            )

        asset = find_release_asset(
            release,
            latest
        )

        result = {
            "success": True,
            "installed": installed,
            "latest": latest,
            "update_available":
                version_tuple(latest)
                > version_tuple(installed),
            "release_url":
                release.get("html_url", ""),
            "asset_name":
                asset.get("name", "")
                if asset else "",
            "asset_url":
                asset.get(
                    "browser_download_url",
                    ""
                )
                if asset else ""
        }

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

        sys.exit(1)


if __name__ == "__main__":
    main()
