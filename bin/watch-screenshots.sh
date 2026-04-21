#!/usr/bin/env bash
SRC_DIR="$HOME/Pictures/Screenshots"
SCRIPT="$HOME/bin/update-latest-ss"

inotifywait -m -e close_write,create,move --format '%f' "$SRC_DIR" | while read -r file; do
    case "$file" in
        *.png|*.jpg|*.jpeg)
            "$SCRIPT"
            ;;
    esac
done
