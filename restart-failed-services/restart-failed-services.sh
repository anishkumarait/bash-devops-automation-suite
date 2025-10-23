#!/usr/bin/env bash
#
# auto_restart_failed_services.sh
#
# Description:
#   Detects failed or inactive services and attempts to restart them automatically.
#   Works on both Linux (systemd) and macOS (launchd).

set -euo pipefail

##############################################
# Global Variables
##############################################
LOG_FILE=""

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  LOG_FILE="/var/log/service_monitor.log"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  LOG_FILE="$HOME/Library/Logs/service_monitor.log"
else
  echo "Unsupported operating system: $OSTYPE" >&2
  exit 1
fi

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

##############################################
# Logging Function
##############################################
log() {
  local LEVEL="$1"
  shift
  local MESSAGE="$*"
  local TIMESTAMP
  TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$TIMESTAMP] [$LEVEL] $MESSAGE" | tee -a "$LOG_FILE"
}

##############################################
# Error Handling (Try/Catch simulation)
##############################################
handle_error() {
  local EXIT_CODE=$?
  log "ERROR" "An error occurred on line ${BASH_LINENO[0]} (exit code: $EXIT_CODE)."
  exit $EXIT_CODE
}
trap handle_error ERR

##############################################
# Linux: Detect and Restart Failed systemd Services
##############################################
restart_failed_systemd_services() {
  log "INFO" "Checking for failed systemd services..."
  local FAILED_SERVICES
  FAILED_SERVICES=$(systemctl --failed --no-legend --no-pager | awk '{print $1}')

  if [[ -z "$FAILED_SERVICES" ]]; then
    log "INFO" "No failed systemd services detected."
    return
  fi

  log "INFO" "Detected failed services: $FAILED_SERVICES"
  for SERVICE in $FAILED_SERVICES; do
    log "INFO" "Attempting to restart service: $SERVICE"
    if systemctl restart "$SERVICE"; then
      log "SUCCESS" "Successfully restarted service: $SERVICE"
    else
      log "ERROR" "Failed to restart service: $SERVICE"
    fi
  done
}

##############################################
# macOS: Detect and Restart Failed launchd Services
##############################################
restart_failed_launchd_services() {
  log "INFO" "Checking for inactive launchd services..."
  local INACTIVE_SERVICES
  INACTIVE_SERVICES=$(launchctl list | awk '$3 == "-" {print $1}' | grep -v "^-" || true)

  if [[ -z "$INACTIVE_SERVICES" ]]; then
    log "INFO" "No inactive launchd services detected."
    return
  fi

  log "INFO" "Detected inactive services: $INACTIVE_SERVICES"
  for SERVICE in $INACTIVE_SERVICES; do
    log "INFO" "Attempting to restart launchd service: $SERVICE"
    if launchctl kickstart -k "system/$SERVICE" 2>/dev/null || launchctl kickstart -k "gui/$(id -u)/$SERVICE" 2>/dev/null; then
      log "SUCCESS" "Successfully restarted launchd service: $SERVICE"
    else
      log "ERROR" "Failed to restart launchd service: $SERVICE"
    fi
  done
}

##############################################
# Main Execution
##############################################
main() {
  log "INFO" "========== Service Monitor Started =========="
  log "INFO" "Running on OS: $OSTYPE"

  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    restart_failed_systemd_services
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    restart_failed_launchd_services
  else
    log "ERROR" "Unsupported OS detected. Exiting."
    exit 1
  fi

  log "INFO" "========== Service Monitor Completed =========="
}

main "$@"
