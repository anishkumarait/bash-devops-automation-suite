# Linux and macOS User Login Audit Script

![Bash](https://img.shields.io/badge/Bash-Script-blue?logo=gnu-bash)
[![License](https://img.shields.io/badge/license-MIT-green)](../LICENSE)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS-blue)](https://github.com/anishkumarait/bash-devops-automation-suite/tree/main/system-health-check)

This script performs a **comprehensive user login audit** on Linux and macOS systems. It lists all system and normal users, SSH keys, last login times, sudo/admin access and password states. The output is displayed as a **table in the terminal** and saved in a **well-formatted JSON file** for further analysis.

---

## Features
- Lists all **system users** with their login shell and home directory  
- Displays **SSH authorized keys** (if available) for each user  
- Shows **last login times** using native system commands  
- Supports both **Linux** and **macOS** systems  
- Includes **robust error handling** and validation  
- Produces **clean, human-readable output in JSON format**  

---

## Prerequisites
Ensure you have the following tools installed on your system:
- `bash` (version 4 or higher)  
- `jq`  
- `lastlog` or `last` (Linux)  
- `dscl` (macOS)  

## Usage
- Clone the repository:
    ```bash
    git clone https://github.com/anishkumarait/bash-devops-automation-suite.git
    cd user-login-audit
    ```
- Make the script executable:
    ```bash
    chmod +x user_audit.sh
    ```
- Run the script with root privileges to ensure complete access:
    ```bash
    sudo ./user_audit.sh
    ```

## Sample Output (JSON file)
```json
{
"system_users": [
{
  "user": "_accessoryupdater",
  "uid": 278,
  "gid": 278,
  "home": "/var/db/accessoryupdater",
  "shell": "/usr/bin/false",
  "is_system": "yes",
  "last_login": "never",
  "ssh_key_count": 0,
  "ssh_key_fingerprints": "",
  "sudo_or_admin": "no",
  "password_state": "unknown"
},
{
  "user": "_amavisd",
  "uid": 83,
  "gid": 83,
  "home": "/var/virusmails",
  "shell": "/usr/bin/false",
  "is_system": "yes",
  "last_login": "never",
  "ssh_key_count": 0,
  "ssh_key_fingerprints": "",
  "sudo_or_admin": "no",
  "password_state": "unknown"
}
],
"normal_users": [
{
  "user": "anishkumar",
  "uid": 501,
  "gid": 20,
  "home": "/Users/anishkumar",
  "shell": "/bin/zsh",
  "is_system": "no",
  "last_login": "Oct 28 20:32 -never",
  "ssh_key_count": 2,
  "ssh_key_fingerprints": "SHA256:fNcG9zob/nbeioVGrNENte6bc/bmePkKWgyAsbgmpJg, SHA256:TH9NrFy8KyFEQMhoEg4zXFHJd1DuJUmwvgWfqAfY/n4",
  "sudo_or_admin": "admin",
  "password_state": "unknown"
}
]
}
```
