# labs/ch20b/fixture.bash - shared fixture for the Chapter 20B demos and the Module 27 and 28 labs.
#
# Sourced by the scripts in this directory right after lab-env.sh. It is not a demo: the file
# name does not end in .sh, so the build and verify tools skip it.
#
# The project is "warehouse-api", a small stock service with a deploy script and release tags.
# Nothing here talks to GitHub or runs a workflow. Each script shows, with plain Git, the
# repository state that explains what a GitHub Actions run does with it.

hidden() {
  tick
  eval "$1" > /dev/null 2>&1 || { printf 'fixture: hidden step failed: %s\n' "$1" >&2; exit 1; }
}

put() {
  mkdir -p "$(dirname "$1")" && cat > "$1" || { printf 'fixture: put failed: %s\n' "$1" >&2; exit 1; }
}

commit_all() {
  tick
  { git add -A && git commit -q -m "$1"; } > /dev/null 2>&1 ||
    { printf 'fixture: commit_all failed: %s\n' "$1" >&2; exit 1; }
}

rules_v1() {
  put src/warehouse/rules.py <<'PY'
def reorder_point(daily_sales, lead_days):
    """Stock level at which a new order must be placed."""
    return daily_sales * lead_days


def needs_reorder(stock, daily_sales, lead_days):
    return stock <= reorder_point(daily_sales, lead_days)
PY
}

check_v1() {
  put tests/check_rules.py <<'PY'
import sys

sys.path.insert(0, "src")
from warehouse import rules

checks = 0
try:
    assert rules.reorder_point(4, 5) == 20
    checks += 1
    assert rules.needs_reorder(18, 4, 5) is True
    checks += 1
except Exception as error:  # one line instead of a traceback
    print("FAIL after %d checks: %s: %s" % (checks, type(error).__name__, error))
    sys.exit(1)
print("ok: %d checks" % checks)
PY
}

deploy_script() {
  put scripts/deploy.sh <<'SH'
#!/usr/bin/env bash
# Simulated deployment: prints what it would deploy and where.
set -eu
target="$1"
echo "would deploy $(git rev-parse --short HEAD) to $target"
SH
  chmod +x scripts/deploy.sh
}

workflow_files() {
  put .github/workflows/deploy.yml <<'YML'
name: Deploy
on:
  push:
    branches: [main]
permissions:
  contents: read
jobs:
  staging:
    uses: ./.github/workflows/reusable-deploy.yml
    with:
      environment: staging
YML
  put .github/workflows/reusable-deploy.yml <<'YML'
name: Reusable deploy
on:
  workflow_call:
    inputs:
      environment:
        required: true
        type: string
permissions:
  contents: read
jobs:
  deploy:
    runs-on: ubuntu-24.04
    environment: ${{ inputs.environment }}
    steps:
      - run: bash scripts/deploy.sh "$TARGET"
        env:
          TARGET: ${{ inputs.environment }}
YML
}

# make_warehouse
# Builds the repository in ./warehouse-api and leaves the shell inside it, on main.
#   6 commits on main; annotated tags v1.0.0 (2nd commit) and v1.1.0 (4th commit).
make_warehouse() {
  hidden 'git init warehouse-api'
  cd warehouse-api || exit 1
  printf '# warehouse-api\n\nStock rules for the warehouse service.\n' > README.md
  printf '[project]\nname = "warehouse-api"\nversion = "0.0.0"\nrequires-python = ">=3.11"\n' > pyproject.toml
  printf '__pycache__/\n.venv/\ndist/\n' > .gitignore
  : | put src/warehouse/__init__.py
  rules_v1
  check_v1
  commit_all 'Add stock rules and their checks'
  deploy_script
  commit_all 'Add the deploy script'
  hidden 'git tag -a v1.0.0 -m "Release 1.0.0"'
  printf 'reorder:\n  lead_days: 5\n  safety_stock: 10\n' | put configs/Thresholds.yaml
  commit_all 'Add reorder thresholds'
  workflow_files
  commit_all 'Add the deploy workflows'
  hidden 'git tag -a v1.1.0 -m "Release 1.1.0"'
  printf '# Release runbook\n\n1. Tag the release.\n2. Watch the deploy workflow.\n' | put docs/runbook.md
  commit_all 'Document the release runbook'
  printf 'version = 1\nrequires-python = ">=3.11"\n\n[[package]]\nname = "warehouse-api"\nversion = "0.0.0"\n' > uv.lock
  commit_all 'Add the lock file'
}

