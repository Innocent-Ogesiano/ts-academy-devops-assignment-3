# Assignment 3 — CI/CD with GitHub Actions

A local CI pipeline for a small Bash application. The pipeline validates the
code, runs tests, and builds/smoke-tests a Docker image. There is no cloud
deployment.

## Application

```
./app/app.sh system-info
./app/app.sh check-host <host>
./app/app.sh check-port <host> <port>
./app/app.sh help
```

- `system-info` — display system information.
- `check-host` — resolve/check a host.
- `check-port` — validate the port and check TCP connectivity.
- `help` — display usage.
- Invalid input returns exit code 2.

## Project layout

```
.
├── README.md
├── app/
│   └── app.sh
├── scripts/
│   ├── lint.sh
│   └── build.sh
├── tests/
│   └── test.sh
├── .github/
│   └── workflows/
│       └── ci.yml
├── Dockerfile
├── compose.yaml
├── .dockerignore
└── grade.sh
```

## Local usage

```bash
./scripts/lint.sh    # validate required files exist + bash -n syntax check
./tests/test.sh       # run the test suite
./scripts/build.sh    # build the Docker image
```

## Verifying the test suite catches failures

To confirm `tests/test.sh` actually fails when the app misbehaves (rather than
passing regardless), a failure was injected and then reverted:

- **Injection**: in the `help` test, the `assert_contains` needle was changed
  from `"Usage"` to `"NoSuchString"`, which is not in the app's help output.
- **Result**: the suite reported `[FAIL] help output mentions merge (expected
  to find 'NoSuchString')` and exited non-zero (11 passed, 1 failed).
- **Fix**: the needle was reverted to `"Usage"`, restoring 12/12 passing.

This confirms the harness's exit code and pass/fail reporting are meaningful,
not just always-green. Note: an earlier edit to that line only changed the
test's *description* string (to "mentions merge") without touching the
needle — that edit didn't affect the assertion, so the test kept passing as
expected; only changing the needle itself reproduces a real failure.
