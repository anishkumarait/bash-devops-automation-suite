# auto_restart_failed_services.sh

**Detect and automatically restart failed `systemd` (Linux) and `launchd` (macOS) services.**

---

## Overview

`auto_restart_failed_services.sh` is a **production-grade Bash script** that continuously monitors your system’s services and automatically restarts any that have failed or become inactive.

It supports both:
- **Linux (systemd-based)** systems  
- **macOS (launchd-based)** systems  

This script is designed for **DevOps engineers, system administrators, and SREs** who need lightweight, automated self-healing for critical services without relying on external monitoring tools.

---

## Features

✅ Detects **failed `systemd` services** on Linux  
✅ Detects **inactive `launchd` services** on macOS  
✅ **Automatically restarts** failed/inactive services  
✅ Detailed **timestamped logging**  
✅ Easily automated using **cron** (Linux) or **launchd** (macOS)

---

## Usage

- Clone the repository:
```bash
git clone https://github.com/anishkumarait/bash-devops-automation-suite.git
cd restart-failed-services

- Make the script executable:
```bash
chmod +x restart-failed-services.sh
```
- Run the script:
```bash
./restart-failed-services.sh

# Root perms
sudo ./restart-failed-services.sh
```

## Sample Output
```bash
[2025-10-23 11:25:02] [INFO] ========== Service Monitor Started ==========
[2025-10-23 11:25:02] [INFO] Running on OS: linux-gnu
[2025-10-23 11:25:02] [INFO] Checking for failed systemd services...
[2025-10-23 11:25:02] [INFO] Detected failed services: nginx
[2025-10-23 11:25:03] [SUCCESS] Successfully restarted service: nginx
[2025-10-23 11:25:03] [INFO] ========== Service Monitor Completed ==========
```
