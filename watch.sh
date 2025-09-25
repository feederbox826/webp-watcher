#!/usr/bin/env bash

shopt -s globstar nullglob

# shellcheck disable=SC1091
source ./db.sh
# env
SCREENSHOT_TIME=${SCREENSHOT_TIME:-1} # time in seconds to take screenshot from videos
QUALITY=${QUALITY:-80} # webp quality
# lookup exit codes
LOOKUP_MATCH=10
LOOKUP_MTIME=11
LOOKUP_MISS=12
# COLORS
RED="\033[0;31m"
MAGENTA="\033[0;35m"
CYAN="\033[0;36m"
GREEN="\033[0;32m"
NC="\033[0m"

trap 'echo "exiting"; exit $?' INT TERM

input_dir=$1
output_dir=$2
if [ -z "$input_dir" ] || [ -z "$output_dir" ]; then
  echo "Usage: $0 <input_dir> <output_dir>"
  exit 1
fi

# ensure directories exist
for dir in "$input_dir" "$output_dir"; do
  [ -d "$dir" ] || { echo "Directory does not exist: $dir"; exit 1; };
done

init_db

test_convert() {
  input_file="$1"
  overwrite="$2"
  # shellcheck disable=SC2295
  rel_path="${input_file#$input_dir/}"
  target="$output_dir/$rel_path"
  # if webm, change target
  case "$input_file" in
    *.webm) target="${target}.webp" ;;
  esac
  # if overwrite or file DNE, ignore everything
  if [ "$overwrite" = 1 ] || [ ! -f "$target" ]; then
    convert "$input_file" "$rel_path" "$target"
    return
  fi
  # test against sqlite
  lookup_file "$input_file" "$target"
  exit_code=$?
  case $exit_code in
    "$LOOKUP_MATCH")
      # match, skip
      # printf "\r[-] %s\033[K\n" "$rel_path"
      true
      ;;
    "$LOOKUP_MTIME")
      # match on mtime, update
      printf "\r${GREEN}[=] %s${NC}\n" "$rel_path"
      insert_file "$input_file" "$target"
      ;;
    "$LOOKUP_MISS"|*) convert "$input_file" "$rel_path" "$target" ;;
  esac
}

convert() {
  input_file="$1"
  rel_path="$2"
  target="$3"
  mkdir -p "$(dirname "$target")"
  # Skip non-webp files
  case "$input_file" in
    *.webp)
      # reencode to quality 80
      printf "\r${CYAN}[ ] %s${NC}" "$rel_path"
      if cwebp -af -mt -quiet -q "$QUALITY" "$input_file" -o "$target"; then
        insert_file "$input_file" "$target"
      fi
      printf "\r${CYAN}[i] %s\033[K${NC}\n" "$rel_path"
      return
      ;;
    *.webm)
      # thumbnail at 1s
      printf "\r${MAGENTA}[ ] %s${NC}" "$rel_path"
      if ffmpeg -ss "$SCREENSHOT_TIME" -i "$input_file" -vframes 1 "$target" -y -loglevel quiet; then
        insert_file "$input_file" "$target"
      fi
      printf "\r${MAGENTA}[v] %s\033[K${NC}\n" "$rel_path"
      return
      ;;
    *.svg)
      cp "$input_file" "$target" && insert_file "$input_file" "$target"
      ;;
    *)
      printf "\r${RED}[!] %s (unsupported)\033[K${NC}\n" "$rel_path"
      return
      ;;
  esac
}

# initial processing
echo "- Starting initial processing"
for file in "$input_dir"/**/*; do
  [ -f "$file" ] || continue
  test_convert "$file" 0
done
echo "- Initial processing complete"

echo "- Watching $input_dir"
inotifywait -mrqe attrib "$input_dir" --format %w%f | while IFS= read -r file; do
  test_convert "$file" 1
done