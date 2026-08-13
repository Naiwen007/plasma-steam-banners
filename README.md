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
- Favorites
- Alphabetical sorting
- Favorites-first sorting
- Favorites-only view
- Configurable number of columns
- Configurable card height
- Manual refresh button
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
plasmashell --replace
```

Steam Banners should then appear in the Plasma widget browser.

## Updating

From inside the cloned repository:

```bash
git pull
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j
cmake --install build --prefix "$HOME/.local"
```

Restart Plasma Shell after updating.

## Usage

### Launch a game

Left-click a game card to launch the game through Steam.

### Favorites

Right-click a game card and select `Add to favorites`. Favorite games are marked with a star.

Right-click the game again and select `Remove from favorites` to remove it.

### Search

Use the search field below the header to filter games by title. Search results update immediately while typing.

### Refresh

Use the refresh button in the Steam Banners header to rescan your Steam libraries and update the game list. The tooltip changes to `Refreshing...` while the scan is running.

### Settings

The widget settings currently include:

- Columns
- Card height
- View
  - Alphabetical (A-Z)
  - Favorites first
  - Favorites only
- SteamGridDB API key

## Artwork cache

SteamGridDB artwork is downloaded locally when needed.

Generated artwork and cache files are runtime data and are intentionally excluded from the Git repository and installation package.

The widget currently caches SteamGridDB logos and hero artwork. Already downloaded artwork is reused instead of being downloaded on every scan.

## Steam library detection

Steam Banners checks common Linux Steam locations and reads Steam's library configuration to find additional library folders.

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
- Artwork selection currently uses the first matching SteamGridDB result.
- The current release is focused on Linux and KDE Plasma 6.
- The build/install layout has primarily been tested with a user-local installation under `~/.local`.

## Project structure

```text
.
├── CMakeLists.txt
├── metadata.json
├── processplugin/
│   ├── CMakeLists.txt
│   ├── process.cpp
│   └── process.h
└── contents/
    ├── config/
    ├── images/
    ├── scripts/
    │   ├── steam_library_scan.py
    │   └── steam_scan.py
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