# scenario_branches
# After make_warehouse: two topic branches from main, one that changes only documentation and
# one that changes code and the lock file. Leaves the shell on main.
scenario_branches() {
  hidden 'git switch -c docs/rollback-steps'
  printf '3. To roll back, re-run the last good deployment.\n' >> docs/runbook.md
  commit_all 'Describe the rollback step'
  hidden 'git switch main'
  hidden 'git switch -c feature/safety-stock'
  printf '\n\ndef with_safety(point, safety_stock):\n    return point + safety_stock\n' >> src/warehouse/rules.py
  printf '\n[[package]]\nname = "pyyaml"\nversion = "6.0.3"\n' >> uv.lock
  commit_all 'Add safety stock and its dependency'
  hidden 'git switch main'
}

# scenario_merge_ref
# After make_warehouse: main and feature/bulk-reorder each pass their own checks, and the merge
# of the two does not. Leaves the shell on feature/bulk-reorder.
scenario_merge_ref() {
  hidden 'git switch -c feature/bulk-reorder'
  put src/warehouse/bulk.py <<'PY'
from warehouse.rules import needs_reorder


def items_to_reorder(items, lead_days):
    return [name for name, stock, daily in items if needs_reorder(stock, daily, lead_days)]
PY
  put tests/check_bulk.py <<'PY'
import sys

sys.path.insert(0, "src")
from warehouse import bulk

try:
    found = bulk.items_to_reorder([("bolt", 18, 4), ("nut", 90, 4)], 5)
    assert found == ["bolt"], found
except Exception as error:  # one line instead of a traceback
    print("FAIL: %s: %s" % (type(error).__name__, error))
    sys.exit(1)
print("ok: bulk reorder")
PY
  commit_all 'Add bulk reorder'
  hidden 'git switch main'
  put src/warehouse/rules.py <<'PY'
def reorder_point(daily_sales, lead_days, safety_stock):
    """Stock level at which a new order must be placed."""
    return daily_sales * lead_days + safety_stock


def needs_reorder(stock, daily_sales, lead_days, safety_stock):
    return stock <= reorder_point(daily_sales, lead_days, safety_stock)
PY
  put tests/check_rules.py <<'PY'
import sys

sys.path.insert(0, "src")
from warehouse import rules

checks = 0
try:
    assert rules.reorder_point(4, 5, 10) == 30
    checks += 1
    assert rules.needs_reorder(28, 4, 5, 10) is True
    checks += 1
except Exception as error:  # one line instead of a traceback
    print("FAIL after %d checks: %s: %s" % (checks, type(error).__name__, error))
    sys.exit(1)
print("ok: %d checks" % checks)
PY
  as asha
  commit_all 'Require a safety stock in the reorder rules'
  as you
  hidden 'git switch feature/bulk-reorder'
}

# scenario_deployed
# After make_warehouse: two bookkeeping refs that stand in for GitHub's deployment records
# (GitHub keeps those as platform objects, not as refs), and a hotfix branch that is not merged.
scenario_deployed() {
  hidden 'git update-ref refs/deployed/production v1.1.0^{commit}'
  hidden 'git update-ref refs/deployed/staging main'
  hidden 'git switch -c hotfix/lead-days'
  printf 'reorder:\n  lead_days: 7\n  safety_stock: 10\n' > configs/Thresholds.yaml
  commit_all 'Raise the lead time to seven days'
  hidden 'git switch main'
}

# scenario_reusable
# After make_warehouse: a branch on which the called workflow gains an input.
scenario_reusable() {
  hidden 'git switch -c ci/python-version'
  put .github/workflows/reusable-deploy.yml <<'YML'
name: Reusable deploy
on:
  workflow_call:
    inputs:
      environment:
        required: true
        type: string
      python-version:
        required: false
        type: string
        default: "3.12"
permissions:
  contents: read
jobs:
  deploy:
    runs-on: ubuntu-24.04
    environment: ${{ inputs.environment }}
    steps:
      - run: bash scripts/deploy.sh "$TARGET"
        env:
          TARGET: ${{ inputs.environment }}
YML
  commit_all 'Let callers choose the Python version'
  hidden 'git switch main'
}
