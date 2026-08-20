# Auto Wallpaper Ubuntu

Automatically fetch and rotate wallpapers on your Ubuntu desktop. This project uses the [Wallhaven API](https://wallhaven.cc) to curate high-quality wallpapers and rotates them at regular intervals.

## Features

- 🖼️ **Automatic Wallpaper Fetching** - Downloads wallpapers from Wallhaven API with customizable filters
- 🔄 **Scheduled Rotation** - Changes desktop wallpaper every 5 minutes
- 🧹 **Pool Management** - Maintains a fixed collection of images, removing oldest files when limit is exceeded
- ⏰ **Daily Refresh** - Fetches new wallpapers daily at 3:00 AM
- 🎯 **Themed Selection** - Rotates through different themes (nature, landscape, mountains, etc.)
- 🔧 **Easy Installation** - Simple cron management with install/uninstall commands
- 🌗 **GNOME Support** - Sets wallpapers for both light and dark themes

## Requirements

- Ubuntu/Debian with GNOME Desktop
- Bash 4.0+
- `curl` - For downloading wallpapers
- `jq` - For parsing JSON responses
- `gsettings` - For setting GNOME wallpaper (included with GNOME)
- `cron` - For task scheduling

### Install Dependencies

```bash
sudo apt update
sudo apt install curl jq
```

## Installation

1. **Clone or download this repository:**
   ```bash
   git clone https://github.com/yourusername/auto-wallpaper-ubuntu.git
   cd auto-wallpaper-ubuntu
   ```

2. **Install cron jobs:**
   ```bash
   ./manage_cron.sh install
   ```

   This sets up:
   - Wallpaper rotation every 5 minutes
   - New wallpaper fetch daily at 3:00 AM

3. **Verify installation:**
   ```bash
   ./manage_cron.sh status
   ```

## Usage

### Manual Execution

**Fetch new wallpapers immediately:**
```bash
./fetch_wallpapers.sh
```

**Change wallpaper immediately:**
```bash
./change_wallpaper.sh
```

### Automated via Cron

Once installed with `manage_cron.sh install`, the following tasks run automatically:

| Task | Frequency | Command |
|------|-----------|---------|
| Fetch Wallpapers | Daily at 3:00 AM | `fetch_wallpapers.sh` |
| Change Wallpaper | Every 5 minutes | `change_wallpaper.sh` |

### Uninstall

Remove all wallpaper cron jobs:
```bash
./manage_cron.sh uninstall
```

## Configuration

Edit `fetch_wallpapers.sh` to customize wallpaper sources:

### Basic Settings
- **`DEST_DIR`** - Where wallpapers are stored (default: `~/Pictures/Wallpapers/Wallhaven`)
- **`MAX_POOL_SIZE`** - Maximum number of wallpapers to keep (default: 100)
- **`PAGES_TO_FETCH`** - Number of API result pages to fetch (default: 1)

### Search Filters
- **`RESOLUTIONS`** - Image resolution filter (default: `3840x2160`)
- **`RATIOS`** - Aspect ratio filter (default: `16x9`)
- **`CATEGORIES`** - Content categories:
  - `100` = General only
  - `010` = Anime
  - `001` = People
- **`PURITY`** - Content filter (default: `100` = SFW only)
- **`SORTING`** - Sort order (options: `random`, `date_added`, `relevance`, `hot`, `toplist`)

### Theme Rotation
Customize themes in the `QUERIES` array:
```bash
QUERIES=(
    "nature"
    "landscape"
    "mountains"
    "forest"
    "aerial view"
    "bird"
    "animals"
)
```

Each fetch run randomly selects a theme from this list.

### API Key (Optional)
For higher API rate limits, add your Wallhaven API key:
```bash
API_KEY="your-api-key-here"
```

Get a free API key from [Wallhaven Settings](https://wallhaven.cc/settings/account).

## Wallpaper Storage

Wallpapers are stored in: `~/Pictures/Wallpapers/Wallhaven/`

The script automatically:
- Creates the directory if it doesn't exist
- Downloads only new wallpapers (skips if already present)
- Removes oldest images when pool exceeds `MAX_POOL_SIZE`

## Troubleshooting

### Wallpaper not changing
1. Check if `change_wallpaper.sh` is executable:
   ```bash
   ls -la change_wallpaper.sh
   ```

2. Verify DBUS connection (required for GNOME):
   ```bash
   echo $DBUS_SESSION_BUS_ADDRESS
   ```

3. Test manually:
   ```bash
   ./change_wallpaper.sh
   ```

### No wallpapers downloaded
1. Check internet connection:
   ```bash
   curl -s "https://wallhaven.cc/api/v1/search?resolutions=3840x2160" | jq '.data | length'
   ```

2. Verify wallpaper directory exists:
   ```bash
   ls ~/Pictures/Wallpapers/Wallhaven/
   ```

3. Check cron logs:
   ```bash
   grep CRON /var/log/syslog | tail -20
   ```

### Cron jobs not running
1. Verify cron is active:
   ```bash
   sudo systemctl status cron
   ```

2. Check installed cron jobs:
   ```bash
   ./manage_cron.sh status
   ```

3. Review cron logs:
   ```bash
   journalctl -u cron --no-pager | tail -20
   ```

## How It Works

### `fetch_wallpapers.sh`
1. Queries Wallhaven API with specified filters
2. Downloads wallpapers to `~/Pictures/Wallpapers/Wallhaven/`
3. Skips files already in the collection
4. Removes oldest wallpapers if pool exceeds `MAX_POOL_SIZE`

### `change_wallpaper.sh`
1. Connects to GNOME D-Bus session
2. Randomly selects a wallpaper from the collection
3. Sets it for both light and dark GNOME themes via `gsettings`

### `manage_cron.sh`
1. Manages cron job installation and removal
2. Ensures scripts are executable
3. Prevents duplicate cron entries
4. Tags cron jobs for easy identification and removal

## API Information

This project uses the **Wallhaven API** (v1):
- **Base URL**: `https://wallhaven.cc/api/v1/`
- **Rate Limit**: Generous for anonymous users
- **Filter Options**: Resolution, aspect ratio, categories, purity, sorting
- **Documentation**: [Wallhaven API Docs](https://wallhaven.cc/help/api)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Feel free to fork, modify, and improve! Suggestions and bug reports are welcome.

---

**Enjoy your fresh wallpapers!** 🎨
