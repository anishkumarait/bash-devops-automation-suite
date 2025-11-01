#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

OS="$(uname -s)"
DATE="$(date +%Y-%m-%d_%H-%M-%S)"
OUT_JSON="user_audit_${DATE}.json"

trap 'echo "Error detected at line $LINENO. Exit code $?"; exit 5' ERR

command -v awk >/dev/null 2>&1 || { echo "awk is required"; exit 1; }
command -v stat >/dev/null 2>&1 || { echo "stat is required"; exit 1; }

json_escape() {
  local str="$1"
  str="${str//\\/\\\\}"
  str="${str//\"/\\\"}"
  str=$(echo "$str" | tr -d '\000-\031')
  echo "$str"
}

is_system_uid() {
  local uid=$1
  if [[ "$OS" == "Darwin" ]]; then
    [[ "$uid" -lt 500 ]] && return 0 || return 1
  else
    [[ "$uid" -lt 1000 ]] && return 0 || return 1
  fi
}

read_users() {
  if [[ "$OS" == "Darwin" ]]; then
    dscl . -list /Users | while read -r user; do
      uid=$(dscl . -read /Users/"$user" UniqueID 2>/dev/null | awk '{print $2}')
      gid=$(dscl . -read /Users/"$user" PrimaryGroupID 2>/dev/null | awk '{print $2}')
      home=$(dscl . -read /Users/"$user" NFSHomeDirectory 2>/dev/null | awk '{print $2}')
      shell=$(dscl . -read /Users/"$user" UserShell 2>/dev/null | awk '{print $2}')
      [[ -n "$uid" && -n "$home" ]] && echo "$user:$uid:$gid:$home:$shell"
    done
  else
    awk -F: 'NF == 7 && $0 !~ /^#/ {print $1":"$3":"$4":"$6":"$7}' /etc/passwd
  fi
}

scan_ssh_keys() {
  local home_dir="$1"
  local count=0
  local fingerprints=""
  if [[ -d "$home_dir/.ssh" ]]; then
    for key in "$home_dir"/.ssh/authorized_keys "$home_dir"/.ssh/*.pub; do
      [[ -f "$key" ]] || continue
      while read -r line; do
        [[ -z "$line" || "$line" == "#"* ]] && continue
        fp=$(echo "$line" | ssh-keygen -lf /dev/stdin 2>/dev/null | awk '{print $2}' || true)
        [[ -n "$fp" ]] && {
          fingerprints+="${fp};;"
          ((count++))
        }
      done < "$key"
    done
  fi
  echo "${count}|${fingerprints}"
}

get_last_login() {
  local user="$1"
  if [[ "$OS" == "Darwin" ]]; then
    last | grep -m1 "^$user" | awk '{print $4,$5,$6,$7}' || echo "never"
  else
    command -v lastlog >/dev/null 2>&1 || { echo "lastlog command required"; return 0; }
    lastlog -u "$user" 2>/dev/null | awk 'NR==2 { if ($4=="**Never") print "never"; else print $4,$5,$6,$7,$8 }'
  fi
}

has_sudo() {
  local user="$1"
  if [[ "$OS" == "Darwin" ]]; then
    id -Gn "$user" | grep -q admin && echo "admin" || echo "no"
  else
    id -Gn "$user" | grep -qE "(sudo|wheel)" && echo "sudo" || echo "no"
  fi
}

get_password_lock_state() {
  local user="$1"
  if [[ "$OS" == "Darwin" ]]; then
    pwpolicy -u "$user" getaccountpolicies 2>/dev/null | grep -q "policyCategoryPassword" && echo "active" || echo "unknown"
  else
    passwd -S "$user" 2>/dev/null | awk '{print $2}' | grep -q 'L' && echo "locked" || echo "active"
  fi
}

print_header() {
  printf "\n%-20s %-6s %-6s %-30s %-15s %-15s %-8s %-6s\n" \
    "User" "UID" "GID" "Home Directory" "Shell" "Last Login" "SSH Keys" "Sudo"
  printf "%-20s %-6s %-6s %-30s %-15s %-15s %-8s %-6s\n" \
    "--------------------" "------" "------" "------------------------------" "---------------" "---------------" "--------" "------"
}

echo "Starting user login audit for ${OS}"
[[ $EUID -ne 0 ]] && echo "Warning You are not root Some fields may be incomplete For full output run as root" >&2

print_header

SYSTEM_JSON_ARRAY=()
NORMAL_JSON_ARRAY=()

while IFS=: read -r user uid gid home shell; do
  [[ -z "$user" || "$user" == "#"* ]] && continue
  [[ -z "$uid" || -z "$gid" ]] && continue

  is_system_uid "$uid" && system_user="yes" || system_user="no"

  last_login="$(get_last_login "$user")"
  ssh_info="$(scan_ssh_keys "${home}")"
  ssh_count="${ssh_info%%|*}"
  ssh_fps="${ssh_info#*|}"
  ssh_fps_display="$(echo "$ssh_fps" | sed -E 's/;;$//; s/;;/, /g')"

  sudo_flag="$(has_sudo "$user")"
  pw_state="$(get_password_lock_state "$user")"

  display_home="$home"
  [[ ${#display_home} -gt 30 ]] && display_home="...${display_home: -27}"

  # Print to terminal
  printf "%-20s %-6s %-6s %-30s %-15s %-15s %-8s %-6s\n" \
    "$user" "$uid" "$gid" "$display_home" "$shell" "$last_login" "$ssh_count" "$sudo_flag"

  # Prepare JSON object
  json_entry=$(cat <<EOF
{
  "user": "$(json_escape "$user")",
  "uid": $uid,
  "gid": $gid,
  "home": "$(json_escape "$home")",
  "shell": "$(json_escape "$shell")",
  "is_system": "$system_user",
  "last_login": "$(json_escape "$last_login")",
  "ssh_key_count": $ssh_count,
  "ssh_key_fingerprints": "$(json_escape "$ssh_fps_display")",
  "sudo_or_admin": "$sudo_flag",
  "password_state": "$pw_state"
}
EOF
)

  [[ "$system_user" == "yes" ]] && SYSTEM_JSON_ARRAY+=("$json_entry") || NORMAL_JSON_ARRAY+=("$json_entry")

done < <(read_users)

SYSTEM_JSON=$(printf "%s,\n" "${SYSTEM_JSON_ARRAY[@]}" | sed '$s/,$//')
NORMAL_JSON=$(printf "%s,\n" "${NORMAL_JSON_ARRAY[@]}" | sed '$s/,$//')

{
  echo "{"
  echo "\"system_users\": ["
  echo "$SYSTEM_JSON"
  echo "],"
  echo "\"normal_users\": ["
  echo "$NORMAL_JSON"
  echo "]"
  echo "}"
} > "${OUT_JSON}"

echo -e "\n✅ User audit completed. Output saved to ${OUT_JSON}"
