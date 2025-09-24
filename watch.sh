#!/bin/sh
# shellcheck disable=SC3046
. ./db.sh
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

init_db

test_convert() {
  input_file="$1"
  overwrite="$2"
  echo "input" "$input_file"
  echo "dir" "$input_dir"
  rel_path="${input_file#"$input_dir"/}"
  target="$output_dir/$rel_path"
  # if webm, change target
  case "$input_file" in
    *.webm) target="${target}.webp" ;;
  esac
  # if overwrite or file DNE, ignore everything
  if [ "$overwrite" = 1 ] || [ ! -f "$target" ]; then
    convert "$input_file"
  # test against sqlite
  fi
  lookup_file "$input_file" "$target"
  exit_code=$?
  if [ $exit_code -eq 0 ]; then
    # match, skip
    # printf "\r[-] %s\033[K\n" "$rel_path"
    true
  elif [ $exit_code -eq 2 ]; then
    # match on mtime, update
    printf "\r[=] %s\n" "$rel_path"
    insert_file "$input_file" "$target"
  else
    convert "$input_file"
  fi
}

convert() {
  input_file="$1"
  rel_path="${input_file#"$input_dir"/}"
  echo "Converting $rel_path"
  # ensure parent directory
  target="$output_dir/$rel_path"
  echo "target $target"
  mkdir -p "$(dirname "$target")"
  # Skip non-webp files
  case "$input_file" in
    *.webp)
      # reencode to quality 80
      printf "\r[ ] %s" "$rel_path"
      cwebp -af -mt -quiet -q 80 "$input_file" -o "$target"
      printf "\r[i] %s\033[K\n" "$rel_path"
      insert_file "$input_file" "$target"
      return
      ;;
    *.webm)
      # change target
      target="${target}.webp"
      # thumbnail at 1s
      printf "\r[ ] %s" "$rel_path"
      ffmpeg -i "$input_file" -vframes 1 -ss 1 "$target" -y -loglevel quiet
      printf "\r[v] %s\033[K\n" "$rel_path"
      insert_file "$input_file" "$target"
      return
      ;;
    *.svg)
      cp "$input_file" "$target" && insert_file "$input_file" "$target"
      ;;
    *)
      printf "\r[!] %s (unsupported)\033[K\n" "$rel_path"
      return
      ;;
  esac
}

# initial processing
echo "- Starting initial processing"
find "$input_dir" -type f | while IFS= read -r file; do
  test_convert "$file" 0
done
echo "- Initial processing complete"

echo "- Watching $input_dir"
inotifywait -mrqe attrib "$input_dir" --format %w%f | while IFS= read -r file; do
  test_convert "$file" 1
done