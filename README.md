# webp-watch

webp thumbnail generator for feederbox tags

Features
- Iterates over subdirectories
- Watches input folder for new files
- sqlite cache to detect new/ updated files

Environment variables
- QUALITY: webp quality
- SCREENSHOT_TIME: Seek time for screenshots
- DB_FILE: Path for sqlite cache
- MTIME_FALLBACK: Assume thumbnails with same mtime don't need to be updated

Usage:
```sh
watch.sh /input /output
```