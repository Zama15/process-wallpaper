#!/bin/bash

ROOT="$(dirname "$(realpath "$0")")"
WALLPAPER_PATH="${ROOT}/wallpaper.png"
TEMP_WALLPAPER_PATH="${ROOT}/temp_wallpaper.png"
LOG_FILE="/tmp/wallpaper.log"

# ========== DEFINE THE FUNCTIONS ==========

echo_error() {
    echo -e "\e[31m$1\e[0m" >&2
}

echo_success() {
    echo -e "\e[32m$1\e[0m"
}

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to set wallpaper for KDE Plasma
set_wallpaper_plasma() {
  if pgrep plasmashell > /dev/null; then
    log "Detected KDE Plasma. Attempting to set wallpaper..."

    # Create a temporary copy of the wallpaper
    cp "$WALLPAPER_PATH" "$TEMP_WALLPAPER_PATH"

    set_single_wallpaper() {
      local wp_path="$1"
      local script="
        var allDesktops = desktops();
        print('Number of desktops: ' + allDesktops.length);
        for (var i = 0; i < allDesktops.length; i++) {
          var d = allDesktops[i];
          d.wallpaperPlugin = 'org.kde.image';
          d.currentConfigGroup = Array('Wallpaper', 'org.kde.image', 'General');
          d.writeConfig('Image', 'file://${wp_path}');
          print('Set wallpaper for desktop ' + i);
        }
        print('Wallpaper setting complete');
      "

      if qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$script"; then
        log "Wallpaper $wp_path set successfully on KDE Plasma."
        
        return 0
      else
        log "Failed to set wallpaper $wp_path on KDE Plasma."

        return 1
      fi
    }

    # Set temporary wallpaper first
    set_single_wallpaper "$TEMP_WALLPAPER_PATH"

    # Small delay to ensure KDE recognizes the change
    sleep 1

    # Set actual wallpaper
    set_single_wallpaper "$WALLPAPER_PATH"

    # Clean up temporary wallpaper
    rm -f "$TEMP_WALLPAPER_PATH"

    return 0
  fi

  return 1
}

# Function to set wallpaper for GNOME
set_wallpaper_gnome() {
  if command -v gsettings > /dev/null; then
    
    log "Detected GNOME. Setting wallpaper..."

    if gsettings set org.gnome.desktop.background picture-uri "file://$WALLPAPER_PATH"; then
      log "Wallpaper set successfully on GNOME."

      return 0
    else
      log "Failed to set wallpaper on GNOME."

      return 1
    fi
  fi

  return 1
}

# Function to set wallpaper with feh (for lightweight environments)
set_wallpaper_feh() {
  if command -v feh > /dev/null; then

    log "Detected feh. Setting wallpaper..."

    if feh --bg-fill "$WALLPAPER_PATH"; then
      log "Wallpaper set successfully using feh."
      
      return 0
    else
      log "Failed to set wallpaper with feh."
      
      return 1
    fi
  fi

  return 1
}

# ========== MAIN ==========

log "Starting wallpaper setting process..."
log "Wallpaper path: $WALLPAPER_PATH"

# Check if wallpaper file exists
if [[ ! -f "$WALLPAPER_PATH" ]]; then
  echo_error "Wallpaper file not found: $WALLPAPER_PATH"

  return 1
fi

# Attempt to set wallpaper using different methods
if set_wallpaper_plasma || set_wallpaper_gnome || set_wallpaper_feh; then
  echo_success "Wallpaper set successfully."
else
  echo_error "Unable to automatically set wallpaper. Please set $WALLPAPER_PATH manually."
      
  exit 1
fi

log "Wallpaper setting process completed."

exit 0

