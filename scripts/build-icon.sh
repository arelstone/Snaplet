#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
source_file="$project_dir/Packaging/AppIcon.png"
output_file="$project_dir/Packaging/Snaplet.icns"

if [[ -f "$output_file" && "$output_file" -nt "$source_file" ]]; then
    exit 0
fi

mkdir -p "$project_dir/.build"
icon_work_dir="$(mktemp -d "$project_dir/.build/icon-build.XXXXXX")"
trap 'rm -rf "$icon_work_dir"' EXIT
iconset="$icon_work_dir/Snaplet.iconset"
mkdir -p "$iconset"

for points in 16 32 128 256 512; do
    sips -z "$points" "$points" "$source_file" --out "$iconset/icon_${points}x${points}.png" >/dev/null
    pixels=$((points * 2))
    sips -z "$pixels" "$pixels" "$source_file" --out "$iconset/icon_${points}x${points}@2x.png" >/dev/null
done

iconutil --convert icns --output "$output_file" "$iconset"
printf 'Built %s\n' "$output_file"
