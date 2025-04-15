#!/bin/sh

echo "Starting watch.sh"

input_dir="$1"
output_dir="$2"
if [ -z "$input_dir" ] || [ -z "$output_dir" ]; then
    echo "Usage: $0 <input_dir> <output_dir>"
    exit 1
fi
for dir in "$input_dir" "$output_dir"; do
    [ ! -d "$dir" ] && echo "Directory does not exist: $dir" && exit 1
done

convert() {
    input_file="$1"
    target="${output_dir}/${input_file}"
    # target file exists
    if [ -f "$target" ]; then
        return
    # convert webp
    elif [ "${input_file##*.}" = "svg" ]; then
        # copy to optimized
        cp "${input_file}" "${target}.svg"
    elif [ "${input_file##*.}" = "webp" ]; then
        # reencode to quality 80
        cwebp -af -quiet -q 80 "${input_file}" -o "${target##*/}"
        echo "Converted $input_file to ${target}"
    elif [ "${input_file##*.}" = "webm" ]; then
        # ffmpeg reencode to crf 25, bv 600k
        ffmpeg -i "${input_file}" \
            -c:v libx264 \
            -quality best \
            -b:v 600k \
            -crf 25 \
            -c:v libvpx-vp9 \
            -c:a copy \
            "${target}"
        echo "Converted $input_file to ${target}.webm"
    fi
}

# convert all files in the input directory
echo "Converting all webp files"
for file in "$input_dir"/*.webp; do
    [ -e "$file" ] && convert "$file"
done
echo "Converting all webm files"
for file in "$input_dir"/*.webm; do
    [ -e "$file" ] && convert "$file"
done

echo "Watching $input_dir"
    inotifywait -mrqe attrib "$input_dir" --format %w%f | while read -r file; do
        convert "$file"
done
echo "watch.sh finished"