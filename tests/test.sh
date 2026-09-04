#!/usr/bin/env bash
#
# test.sh - test suite for app/app.sh
#
# Exercises: help, system-info, invalid commands, a missing host argument,
# a valid host, a missing port argument, a non-numeric port, and an
# out-of-range port.

set -u -o pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT_DIR/app/app.sh"

pass_count=0
fail_count=0

# assert_exit <description> <expected_exit_code> -- <command...>
assert_exit() {
    local desc="$1"
    local expected="$2"
    shift 2
    if [ "${1:-}" = "--" ]; then
        shift
    fi

    local output
    output="$("$@" 2>&1)"
    local actual=$?

    if [ "$actual" -eq "$expected" ]; then
        echo "  [PASS] $desc (exit $actual)"
        pass_count=$((pass_count + 1))
    else
        echo "  [FAIL] $desc (expected exit $expected, got $actual)"
        echo "         output: $output"
        fail_count=$((fail_count + 1))
    fi
}

# assert_contains <description> <haystack> <needle>
assert_contains() {
    local desc="$1"
    local haystack="$2"
    local needle="$3"

    if [[ "$haystack" == *"$needle"* ]]; then
        echo "  [PASS] $desc"
        pass_count=$((pass_count + 1))
    else
        echo "  [FAIL] $desc (expected to find '$needle')"
        fail_count=$((fail_count + 1))
    fi
}

if [ ! -x "$APP" ]; then
    echo "Error: $APP not found or not executable" >&2
    exit 1
fi

echo "== Running tests against $APP =="

# 1. help command
help_output="$("$APP" help 2>&1)"
help_exit=$?
assert_exit "help exits 0" 0 -- "$APP" help
assert_contains "help output mentions merge" "$help_output" "Usage"

# 2. system-info command
info_output="$("$APP" system-info 2>&1)"
assert_exit "system-info exits 0" 0 -- "$APP" system-info
assert_contains "system-info output includes hostname" "$info_output" "Hostname"

# 3. invalid command
assert_exit "invalid command returns exit 2" 2 -- "$APP" bogus-command

# 4. no command at all
assert_exit "no command returns exit 2" 2 -- "$APP"

# 5. check-host with a missing host argument
assert_exit "check-host with missing host returns exit 2" 2 -- "$APP" check-host

# 6. check-host with a valid, reachable host
assert_exit "check-host localhost succeeds" 0 -- "$APP" check-host localhost

# 7. check-port with a missing port argument
assert_exit "check-port with missing port returns exit 2" 2 -- "$APP" check-port localhost

# 8. check-port with a non-numeric port
assert_exit "check-port with non-numeric port returns exit 2" 2 -- "$APP" check-port localhost abc

# 9. check-port with an out-of-range port
assert_exit "check-port with out-of-range port (0) returns exit 2" 2 -- "$APP" check-port localhost 0
assert_exit "check-port with out-of-range port (70000) returns exit 2" 2 -- "$APP" check-port localhost 70000

echo
echo "== Results: $pass_count passed, $fail_count failed =="

if [ "$fail_count" -eq 0 ]; then
    exit 0
else
    exit 1
fi
