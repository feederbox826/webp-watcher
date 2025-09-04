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
  [ -d "$dir" ] || { echo "Directory does not exist: $dir"; exit 1; };
done

convert() {
  input_file="$1"
  overwrite="$2"
  base_name=${input_file##*/}
  target=$output_dir/$base_name
  # skip if not overwriting and target exists
  [ "$overwrite" != 1 ] && [ -s "$target" ] && return
  # Skip non-webp files
  case "$input_file" in
    *.webp) ;;
    *.svg) cp "$input_file" "$target" && return ;;
    *) return ;;
  esac
  printf "\r[ ] %s" "$base_name"
  # reencode to quality 80
  cwebp -af -quiet -q 80 "$input_file" -o "$target"
  printf "\r[✓] %s\033[K\n" "$base_name"
}

# initial processing
echo "- Starting initial processing"
for file in "$input_dir"/*.svg "$input_dir"/*.webp; do
  target="$output_dir/${file##*/}"
  # copy only if target doesn't exit
  [ ! -s "$target" ] && convert "$file" 0
done
echo "- Initial processing complete"

echo "- Watching $input_dir"
inotifywait -mqe attrib "$input_dir" --format %w%f | while IFS= read -r file; do
  convert "$file" 1
done