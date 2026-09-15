#!/usr/bin/env bash

set -u

APP_NAME="devops-tool"

show_help() {
    cat <<EOF
========================================
          DEVOPS DIAGNOSTIC CLI
========================================

Usage:
  app.sh <command> [arguments]

Commands:
  system-info
      Display Linux system information.

  check-host <host>
      Resolve the supplied host and perform a basic connectivity check.

  check-port <host> <port>
      Validate the port and check TCP connectivity.

  help
      Display this help message.

Exit codes:
  0  Success
  1  Operational/runtime failure
  2  Invalid command or input

Examples:
  ./app.sh system-info
  ./app.sh check-host google.com
  ./app.sh check-port google.com 443
  ./app.sh help
EOF
}

run_system_info() {
    echo "========================================"
    echo "          SYSTEM INFORMATION"
    echo "========================================"
    echo

    echo "Hostname:"
    hostname

    echo
    echo "Current User:"
    whoami

    echo
    echo "Operating System:"
    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        echo "${PRETTY_NAME:-Unknown Linux}"
    else
        echo "Unknown Linux"
    fi

    echo
    echo "Kernel:"
    uname -r

    echo
    echo "Architecture:"
    uname -m

    echo
    echo "Uptime:"
    uptime

    echo
    echo "CPU:"
    if command -v lscpu >/dev/null 2>&1; then
        lscpu | grep -E '^(Architecture|CPU\(s\)|Model name):' || true
    else
        echo "CPU information unavailable."
    fi

    echo
    echo "Memory:"
    if command -v free >/dev/null 2>&1; then
        free -h
    else
        echo "Memory information unavailable."
    fi

    echo
    echo "Disk:"
    df -h /

    echo
    echo "========================================"
}

run_check_host() {
    local host="$1"
    local resolved_address

    if [[ -z "$host" || "$host" =~ [[:space:]] ]]; then
        echo "Error: invalid host."
        return 2
    fi

    resolved_address=$(getent ahosts "$host" 2>/dev/null | awk 'NR==1 {print $1}')

    if [[ -z "$resolved_address" ]]; then
        echo "Error: unable to resolve host: $host"
        return 1
    fi

    echo "========================================"
    echo "             HOST CHECK"
    echo "========================================"
    echo
    echo "Host:"
    echo "$host"

    echo
    echo "Resolved Address:"
    echo "$resolved_address"

    echo
    echo "Connectivity:"

    if ! command -v ping >/dev/null 2>&1; then
        echo "Error: ping is unavailable."
        return 1
    fi

    if ping -c 1 -W 2 "$host" >/dev/null 2>&1; then
        echo "Ping: SUCCESS"
    else
        echo "Ping: FAILED"
        return 1
    fi

    echo
    echo "========================================"

    return 0
}

run_check_port() {
    local host="$1"
    local port="$2"
    local resolved_address

    if [[ -z "$host" || "$host" =~ [[:space:]] ]]; then
        echo "Error: invalid host."
        return 2
    fi

    if [[ ! "$port" =~ ^[0-9]+$ ]]; then
        echo "Error: port must be numeric."
        return 2
    fi

    if (( port < 1 || port > 65535 )); then
        echo "Error: port must be between 1 and 65535."
        return 2
    fi

    resolved_address=$(getent ahosts "$host" 2>/dev/null | awk 'NR==1 {print $1}')

    if [[ -z "$resolved_address" ]]; then
        echo "Error: unable to resolve host: $host"
        return 1
    fi

    echo "========================================"
    echo "             PORT CHECK"
    echo "========================================"
    echo
    echo "Host:"
    echo "$host"

    echo
    echo "Resolved Address:"
    echo "$resolved_address"

    echo
    echo "Port:"
    echo "$port"

    echo
    echo "TCP Connectivity:"

    if command -v nc >/dev/null 2>&1; then
        if nc -z -w 3 "$host" "$port" >/dev/null 2>&1; then
            echo "TCP Port $port: OPEN"
            return 0
        fi
    fi

    if command -v bash >/dev/null 2>&1; then
        if timeout 3 bash -c "</dev/tcp/$host/$port" >/dev/null 2>&1; then
            echo "TCP Port $port: OPEN"
            return 0
        fi
    fi

    echo "TCP Port $port: CLOSED or UNREACHABLE"
    return 1
}

if [[ $# -eq 0 ]]; then
    echo "Error: no command supplied."
    echo
    show_help
    exit 2
fi

command="$1"

case "$command" in
    system-info)
        if [[ $# -ne 1 ]]; then
            echo "Error: 'system-info' does not accept additional arguments."
            exit 2
        fi

        run_system_info
        exit $?
        ;;

    check-host)
        if [[ $# -ne 2 ]]; then
            echo "Error: 'check-host' requires a host."
            echo "Usage: ./app/app.sh check-host <host>"
            exit 2
        fi

        run_check_host "$2"
        exit $?
        ;;

    check-port)
        if [[ $# -ne 3 ]]; then
            echo "Error: 'check-port' requires a host and port."
            echo "Usage: ./app/app.sh check-port <host> <port>"
            exit 2
        fi

        run_check_port "$2" "$3"
        exit $?
        ;;

    help|-h|--help)
        if [[ $# -ne 1 ]]; then
            echo "Error: 'help' does not accept additional arguments."
            exit 2
        fi

        show_help
        exit 0
        ;;

    *)
        echo "Error: invalid command: $command"
        echo
        show_help
        exit 2
        ;;
esac

THIS_IS_A_CI_FAILURE(