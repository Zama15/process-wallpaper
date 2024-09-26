#!/bin/bash

ROOT="$(dirname "$(realpath "$0")")"
SERVICES_DIR="${HOME}/.config/systemd/user"
SERVICE_FILE_NAME="process-wallpaper.service"


# ========== DEFINE THE FUNCTIONS ==========

function echo_error {
  echo -e "\e[31m$1\e[0m" >&2
}


function echo_success {
  echo -e "\e[32m$1\e[0m"
}

function restart_service {
  echo "Restarting the service..."
  if systemctl --user restart "$SERVICE_FILE_NAME"; then
    echo_success "Service $SERVICE_FILE_NAME restarted successfully."
  else
    echo_error "Failed to restart $SERVICE_FILE_NAME. Please check the logs."
    exit 1
  fi
}

# ========== WHO THE USER IS ==========

if [[ "$EUID" -eq 0 ]]; then
  echo_error "Error: This script should not be run as root. Please run it as a regular user."
  exit 1
fi

# ========== CHECK SERVICE DIR OR CREATE IT ==========

function services_dir_exist {
  if [[ ! -d "$SERVICES_DIR" ]]; then
    echo_error "Directory ${SERVICES_DIR} does not exist. Proceeding to create one..."

    if mkdir -p "$SERVICES_DIR"; then
      echo_success "Successfully created ${SERVICES_DIR}."
    else
      echo_error "Failed to create ${SERVICES_DIR}."
      exit 1
    fi
  else
    echo_success "Directory ${SERVICES_DIR} already exists. Proceeding..."
  fi
}

# ========== SET UP SERVICE FILE CONTENT ==========

SERV=()

SERV+=("[Unit]")
SERV+=("Description=Process Wallpaper Service")
SERV+=("After=graphical-session.target")
SERV+=("")
SERV+=("[Service]")
SERV+=("ExecStart=${ROOT}/processWallpaperService.sh")
SERV+=("Restart=always")
SERV+=("Environment=DISPLAY=:0")
SERV+=("Environment=DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${UID}/bus")
SERV+=("")
SERV+=("[Install]")
SERV+=("WantedBy=graphical-session.target")

SERV_STR="$(printf '%s\n' "${SERV[@]}")"

# ========== MAIN ==========
# Check if the service is already running
if systemctl --user is-active --quiet "$SERVICE_FILE_NAME"; then
  echo "The service is already running. Do you want to update and restart it? (y/n)"
  read -r response
  if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    # Update the service file
    echo -e "$SERV_STR" > "$SERVICES_DIR/$SERVICE_FILE_NAME"
    systemctl --user daemon-reload
    restart_service
    echo_success "Service updated and restarted."
    exit 0
  else
    echo "No changes made. Exiting."
    exit 0
  fi
fi

# Check if the directory where the .service will be placed exist
services_dir_exist

# Create or overwrite the process-wallpaper.service file
echo -e "$SERV_STR" > "$SERVICES_DIR/$SERVICE_FILE_NAME"

if [ $? -eq 0 ]; then
  echo_success "File $SERVICES_DIR/$SERVICE_FILE_NAME was created successfully"
else
  echo_error "There was an error writing data to $SERVICES_DIR/$SERVICE_FILE_NAME."
  exit 1
fi

echo "Reloading daemon services, enabling, and starting the service now..."


# Reload systemd manager configuration
systemctl --user daemon-reload

# Enable the new service to start on boot
if systemctl --user enable "$SERVICE_FILE_NAME"; then
  echo_success "Service $SERVICE_FILE_NAME enabled successfully."
else
  echo_error "Failed to enable $SERVICE_FILE_NAME. Please check the service file."
  exit 1
fi

# Start the service immediately
if systemctl --user start "$SERVICE_FILE_NAME"; then
  echo_success "Service $SERVICE_FILE_NAME started successfully."
else
  echo_error "Failed to start $SERVICE_FILE_NAME. Please check the logs."
  exit 1
fi

echo_success "Setup complete"

exit 0

