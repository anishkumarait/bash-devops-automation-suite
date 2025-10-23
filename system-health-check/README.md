# System Health Check Script

[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS-blue)](https://github.com/<your-username>/system-health-check)

A **cross-platform system health check script** for **DevOps, SREs, and Cloud engineers**. Provides a **quick overview of system health**, including CPU, memory, disk, network utilization, running processes, services, and recent system logs. Fully **non-blocking**, color-coded, and safe for production use.

---

## Purpose

The purpose of this script is to give engineers a **single-command tool** to quickly assess system health. It helps with:

- Identifying **high CPU or memory-consuming processes**
- Checking **disk usage and availability**
- Monitoring **network utilization and open ports**
- Viewing **recent system logs for errors**
- Listing **running services**
- Performing **uptime and system load checks**

This script is **cross-platform** and handles **permissions gracefully**.

---

## Features / Functions

### `check_uptime()`
Displays system uptime and load average.

### `check_cpu()`
Shows CPU usage and load percentage.

### `check_memory()`
Displays memory usage, including total, used, free, and swap.

### `check_disk()`
Shows disk usage for mounted filesystems.

### `check_processes()`
Lists top 10 memory-consuming and top 10 CPU-consuming processes.

### `check_network()`
Shows network statistic:
- Network utilization (incoming/outgoing traffic per interface)
- Currently used/listening ports
- Active TCP connections

### `check_services()`
Lists running services.
- Linux: `systemctl list-units --type=service --state=running`
- macOS: `launchctl list`

### `check_logs()`
Displays recent system logs (last 1 hour) with errors, failures, or critical events.

## Usage
- Clone the repository:
```bash
git clone https://github.com/<your-username>/system-health-check.git
cd system-health-check
```

- Make the script executable:
```bash
chmod +x system-health-check.sh
```

- Run the script:
```bash
# Non-root (basic info)
./system-health-check.sh

# Root (full network and process info)
sudo ./system-health-check.sh
```

## Sample Output
```bash
-- System Uptime --
up 3 days, 4 hours, 22 minutes
Load Average: 0.15 0.10 0.05

-- CPU Usage --
CPU Usage: 12%

-- Memory Usage --
Total: 16GB
Used: 8.5GB
Free: 7.5GB
Swap Used: 1GB

-- Disk Usage --
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1       100G   70G   30G  70% /

-- Network Stats and Open Ports --
Network Utilization:
Interface: eth0  RX: 12345678  TX: 9876543

Currently Used Ports:
TCP PORT: 22     STATE: 01
UDP PORT: 12345

Total Established TCP Connections: 5

-- Top 10 Memory-Consuming Processes --
PID    PPID   CMD               %MEM %CPU
1234   1      java              12.5 30.0
5678   1      python3           8.0  10.0

-- Running Services --
nginx.service                             running
ssh.service                               running

-- System Logs with Errors (Last 1 Hour) --
Feb 23 10:15:32 server sshd[1234]: Failed password for root from 192.168.1.1
No anomalies found in messages log.
```