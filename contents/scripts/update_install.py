#!/usr/bin/env python3

import argparse
import json
import shutil
import subprocess
import sys
import tarfile
import tempfile
import urllib.request
from pathlib import Path

from update_check import (
    find_release_asset,
    get_latest_release,
    read_installed_version,
    version_tuple,
)


DEFAULT_PREFIX = Path.home() / ".local"


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--prefix",
        type=Path,
        default=DEFAULT_PREFIX,
        help="Installation prefix. Defaults to ~/.local."
    )

    parser.add_argument(
        "--allow-current",
        action="store_true",
        help=(
            "Allow installing the currently installed version. "
            "Intended for testing only."
        )
    )

    return parser.parse_args()


def download_file(url, destination):
    request = urllib.request.Request(
        url,
        headers={
            "User-Agent": "Steam-Banners-Updater"
        }
    )

    with urllib.request.urlopen(
        request,
        timeout=60
    ) as response:
        with destination.open("wb") as output:
            shutil.copyfileobj(
                response,
                output
            )


def safe_extract(archive_path, destination):
    destination = destination.resolve()

    with tarfile.open(
        archive_path,
        "r:gz"
    ) as archive:

        for member in archive.getmembers():
            target = (
                destination / member.name
            ).resolve()

            try:
                target.relative_to(destination)
            except ValueError:
                raise RuntimeError(
                    "Unsafe path found in update archive."
                )

        archive.extractall(destination)


def find_source_directory(extract_dir):
    candidates = [
        path
        for path in extract_dir.iterdir()
        if path.is_dir()
        and (path / "CMakeLists.txt").exists()
        and (path / "metadata.json").exists()
    ]

    if len(candidates) != 1:
        raise RuntimeError(
            "Could not locate Steam Banners source directory."
        )

    return candidates[0]


def run_command(command, cwd=None):
    result = subprocess.run(
        command,
        cwd=cwd,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT
    )

    if result.returncode != 0:
        raise RuntimeError(
            "Command failed:\n"
            + " ".join(str(part) for part in command)
            + "\n\n"
            + result.stdout[-4000:]
        )

    return result.stdout

def refuse_development_checkout(prefix):
    widget_dir = (
        prefix
        / "share"
        / "plasma"
        / "plasmoids"
        / "com.new.steambanners"
    )

    git_dir = widget_dir / ".git"

    if git_dir.exists():
        raise RuntimeError(
            "Automatic update is disabled for a development checkout."
        )

def main():
    args = parse_args()

    try:
        installed = read_installed_version()
        release = get_latest_release()

        latest = release.get(
            "tag_name",
            ""
        ).lstrip("v")

        if not latest:
            raise RuntimeError(
                "Latest GitHub release has no version tag."
            )

        if (
            not args.allow_current
            and version_tuple(latest)
            <= version_tuple(installed)
        ):
            print(
                json.dumps({
                    "success": False,
                    "error": "No newer version is available.",
                    "installed": installed,
                    "latest": latest
                })
            )
            return

        asset = find_release_asset(
            release,
            latest
        )

        if not asset:
            raise RuntimeError(
                "The release does not contain an installable archive."
            )

        asset_url = asset.get(
            "browser_download_url",
            ""
        )

        if not asset_url:
            raise RuntimeError(
                "The release asset has no download URL."
            )

        prefix = args.prefix.expanduser().resolve()
        if not args.allow_current:
            refuse_development_checkout(prefix)

        with tempfile.TemporaryDirectory(
            prefix="steambanners-update-"
        ) as temp_name:

            temp_dir = Path(temp_name)

            archive_path = (
                temp_dir / asset["name"]
            )

            extract_dir = (
                temp_dir / "source"
            )

            extract_dir.mkdir()

            download_file(
                asset_url,
                archive_path
            )

            safe_extract(
                archive_path,
                extract_dir
            )

            source_dir = find_source_directory(
                extract_dir
            )

            build_dir = (
                temp_dir / "build"
            )

            run_command([
                "cmake",
                "-S",
                str(source_dir),
                "-B",
                str(build_dir),
                "-DCMAKE_BUILD_TYPE=Release"
            ])

            run_command([
                "cmake",
                "--build",
                str(build_dir),
                "-j"
            ])

            run_command([
                "cmake",
                "--install",
                str(build_dir),
                "--prefix",
                str(prefix)
            ])

        print(
            json.dumps({
                "success": True,
                "installed_before": installed,
                "installed_version": latest,
                "prefix": str(prefix),
                "restart_required": True
            })
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
