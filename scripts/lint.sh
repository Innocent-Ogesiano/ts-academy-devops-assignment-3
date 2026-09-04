#!/usr/bin/env bash
#
# lint.sh - static checks for the assignment-3 project
#
#  1. Verify the required project files exist.
#  2. Run `bash -n` (syntax check) against every Bash script.
#  3. If shellcheck is installed, run it too (extra check, non-fatal
#     unless SHELLCHECK_STRICT=1).

set -u -o pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

status=0

REQUIRED_FILES=(
    "README.md"
    "app/app.sh"
    "scripts/lint.sh"
    "scripts/build.sh"
    "tests/test.sh"
    ".github/workflows/ci.yml"
    "Dockerfile"
    "compose.yaml"
    ".dockerignore"
)

echo "== Checking required files =="
for f in "${REQUIRED_FILES[@]}"; do
    if [ -f "$f" ]; then
        echo "  [OK]      $f"
    else
        echo "  [MISSING] $f"
        status=1
    fi
done

echo
echo "== Syntax checking Bash scripts (bash -n) =="
SHELL_SCRIPTS=()
while IFS= read -r -d '' script; do
    SHELL_SCRIPTS+=("$script")
done < <(find . -type f -name '*.sh' -not -path './.git/*' -print0 | sort -z)

if [ "${#SHELL_SCRIPTS[@]}" -eq 0 ]; then
    echo "  No shell scripts found."
else
    err_file="$(mktemp)"
    for script in "${SHELL_SCRIPTS[@]}"; do
        if bash -n "$script" 2>"$err_file"; then
            echo "  [OK]   $script"
        else
            echo "  [FAIL] $script"
            sed 's/^/         /' "$err_file"
            status=1
        fi
    done
    rm -f "$err_file"
fi

echo
echo "== ShellCheck (extra check) =="
if command -v shellcheck >/dev/null 2>&1; then
    if [ "${#SHELL_SCRIPTS[@]}" -eq 0 ]; then
        echo "  No shell scripts to check."
    else
        if shellcheck "${SHELL_SCRIPTS[@]}"; then
            echo "  [OK] shellcheck passed"
        else
            echo "  [FAIL] shellcheck reported issues"
            if [ "${SHELLCHECK_STRICT:-0}" = "1" ]; then
                status=1
            else
                echo "  (non-fatal; set SHELLCHECK_STRICT=1 to enforce)"
            fi
        fi
    fi
else
    echo "  shellcheck not installed - skipping (install it for deeper checks)"
fi

echo
if [ "$status" -eq 0 ]; then
    echo "Lint passed."
else
    echo "Lint failed." >&2
fi

exit "$status"
