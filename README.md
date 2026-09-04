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
assignment-3/
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
