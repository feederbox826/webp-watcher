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

## Custom ffmpeg
Yes, there's a custom ffmpeg build for the specific format for my tags
- It reduces the image size
  - 197MB to 31MB on x64
  - 121MB to 22MB on arm64
- It greatly increases speed
  - user 0.37s, sys 0.11s to user 0.28s sys 0.06s on x86
  - user 0.42s, sys 0.03s to user 0.37s sys 0.00s on arm64