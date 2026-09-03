#!/usr/bin/env bash
#
# app.sh - small system/network diagnostic CLI
#
# Usage:
#   app.sh system-info
#   app.sh check-host <host>
#   app.sh check-port <host> <port>
#   app.sh help
#
# Exit codes:
#   0 - success
#   1 - the requested check failed (host unreachable, port closed, etc.)
#   2 - invalid usage / invalid input

set -u -o pipefail

EXIT_OK=0
EXIT_FAIL=1
EXIT_INVALID=2

usage() {
    cat <<'EOF'
Usage: app.sh <command> [arguments]

Commands:
  system-info             Display system information.
  check-host <host>       Resolve/check reachability of a host.
  check-port <host> <port>  Validate a port and check TCP connectivity.
  help                    Display this usage information.

Exit codes:
  0  success
  1  requested check failed
  2  invalid input / usage
EOF
}

cmd_system_info() {
    echo "== System Information =="
    echo "Hostname : $(hostname 2>/dev/null || echo unknown)"
    echo "Kernel   : $(uname -s 2>/dev/null)"
    echo "Release  : $(uname -r 2>/dev/null)"
    echo "Arch     : $(uname -m 2>/dev/null)"

    if command -v uptime >/dev/null 2>&1; then
        echo "Uptime   : $(uptime 2>/dev/null)"
    fi

    if [ -r /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        echo "OS       : ${PRETTY_NAME:-unknown}"
    fi

    if command -v date >/dev/null 2>&1; then
        echo "Date     : $(date)"
    fi

    return "$EXIT_OK"
}

# Basic hostname/IPv4 syntax sanity check (not a full RFC validator).
is_valid_host_format() {
    local host="$1"
    if [ -z "$host" ]; then
        return 1
    fi
    case "$host" in
        *' '*) return 1 ;;
    esac
    return 0
}

cmd_check_host() {
    if [ "$#" -ne 1 ]; then
        echo "Error: check-host requires exactly one argument: <host>" >&2
        return "$EXIT_INVALID"
    fi

    local host="$1"
    if ! is_valid_host_format "$host"; then
        echo "Error: invalid host: '$host'" >&2
        return "$EXIT_INVALID"
    fi

    echo "Checking host: $host"

    local resolved=""
    if command -v getent >/dev/null 2>&1; then
        resolved="$(getent hosts "$host" 2>/dev/null | awk '{print $1}' | head -n1)"
    elif command -v host >/dev/null 2>&1; then
        resolved="$(host "$host" 2>/dev/null | awk '/has address/ {print $4; exit}')"
    fi

    if [ -n "$resolved" ]; then
        echo "Resolved : $host -> $resolved"
    else
        echo "Resolved : could not resolve $host via DNS lookup"
    fi

    if command -v ping >/dev/null 2>&1; then
        if ping -c 1 -W 2 "$host" >/dev/null 2>&1; then
            echo "Reachable: yes (ICMP ping succeeded)"
            return "$EXIT_OK"
        else
            echo "Reachable: no (ICMP ping failed)"
        fi
    fi

    if [ -n "$resolved" ]; then
        return "$EXIT_OK"
    fi

    echo "Error: host '$host' could not be resolved or reached" >&2
    return "$EXIT_FAIL"
}

is_valid_port() {
    local port="$1"
    case "$port" in
        ''|*[!0-9]*) return 1 ;;
    esac
    if [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        return 1
    fi
    return 0
}

cmd_check_port() {
    if [ "$#" -ne 2 ]; then
        echo "Error: check-port requires exactly two arguments: <host> <port>" >&2
        return "$EXIT_INVALID"
    fi

    local host="$1"
    local port="$2"

    if ! is_valid_host_format "$host"; then
        echo "Error: invalid host: '$host'" >&2
        return "$EXIT_INVALID"
    fi

    if ! is_valid_port "$port"; then
        echo "Error: invalid port: '$port' (must be an integer 1-65535)" >&2
        return "$EXIT_INVALID"
    fi

    echo "Checking TCP connectivity: $host:$port"

    if command -v timeout >/dev/null 2>&1; then
        if timeout 5 bash -c "exec 3<>/dev/tcp/$host/$port" 2>/dev/null; then
            exec 3>&- 2>/dev/null
            echo "Port     : $port/tcp open on $host"
            return "$EXIT_OK"
        fi
    else
        if (exec 3<>"/dev/tcp/$host/$port") 2>/dev/null; then
            exec 3>&- 2>/dev/null
            echo "Port     : $port/tcp open on $host"
            return "$EXIT_OK"
        fi
    fi

    echo "Port     : $port/tcp closed or unreachable on $host" >&2
    return "$EXIT_FAIL"
}

main() {
    if [ "$#" -lt 1 ]; then
        usage >&2
        exit "$EXIT_INVALID"
    fi

    local cmd="$1"
    shift

    case "$cmd" in
        system-info)
            if [ "$#" -ne 0 ]; then
                echo "Error: system-info takes no arguments" >&2
                exit "$EXIT_INVALID"
            fi
            cmd_system_info
            exit $?
            ;;
        check-host)
            cmd_check_host "$@"
            exit $?
            ;;
        check-port)
            cmd_check_port "$@"
            exit $?
            ;;
        help|-h|--help)
            usage
            exit "$EXIT_OK"
            ;;
        *)
            echo "Error: unknown command '$cmd'" >&2
            usage >&2
            exit "$EXIT_INVALID"
            ;;
    esac
}

main "$@"
