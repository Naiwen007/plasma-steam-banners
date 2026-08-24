# Steam Banners

A KDE Plasma 6 widget for browsing and launching installed Steam games using artwork from SteamGridDB.

Steam Banners scans your local Steam libraries, displays your installed games as artwork-based cards, and launches games directly through Steam.

## Features

- Automatically detects installed Steam games
- Supports multiple Steam library folders
- Downloads game logos and hero artwork from SteamGridDB
- Automatically trims and normalizes SteamGridDB logos
- Launches games directly through Steam
- Live game search
- Genre filtering
- Favorites
- Clear visual highlighting for favorite games
- Alphabetical sorting
- Favorites-first sorting
- Favorites-only view
- Configurable number of columns
- Configurable card height
- Manual refresh button
- Per-game artwork refresh from the game context menu
- Built-in update checker and automatic update installation
- Cache management directly from the widget settings
- Automatic warning when a configured Steam library is unavailable
- Local artwork and metadata caching for faster startup
- First-run guidance when no SteamGridDB API key is configured
- Empty-state messages when no games or favorites are found
- Custom Steam Banners interface
- SteamGridDB API key management directly from the widget settings

## Requirements

Steam Banners currently targets KDE Plasma 6 on Linux.

Runtime requirements:

- KDE Plasma 6
- Steam
- Python 3
- Pillow for Python
- Qt 6

Build requirements:

- CMake
- C++17 compatible compiler
- Qt 6 development files
- Qt 6 QML development files

The widget contains a small C++ QML module used to start external processes, so Steam Banners must currently be built before installation.

## SteamGridDB

Steam Banners uses SteamGridDB for game logos and hero artwork.

A SteamGridDB API key is required to download artwork.

The widget will still detect and display installed games without an API key, but SteamGridDB artwork will not be available.

### Getting an API key

1. Create or sign in to your SteamGridDB account.
2. Open the SteamGridDB API settings.
3. Generate an API key.
4. Open the Steam Banners settings.
5. Paste the key into the **SteamGridDB API key** field.
6. Click **Save API key**.
7. Refresh the game library.

Steam Banners also includes a direct link to the SteamGridDB API settings page inside its configuration dialog.

The API key is stored locally at:

```text
~/.config/steambanners/steamgriddb.key
```

The key file is created with user-only permissions.

## Building and installing

Clone the repository:

```bash
git clone https://github.com/Naiwen007/plasma-steam-banners.git
cd plasma-steam-banners
```

Configure the build:

```bash
cmake \
  -S . \
  -B build \
  -DCMAKE_BUILD_TYPE=Release
```

Build:

```bash
cmake --build build -j
```

Install for the current user:

```bash
cmake --install build \
  --prefix "$HOME/.local"
```

After installation, restart Plasma Shell or log out and back in.

On Plasma 6, Plasma Shell can normally be restarted with:

```bash
nohup plasmashell --replace > /tmp/plasmashell.log 2>&1 &
```
Plasma Shell output is then written to:

```text
/tmp/plasmashell.log
```

This can be useful when troubleshooting QML or widget startup errors.

Steam Banners should then appear in the Plasma widget browser.

## Updating

## Updating

Steam Banners includes a built-in update checker in the widget settings.

When a newer GitHub release is available, the settings page can:

- show the installed and latest available versions,
- open the corresponding GitHub release,
- download and install the release automatically,
- and restart Plasma after installation.

Automatic installation downloads the official Steam Banners source release archive, builds it locally, and installs it under:

```text
~/.local
```
Because updates are built locally, the build requirements listed above must also be installed for automatic updates to work.

Automatic updating is intentionally disabled when Steam Banners is running directly from a development Git checkout.

Updating a development checkout

When working from a cloned repository, update it manually:

git pull
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j
cmake --install build --prefix "$HOME/.local"

Restart Plasma Shell after updating:

nohup plasmashell --replace > /tmp/plasmashell.log 2>&1 &

## Usage

### Launch a game

Left-click a game card to launch the game through Steam.

### Favorites

Right-click a game card and select `Add to favorites`.

Favorite games are highlighted with a gold border and a star for easier identification.

Right-click the game again and select `Remove from favorites` to remove it.

### Search

Use the search button in the Steam Banners header to open the search field.

Enter part of a game title to filter the library. Search results update immediately while typing.

Use the clear button in the search field to remove the current search and show all matching games again.

### Genre filtering

Use the genre button in the Steam Banners header to filter the game library by genre.

