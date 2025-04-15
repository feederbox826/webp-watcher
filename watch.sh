#!/bin/bash

echo "Starting watch.sh"

input_dir="$1"
output_dir="$2"
if [[ -z "$input_dir" || -z "$output_dir" ]]; then
    echo "Usage: $0 <input_dir> <output_dir>"
    exit 1
fi
for dir in "$input_dir" "$output_dir"; do
    [[ ! -d "$dir" ]] && echo "Directory does not exist: $dir" && exit 1
done

function convert() {
    local input_file="$1"
    local target="${output_dir}/${input_file##*/}"
    # Skip non-webp files or if the target file exists
    [[ "$input_file" != *.webp || -f "$target" ]] && return

    # reencode to quality 80
    echo "Converting $input_file to ${target}"
    cwebp -af -quiet -q 80 "$input_file" -o "${target}"
    echo "Converted $input_file to ${target}"
}

# convert all files in the input directory
for file in "$input_dir"/*.webp; do
    [[ -e "$file" ]] && convert "$file"
done

echo "Watching $input_dir"
    inotifywait -mrqe attrib "$input_dir" --format %w%f | while read -r file; do
        convert "$file"
done
echo "watch.sh finished"