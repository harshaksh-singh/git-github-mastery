# Shared fixture for the Chapter 21A demos and the Module 29 lab replays.
# Sourced by each script after lab_begin or sandbox_begin; builds everything in the current directory.

# wf_repo: a repository "inventory-api" whose .github/workflows/ holds the course's
# secure workflow and the five teaching workflows of workflows/vulnerable/.
wf_repo() {
  quiet 'git init inventory-api'
  cd inventory-api || return 1
  mkdir -p .github/workflows
  cp "$COURSE_ROOT/workflows/12-secure.yml" .github/workflows/
  cp "$COURSE_ROOT"/workflows/vulnerable/*.yml .github/workflows/
  printf '# inventory-api\n\nPractice copy for the Module 29 labs.\n' > README.md
  quiet 'git add . && git commit -m "Add the Module 29 workflows"'
}

# review_repo: a repository with a small, sound CI workflow on main and a branch
# "feature/coverage-comment" (by ravi) that changes it. Constructed for Lab 29.3.
review_repo() {
  quiet 'git init inventory-api'
  cd inventory-api || return 1
  mkdir -p .github/workflows
  cat > .github/workflows/ci.yml <<'YAML'
name: ci

on:
  pull_request:
  push:
    branches: [main]

permissions:
  contents: read

jobs:
  test:
    runs-on: ubuntu-24.04
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          persist-credentials: false
      - uses: astral-sh/setup-uv@c18668ad3cf93ea998bef934396af7bb5c839dc7 # v10.2.0
      - run: uv sync --locked
      - run: uv run pytest
YAML
  printf '# inventory-api\n' > README.md
  quiet 'git add . && git commit -m "Add CI"'
  quiet 'git switch -c feature/coverage-comment'
  as ravi
  cat > .github/workflows/ci.yml <<'YAML'
name: ci

on:
  pull_request_target:
  push:
    branches: [main]

permissions:
  contents: write
  pull-requests: write

env:
  COVERAGE_TOKEN: ${{ secrets.COVERAGE_TOKEN }}
  PYPI_API_TOKEN: ${{ secrets.PYPI_API_TOKEN }}

jobs:
  test:
    runs-on: [self-hosted, linux]
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          ref: ${{ github.event.pull_request.head.sha }}
          allow-unsafe-pr-checkout: true
      - uses: astral-sh/setup-uv@c18668ad3cf93ea998bef934396af7bb5c839dc7 # v10.2.0
      - run: uv sync --locked
      - run: uv run pytest
      - name: Install the coverage uploader
        run: curl -sSL https://coverage-tool.example.com/install.sh | bash
      - name: Announce
        run: echo "Coverage for ${{ github.head_ref }} uploaded"
      - uses: example-org/coverage-comment@v3
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
YAML
  cat > .github/workflows/release.yml <<'YAML'
name: release

on:
  push:
    tags: ["v*"]

jobs:
  publish:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v7
      - uses: astral-sh/setup-uv@c18668ad3cf93ea998bef934396af7bb5c839dc7 # v10.2.0
        with:
          enable-cache: true
      - run: uv build
      - name: Publish
        run: uv publish --token "${{ secrets.PYPI_API_TOKEN }}"
YAML
  quiet 'git add . && git commit -m "Post coverage comments on fork pull requests; add release workflow"'
  as you
  quiet 'git switch main'
}
