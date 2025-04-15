#!/bin/sh
trap 'echo "exiting"; exit 1' INT TERM EXIT

input_dir=$1
output_dir=$2
if [ -z "$input_dir" ] || [ -z "$output_dir" ]; then
  echo "Usage: $0 <input_dir> <output_dir>"
  exit 1
fi

# ensure directories exist
for dir in "$input_dir" "$output_dir"; do
  if [ ! -d "$dir" ]; then
    echo "Directory does not exist: $dir"
    exit 1
  fi
done

convert() {
  input_file="$1"
  base_name=${input_file##*/}
  target=$output_dir/$base_name
  # Skip non-webp files or if the target file exists
  case "$input_file" in
    *.webp) [ ! -s "$target" ] || return ;;
    *.svg) cp "$input_file" "$target" && return ;;
    *) return ;;
  esac
	printf "\r[ ] %s" "$base_name"
  # reencode to quality 80
  cwebp -af -quiet -q 80 "$input_file" -o "${target}"
  printf "\r[✓] %s\033[K\n" "$base_name"
}

# process with progress bar
echo "Starting initial processing"
for file in "$input_dir"/*.svg; do
  target="$output_dir/${file##*/}"
  # Skip if the target file already exists
  [ ! -f "$target" ] && cp "$file" "$target"
done
echo "Copied SVGs"
for file in "$input_dir"/*.webp; do
  [ -s "$file" ] && convert "$file"
done
echo "Initial processing complete."

echo "Watching $input_dir"
inotifywait -mrqe attrib "$input_dir" --format %w%f | while IFS= read -r file; do
  convert "$file"
done