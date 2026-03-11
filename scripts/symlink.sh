#!/bin/bash
# Symlinks addon folders into WoW AddOns directory
# Usage: ./scripts/symlink.sh /path/to/WoW/_retail_/Interface/AddOns

export MSYS=winsymlinks:nativestrict

WOW_ADDONS_DIR="${1:?Usage: $0 /path/to/WoW/_retail_/Interface/AddOns}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Symlink shared libs into each addon
for lib_dir in "$REPO_ROOT"/libs/*/; do
    lib_name="$(basename "$lib_dir")"
    for addon_dir in "$REPO_ROOT"/addons/*/; do
        target="$addon_dir/Libs/$lib_name"
        [ -L "$target" ] || [ -e "$target" ] && rm -rf "$target"
        ln -s "$lib_dir" "$target"
        echo "Linked lib $lib_name -> $target"
    done
done

for addon_dir in "$REPO_ROOT"/addons/*/; do
    addon_name="$(basename "$addon_dir")"
    target="$WOW_ADDONS_DIR/$addon_name"
    if [ -e "$target" ]; then
        rm -rf "$target"
    fi
    ln -s "$addon_dir" "$target"
    echo "Linked $addon_name -> $target"
done
