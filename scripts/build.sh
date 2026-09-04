#!/usr/bin/env bash
#
# build.sh - build the devops-tool Docker image and run smoke tests
#
#   docker build -t devops-tool .
#   docker run --rm devops-tool help
#   docker run --rm devops-tool system-info
#   docker run --rm devops-tool <invalid-command>   (expects exit 2)

set -u -o pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

IMAGE_NAME="${IMAGE_NAME:-devops-tool}"

if ! command -v docker >/dev/null 2>&1; then
    echo "Error: docker is not installed or not on PATH" >&2
    exit 1
fi

status=0

echo "== Building image: $IMAGE_NAME =="
if ! docker build -t "$IMAGE_NAME" .; then
    echo "Error: docker build failed" >&2
    exit 1
fi

# smoke_test <description> <expected_exit_code> -- <docker args...>
smoke_test() {
    local desc="$1"
    local expected="$2"
    shift 2
    if [ "${1:-}" = "--" ]; then
        shift
    fi

    local output
    output="$(docker run --rm "$IMAGE_NAME" "$@" 2>&1)"
    local actual=$?

    if [ "$actual" -eq "$expected" ]; then
        echo "  [PASS] $desc (exit $actual)"
    else
        echo "  [FAIL] $desc (expected exit $expected, got $actual)"
        echo "         output: $output"
        status=1
    fi
}

echo
echo "== Smoke testing image: $IMAGE_NAME =="

smoke_test "help command"          0 -- help
smoke_test "system-info command"   0 -- system-info
smoke_test "invalid command"       2 -- bogus-command

echo
if [ "$status" -eq 0 ]; then
    echo "Build and smoke tests passed."
else
    echo "Build and smoke tests failed." >&2
fi

exit "$status"