Selecting a genre shows only games that match that genre. Selecting the same genre again, or choosing `All Games`, clears the filter.

### Refresh

Use the refresh button in the Steam Banners header to rescan your Steam libraries, refresh game metadata, and update artwork for all installed games.

Normal widget startup uses locally cached metadata and artwork for faster loading. A manual refresh performs the slower network lookups needed to update genres and SteamGridDB artwork.

To refresh artwork for a single game, right-click the game card and select `Refresh artwork`.

The tooltip changes to `Refreshing...` while a scan is running.

### Settings

The widget settings currently include:

- Columns
- Card height
- View
  - Alphabetical (A-Z)
  - Favorites first
  - Favorites only
- SteamGridDB API key
- Cache information
  - Artwork size and file count
  - Logo and hero file counts
  - Metadata size
  - Clear artwork cache
  - Clear metadata cache
- Update management
  - Check for new Steam Banners releases
  - Install available updates
  - Restart Plasma after an update

## Artwork and metadata cache

Steam Banners stores downloaded artwork, game metadata, and Steam library status information in a local runtime cache.

The cache is located at:

```text
~/.cache/steambanners/
```
It currently contains:

```text
logos/
heroes/
game_metadata.json
library_status.json
```

Cached artwork and metadata are reused during normal startup to keep the widget responsive.

The widget settings display the current artwork and metadata cache usage. Artwork and metadata can also be cleared separately from the settings.

Clearing the artwork cache removes downloaded and locally prepared logos and hero images. The widget automatically rescans the library afterward.

Clearing the metadata cache removes cached genre information. The widget automatically rescans afterward, but a full manual refresh is required to download the genre metadata again.

Using the manual refresh button updates cached metadata and artwork when new data is available.

Runtime cache files are intentionally excluded from the Git repository and installation package.

## Steam library detection

Steam Banners automatically detects Steam libraries configured in Steam.

The widget checks common Linux Steam installation locations and reads Steam's `libraryfolders.vdf` file to discover additional Steam library folders.

If a configured Steam library is temporarily unavailable, for example because an external or secondary drive is not mounted, Steam Banners shows a warning in the widget.

Unavailable libraries are not removed from Steam's configuration. They are simply skipped until the library path becomes available again.

This means games stored on secondary or external drives are supported automatically, as long as:

- the drive is mounted,
- the Steam library has been added to Steam,
- and the library is accessible when Steam Banners performs its scan.

Installed games are detected from Steam `appmanifest_*.acf` files.

Steam runtimes, Proton versions, redistributables, and similar Steam tools are filtered out of the game list.

## Uninstall

Remove the Plasma widget:

```bash
rm -rf "$HOME/.local/share/plasma/plasmoids/com.new.steambanners"
```

Remove the Steam Banners QML process module:

```bash
rm -rf "$HOME/.local/lib/qt6/qml/SteamBanners"
```

Optional: remove configuration:

```bash
rm -rf "$HOME/.config/steambanners"
```

Restart Plasma Shell afterward.

## Known limitations

- SteamGridDB artwork requires a user-provided SteamGridDB API key.
- Some games may not have suitable logo or hero artwork available on SteamGridDB.
- Genre information depends on metadata returned by the Steam Store.
- A manual refresh requires an internet connection to update metadata and SteamGridDB artwork.
- The current release is focused on Linux and KDE Plasma 6.
- The build/install layout has primarily been tested with a user-local installation under `~/.local`.

## Project structure

```text
.
├── CMakeLists.txt
├── LICENSE
├── metadata.json
├── processplugin/
│   ├── CMakeLists.txt
│   ├── process.cpp
│   └── process.h
└── contents/
    ├── config/
    │   ├── config.qml
    │   └── main.xml
    ├── fonts/
    │   ├── OFL.txt
    │   └── Orbitron Bold.ttf
    ├── images/
    │   ├── header.png
    │   └── placeholder.png
    ├── scripts/
    │   ├── cache_manage.py
    │   ├── steam_library_scan.py
    │   ├── steam_scan.py
    │   ├── update_check.py
    │   └── update_install.py
    └── ui/
        ├── GameGrid.qml
        ├── SteamScanner.qml
        ├── configGeneral.qml
        └── main.qml
```

## Credits

Game logos and hero artwork are provided through the SteamGridDB API.

Steam and related trademarks belong to Valve Corporation.

Steam Banners is an independent project and is not affiliated with or endorsed by Valve Corporation or SteamGridDB.

## License

Steam Banners is licensed under the GNU General Public License v3.0.
