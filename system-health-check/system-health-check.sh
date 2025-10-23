#!/bin/bash
# -----------------------------------------------------------------------------
# System Health Check Script (Linux + macOS)
# Author: Anish
# Description: Collects CPU, memory, disk usage, uptime, running processes,
#              network stats, and checks system logs for anomalies.
# -----------------------------------------------------------------------------

set -euo pipefail
trap 'echo "[ERROR] Script failed at line $LINENO. Exiting."; exit 1' ERR

# Colors for output
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
NC="\033[0m"

# Detect OS
OS_TYPE="$(uname -s | tr '[:upper:]' '[:lower:]')"

# ---------------- Functions ----------------

print_header() {
    echo -e "${CYAN}=============================="
    echo -e " System Health Check - $(date) "
    echo -e "==============================${NC}"
}

# CPU usage
check_cpu() {
    echo -e "${YELLOW}-- CPU Usage --${NC}"
    if [[ "$OS_TYPE" == "darwin"* ]]; then
        # macOS: use top command
        CPU_IDLE=$(top -l 1 | awk '/CPU usage:/ {print $7}' | cut -d. -f1)
        CPU_USAGE=$((100 - CPU_IDLE))
        echo "CPU Usage: ${CPU_USAGE}%"
    else
        # Linux
        if command -v mpstat >/dev/null 2>&1; then
            mpstat | awk '/all/ {printf "CPU Usage: %.2f%%\n", 100 - $12}'
        else
            CPU_IDLE=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}' | cut -d. -f1)
            CPU_USAGE=$((100 - CPU_IDLE))
            echo "CPU Usage: ${CPU_USAGE}%"
        fi
    fi
    echo ""
}

# Memory usage
check_memory() {
    echo -e "${YELLOW}-- Memory Usage --${NC}"
    if [[ "$OS_TYPE" == "darwin"* ]]; then
        # macOS: memory summary
        vm_stat | awk '
            BEGIN {print "Memory Usage:"}
            /Pages active:/ {active=$3}
            /Pages inactive:/ {inactive=$3}
            /Pages wired down:/ {wired=$4}
            /Pages free:/ {free=$3}
            END {printf "Active: %d, Inactive: %d, Wired: %d, Free: %d (pages)\n", active, inactive, wired, free}'
    else
        free -h
    fi
    echo ""
}

# Disk usage
check_disk() {
    echo -e "${YELLOW}-- Disk Usage --${NC}"
    if [[ "$OS_TYPE" == "darwin"* ]]; then
        df -h
    else
        df -h --total | awk 'NR==1 || NR==NF'
    fi
    echo ""
}

# System uptime
check_uptime() {
    echo -e "${YELLOW}-- System Uptime --${NC}"
    if [[ "$OS_TYPE" == "darwin"* ]]; then
        uptime | awk -F'(up |,)' '{print "Uptime:" $2}'
    else
        uptime -p
    fi
    echo ""
}

# Top CPU/Memory consuming processes
check_processes() {
    echo -e "${YELLOW}-- Top 10 Memory-Consuming Processes --${NC}"
    if [[ "$OS_TYPE" == "darwin"* ]]; then
        ps -Ao pid,ppid,comm,%mem,%cpu | sort -k4 -nr | head -n 11
    else
        ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 11
    fi
    echo ""

    echo -e "${YELLOW}-- Top 10 CPU-Consuming Processes --${NC}"
    if [[ "$OS_TYPE" == "darwin"* ]]; then
        ps -Ao pid,ppid,comm,%mem,%cpu | sort -k5 -nr | head -n 11
    else
        ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 11
    fi
    echo ""
}

# Check network
check_network() {
    echo -e "${YELLOW}-- Network Stats and Open Ports --${NC}"

    if [[ "$OS_TYPE" == "darwin"* ]]; then
        echo "Network Utilization:"
        netstat -ib | awk 'NR>1 {print $1,$7,$10}' | awk '{rx[$1]+=$2; tx[$1]+=$3} END {for (i in rx) printf "Interface: %-8s RX: %-10d TX: %-10d\n", i, rx[i], tx[i]}'
        echo "Currently Used Ports:"
        lsof -i -P -n | grep LISTEN | awk '{printf "PID: %-6s PORT: %-8s PROCESS: %s\n",$2,$9,$1}' | head -n 20
        echo "Active TCP Connections:"
        netstat -anv | grep tcp | grep ESTABLISHED | wc -l | awk '{print "Total Established TCP Connections:", $1}'

    else
        echo "Network Utilization:"
        awk '/^Inter|^[a-z]/ {if($1!="Inter-|face") {rx[$1]+=$2; tx[$1]+=$10}} END {for (i in rx) printf "Interface: %-8s RX: %-10d TX: %-10d\n", i, rx[i], tx[i]}' /proc/net/dev
        echo "Currently Used Ports:"
        if [ -r /proc/net/tcp ]; then
            awk 'NR>1 {split($2,a,":"); printf "TCP PORT: %-6d STATE: %s\n", strtonum("0x"a[2]), $4}' /proc/net/tcp | head -n 20
        fi
        if [ -r /proc/net/udp ]; then
            awk 'NR>1 {split($2,a,":"); printf "UDP PORT: %-6d\n", strtonum("0x"a[2])}' /proc/net/udp | head -n 20
        fi
        EST_CONN=$(awk 'NR>1 && $4=="01" {count++} END {print count}' /proc/net/tcp)
        echo "Total Established TCP Connections: $EST_CONN"
        echo ""
    fi
    echo ""
}

# Running services
check_services() {
    echo -e "${YELLOW}-- Running Services --${NC}"
    if [[ "$OS_TYPE" == "darwin"* ]]; then
        echo "Launchctl services (first 10):"
        launchctl list | head -n 10
    elif command -v systemctl >/dev/null 2>&1; then
        systemctl list-units --type=service --state=running | awk '{printf "%-50s %-10s\n",$1,$4}' | head -n 15
    else
        echo "No service manager found."
    fi
    echo ""
}

# Check system logs (last 1 hour) for errors
check_logs() {
    echo -e "${YELLOW}-- System Logs with Errors (Last 1 Hour) --${NC}"

    if [[ "$OS_TYPE" == "darwin"* ]]; then
        log show --predicate 'eventType == logEvent' --last 1h | grep -iE "error|fail|critical" || echo "No anomalies found in macOS logs."
    else
        if command -v journalctl >/dev/null 2>&1; then
            journalctl --since "1 hour ago" -p 3 -xb || echo "No critical errors found in journal logs."
        elif [ -f /var/log/syslog ]; then
            awk -vDate="$(date --date='1 hour ago' '+%b %d %H:%M:%S')" '$0 > Date' /var/log/syslog | grep -iE "error|fail|critical" || echo "No anomalies found in syslog."
        elif [ -f /var/log/messages ]; then
            awk -vDate="$(date --date='1 hour ago' '+%b %d %H:%M:%S')" '$0 > Date' /var/log/messages | grep -iE "error|fail|critical" || echo "No anomalies found in messages log."
        else
            echo "No standard log files found."
        fi
    fi

    echo ""
}


# Summary message
summarize_report() {
    echo -e "${GREEN}System Health Check Completed Successfully.${NC}"
}

# ---------------- Main ----------------
main() {
    print_header
    check_uptime
    check_cpu
    check_memory
    check_disk
    check_processes
    check_network
    check_services
    # check_logs
    summarize_report
}

main
