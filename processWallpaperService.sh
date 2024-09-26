#!/bin/bash

# Set the path to your scripts
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
CONFIG_FILE="$SCRIPT_DIR/config.json"
LOG_FILE="/tmp/wallpaper.log"

# ========== DEFINE THE FUNCTIONS ==========

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to get sleep time from JSON
get_sleep_time() {
  local sleep_time=$(grep '"timeSeg":' "$CONFIG_FILE" | sed 's/[^0-9]*//g')
  if [ -z "$sleep_time" ]; then
    sleep_time=60  # Default to 60 seconds if not found
  fi

  echo "$sleep_time"
}

# Function to update wallpaper
update_wallpaper() {
  cd "$SCRIPT_DIR"
  ./updateWallpaper.sh
  ./setWallpaper.sh
}

# ========== MAIN ==========

# Get the sleep time from the JSON file using grep and sed
SLEEP_TIME=$(get_sleep_time)

# Initialize last modification time of config file
LAST_MODIFIED=$(stat -c %Y "$CONFIG_FILE")

# Main loop
while true; do
  # Check if config file has been modified
  CURRENT_MODIFIED=$(stat -c %Y "$CONFIG_FILE")

  if [ "$CURRENT_MODIFIED" != "$LAST_MODIFIED" ]; then
    log "Config file was modified since last iteration"
    log "Last modified: ${LAST_MODIFIED}, Current Modified: ${CURRENT_MODIFIED}"
    log "Last time: ${SLEEP_TIME}, Current time: $(get_sleep_time)"

    SLEEP_TIME=$(get_sleep_time)
    LAST_MODIFIED=$CURRENT_MODIFIED
  fi

  update_wallpaper
  sleep "$SLEEP_TIME"
done

