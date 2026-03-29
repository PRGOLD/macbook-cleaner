# 🍎 MacBook Cleaner

A simple toolkit to keep your MacBook clean, organised, and secure.

## What's included

| File | Description |
|------|-------------|
| `mac_cleanup.sh` | Shell script — safely clears Trash, caches, temp files, old logs, Xcode derived data, and Docker images |
| `mac_clean_guide.html` | Interactive HTML checklist covering disk space, file organisation, and security & privacy |

## Quick start

### Run the cleanup script

```bash
# Clone the repo
git clone https://github.com/PRGOLD/macbook-cleaner.git
cd macbook-cleaner

# Make the script executable and run it
chmod +x mac_cleanup.sh
./mac_cleanup.sh
```

### Open the guide

Simply open `mac_clean_guide.html` in your browser. Tick off items as you go — your progress is saved automatically.

## What the script cleans

- 🗑️ **Trash** — empties `~/.Trash`
- 📦 **User caches** — removes stale `.cache` files from `~/Library/Caches`
- 🌡️ **Temp files** — removes files older than 3 days from `/private/tmp`
- 📋 **Old logs** — removes log files older than 30 days from `~/Library/Logs`
- 🛠️ **Xcode DerivedData** — optional, prompts before deleting
- 🐳 **Docker** — optional `docker system prune` if Docker is running

## What the guide covers

1. **Disk Space** — built-in macOS Storage tool, finding large files, removing old backups
2. **File Organisation** — Desktop, Downloads, folder structure, iCloud Drive, app cleanup
3. **Security & Privacy** — FileVault, Firewall, Login Items, password manager, 2FA, malware scan
4. **Bonus** — performance tips and battery health

## License

MIT — free to use, modify, and share.
