# labs/ch20a/fixture.bash - shared fixture for the Chapter 20A demos and the Module 26 labs.
#
# Sourced by the scripts in this directory right after lab-env.sh. It is not a demo: the file
# name does not end in .sh, so the build and verify tools skip it.
#
# The project is a reduced "inventory-api" (the real one is sample-project/ in the course
# folder). The fixture writes its own small files, so that the commit IDs in the book do not
# change when the sample project is edited.
#
#   $LAB_DIR/hub/inventory-api.git   a bare repository that plays the repository on GitHub
#   $LAB_DIR/you/inventory-api       your clone
#
# Nothing here talks to GitHub or runs a workflow. Where a script imitates what a runner or the
# platform does (a shallow fetch, a ref under refs/pull/), the chapter names the documented
# behavior that is imitated and says that the commands are plain Git chosen by the author.

# hidden '<command line>': a setup step the transcript does not show. A failure stops the script.
hidden() {
  tick
  eval "$1" > /dev/null 2>&1 || { printf 'fixture: hidden step failed: %s\n' "$1" >&2; exit 1; }
}

# put <path>: write standard input to the file, creating its directory.
put() {
  mkdir -p "$(dirname "$1")" && cat > "$1" || { printf 'fixture: put failed: %s\n' "$1" >&2; exit 1; }
}

_stock_v1() {
  put src/inventory_api/stock.py <<'PY'
"""Stock arithmetic."""

LOW_STOCK_THRESHOLD = 5


def receive(stock, sku, quantity):
    updated = dict(stock)
    updated[sku] = updated.get(sku, 0) + quantity
    return updated


def low_stock(stock, threshold=LOW_STOCK_THRESHOLD):
    return sorted(sku for sku, quantity in stock.items() if quantity <= threshold)
PY
}

_tests_v1() {
  put tests/test_stock.py <<'PY'
import unittest

from inventory_api.stock import low_stock, receive


class StockTests(unittest.TestCase):
    def test_receive(self):
        self.assertEqual(receive({"bolt": 3}, "bolt", 2), {"bolt": 5})

    def test_low_stock_uses_the_default_threshold(self):
        self.assertEqual(low_stock({"bolt": 5, "nut": 8}), ["bolt"])
PY
}

# scenario_base: hub and your clone, three commits on main, an annotated tag v0.1.0 on the second.
scenario_base() {
  cd "$LAB_DIR" || exit 1
  hidden 'git init --bare hub/inventory-api.git'
  hidden 'git init you/inventory-api'
  cd you/inventory-api || exit 1
  hidden 'git remote add origin ../../hub/inventory-api.git'
  printf '# inventory-api\n\nStock arithmetic for a small inventory service.\n' | put README.md
  printf '[project]\nname = "inventory-api"\nversion = "0.1.0"\nrequires-python = ">=3.11"\n' | put pyproject.toml
  : | put src/inventory_api/__init__.py
  _stock_v1
  _tests_v1
  hidden 'git add . && git commit -m "Add stock functions and tests"'
  printf '<project>\n  <artifactId>java-service</artifactId>\n  <version>0.1.0</version>\n</project>\n' | put java-service/pom.xml
  hidden 'git add . && git commit -m "Add Maven module for price calculation"'
  hidden 'git tag -a v0.1.0 -m "inventory-api 0.1.0"'
  printf '\nRun the tests with: PYTHONPATH=src python3 -m unittest discover -s tests\n' >> README.md
  hidden 'git commit -am "Document how to run the tests"'
  hidden 'git push -u origin main && git push origin v0.1.0'
}

# scenario_pull_request: on top of scenario_base, a feature branch with one commit (the pull
# request head), pushed; then Asha changes the default threshold on main, which the feature
# branch does not have. The two changes merge without a textual conflict.
scenario_pull_request() {
  scenario_base
  hidden 'git switch -c feature/reorder-report'
  put src/inventory_api/report.py <<'PY'
"""Which SKUs to reorder."""

from inventory_api.stock import low_stock


def reorder_report(stock):
    return [f"reorder {sku}" for sku in low_stock(stock)]
PY
  put tests/test_report.py <<'PY'
import unittest

from inventory_api.report import reorder_report


class ReportTests(unittest.TestCase):
    def test_reorders_only_low_stock(self):
        self.assertEqual(reorder_report({"bolt": 5, "nut": 8}), ["reorder bolt"])
PY
  hidden 'git add . && git commit -m "Add reorder report"'
  hidden 'git push -u origin feature/reorder-report'
  hidden 'git switch main'
  as asha
  hidden "sed -i.bak 's/LOW_STOCK_THRESHOLD = 5/LOW_STOCK_THRESHOLD = 10/' src/inventory_api/stock.py && rm src/inventory_api/stock.py.bak"
  hidden "sed -i.bak 's/\\[\"bolt\"\\])/[\"bolt\", \"nut\"])/' tests/test_stock.py && rm tests/test_stock.py.bak"
  hidden 'git commit -am "Raise the default low-stock threshold to 10"'
  hidden 'git push origin main'
  as you
}

# server_open_pr <number> <head-branch>: on the hub, imitate the Git data of an open pull request:
# refs/pull/N/head, and a test merge commit under refs/pull/N/merge (Chapter 17, section 17.2).
server_open_pr() {
  ( cd "$LAB_DIR/hub/inventory-api.git" || exit 1
    tick
    git update-ref "refs/pull/$1/head" "refs/heads/$2" || exit 1
    tree=$(git merge-tree --write-tree main "refs/pull/$1/head") || exit 1
    merge=$(GIT_AUTHOR_NAME=GitHub GIT_AUTHOR_EMAIL=noreply@github.com \
            GIT_COMMITTER_NAME=GitHub GIT_COMMITTER_EMAIL=noreply@github.com \
            git commit-tree "$tree" -p main -p "refs/pull/$1/head" \
              -m "Merge $(git rev-parse "refs/pull/$1/head") into $(git rev-parse main)") || exit 1
    git update-ref "refs/pull/$1/merge" "$merge"
  ) || { printf 'fixture: server_open_pr failed\n' >&2; exit 1; }
}
