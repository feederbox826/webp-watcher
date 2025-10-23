#!/bin/sh

# sqlite database helper

DB_FILE=${DB_FILE:-"webp-watch.sqlite3"}
MTIME_FALLBACK=${MTIME_FALLBACK:-0}

init_db() {
  if [ ! -f "$DB_FILE" ]; then
    echo "Creating database..."
    sqlite3 "$DB_FILE" <<EOF
      CREATE TABLE IF NOT EXISTS files (
        filename TEXT PRIMARY KEY,
        mtime INTEGER,
        size INTEGER
      );
      CREATE INDEX IF NOT EXISTS idx_files_all on files (filename, mtime, size);
      CREATE INDEX IF NOT EXISTS idx_files_mtime on files (filename, mtime);
EOF
  fi
  sqlite3 "$DB_FILE" "PRAGMA journal_mode=WAL; PRAGMA optimize; VACUUM;"
}

lookup_file() {
  filename="$1"
  target="$2"
  mtime=$(stat -c %Y "$filename")
  size=$(stat -c %s "$filename")
  safe_filename=$(echo "$filename" | sed "s/'/''/g")
  # check sqlite
  if sqlite3 -readonly "$DB_FILE" \
    "SELECT 1 FROM files WHERE filename = '$safe_filename' AND mtime = $mtime AND size = $size" \
    | grep -q 1; then
    return 10
  # if target, check mtime
  elif [ "$MTIME_FALLBACK" -eq 1 ] && [ -s "$target" ]; then
    target_mtime=$(stat -c %Y "$target")
    if [ "$target_mtime" -eq "$mtime" ]; then
      return 11
    fi
  fi
  return 12
}

# shellcheck disable=SC3023
insert_file() {
  filename="$1"
  target="$2"
  mtime=$(stat -c %Y "$filename")
  size=$(stat -c %s "$filename")
  safe_filename=$(echo "$filename" | sed "s/'/''/g")
  sqlite3 "$DB_FILE" "REPLACE INTO files (filename, mtime, size) VALUES ('$safe_filename', $mtime, $size);"
  # set mtime of target to match source
  touch -m -d "@$mtime" "$target"
}