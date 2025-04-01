#!/bin/bash

# Set the media path
MEDIA_PATH="/home/awp/minetest/media"

collect_from () {
        echo "Processing media from: $1"
        find -L "$1" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.ogg" -o -name "*.x" -o -name "*.b3d" \) | while read f; do
                basename "$f"
                hash=$(openssl dgst -sha1 <"$f" | cut -d " " -f 2)
                cp "$f" "$MEDIA_PATH/$hash"
        done
}

mkdir -p "$MEDIA_PATH"
# Change this 'collect_from' or add more lines of 'collect_from'
collect_from mods/
# Example for MineClone2
#collect_from mods/
#collect_from textures/

printf "Creating index.mth... "
printf "MTHS\x00\x01" > "$MEDIA_PATH/index.mth"
find "$MEDIA_PATH" -type f -not -name index.mth | while read f; do
        openssl dgst -binary -sha1 <$f >> "$MEDIA_PATH/index.mth"
done
