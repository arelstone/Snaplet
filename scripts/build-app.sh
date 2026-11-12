#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
cd "$project_dir"

./scripts/build-icon.sh
swift build
binary_dir="$(swift build --show-bin-path)"
app_dir="$project_dir/.build/Snaplet.app"
mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources"
cp "$binary_dir/Snaplet" "$app_dir/Contents/MacOS/Snaplet"
cp Packaging/Info.plist "$app_dir/Contents/Info.plist"
cp Packaging/Snaplet.icns "$app_dir/Contents/Resources/Snaplet.icns"
python3 scripts/sign-app.py "$app_dir"
printf '\nBuilt %s\n' "$app_dir"
