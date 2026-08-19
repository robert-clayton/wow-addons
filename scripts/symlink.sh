#!/usr/bin/env bash
# Symlinks addon folders into WoW AddOns directory
# Usage: ./scripts/symlink.sh /path/to/WoW/_retail_/Interface/AddOns

set -euo pipefail

export MSYS=winsymlinks:nativestrict

WOW_ADDONS_DIR="${1:?Usage: $0 /path/to/WoW/_retail_/Interface/AddOns}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

mkdir -p -- "$WOW_ADDONS_DIR"
WOW_ADDONS_DIR="$(cd "$WOW_ADDONS_DIR" && pwd -P)"
case "$WOW_ADDONS_DIR" in
    */Interface/AddOns) ;;
    *)
        echo "Refusing target that is not an Interface/AddOns directory: $WOW_ADDONS_DIR" >&2
        exit 1
        ;;
esac

remove_existing() {
    local target="$1"
    local allowed_parent="$2"
    local actual_parent
    actual_parent="$(cd "$(dirname "$target")" && pwd -P)"
    if [[ "$actual_parent" != "$allowed_parent" ]]; then
        echo "Refusing to remove target outside expected directory: $target" >&2
        exit 1
    fi
    if [[ -L "$target" || -e "$target" ]]; then
        rm -rf -- "$target"
    fi
}

# Symlink shared libs into each addon
for lib_dir in "$REPO_ROOT"/libs/*/; do
    lib_name="$(basename "$lib_dir")"
    for addon_dir in "$REPO_ROOT"/addons/*/; do
        mkdir -p -- "$addon_dir/Libs"
        lib_parent="$(cd "$addon_dir/Libs" && pwd -P)"
        target="$addon_dir/Libs/$lib_name"
        remove_existing "$target" "$lib_parent"
        ln -s "$lib_dir" "$target"
        [[ -L "$target" ]] || { echo "Failed to link $target" >&2; exit 1; }
        echo "Linked lib $lib_name -> $target"
    done
done

for addon_dir in "$REPO_ROOT"/addons/*/; do
    addon_name="$(basename "$addon_dir")"
    target="$WOW_ADDONS_DIR/$addon_name"
    remove_existing "$target" "$WOW_ADDONS_DIR"
    ln -s "$addon_dir" "$target"
    [[ -L "$target" ]] || { echo "Failed to link $target" >&2; exit 1; }
    echo "Linked $addon_name -> $target"
done
