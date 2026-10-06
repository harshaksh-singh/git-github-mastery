#!/usr/bin/env bash
# Incident 7: CI passes locally and fails on GitHub Actions.
# GitHub Actions cannot be run from this course. The generator builds the repository state
# (server.git and the clone you/ of the project "eval-reports"); the workflow file and the
# description of the failed run are in incidents/07-ci-passes-locally/evidence/. The diagnosis
# is made on paper, and the part that plain Git can show is shown with plain Git.
. "$(dirname "${BASH_SOURCE[0]}")/../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/incidents/lib/incident-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin incidents 07-ci-passes-locally
inc_begin

inc_server
inc_clone you
cd you || exit 1
mkdir -p reports templates tests scripts .github/workflows
printf '# {title}\n\nAccuracy: {accuracy}\n' > templates/summary.md.tmpl
printf 'import os\n\nHERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))\n\ndef render(title, accuracy):\n    with open(os.path.join(HERE, "templates", "summary.md.tmpl")) as f:\n        return f.read().format(title=title, accuracy=accuracy)\n' > reports/render.py
: > reports/__init__.py
: > tests/__init__.py
printf 'import unittest\nfrom reports.render import render\n\nclass RenderTest(unittest.TestCase):\n    def test_title(self):\n        self.assertIn("# Nightly", render("Nightly", 0.91))\n' > tests/test_render.py
_c 'Add report renderer'
printf '# eval-reports\n\nRenders evaluation reports. Versions come from Git tags.\n' > README.md
_c 'Add README'
quiet 'git tag -a v1.4.0 -m "Release 1.4.0"'
cp "$COURSE_ROOT/incidents/07-ci-passes-locally/evidence/ci.yml" .github/workflows/ci.yml
quiet 'git rm -q --cached .github/workflows/ci.yml'
# The workflow at first had no version step: write that earlier form, commit, then the current one.
grep -v -e 'Compute version' -e 'version="' -e 'VERSION=' -e '^        run: |$' .github/workflows/ci.yml > .github/workflows/ci.tmp
mv .github/workflows/ci.tmp .github/workflows/ci.yml
_c 'Add CI workflow'
printf '#!/usr/bin/env bash\n# Prints the version of this checkout, derived from the newest release tag.\nset -e\ngit describe --tags --match "v*"\n' > scripts/version.sh
cp "$COURSE_ROOT/incidents/07-ci-passes-locally/evidence/ci.yml" .github/workflows/ci.yml
_c 'Stamp reports with the version from git describe'
# A later refactoring renames the constant and, on a Mac, nobody notices the changed case.
printf 'import os\n\nHERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))\nTEMPLATE = os.path.join(HERE, "templates", "Summary.md.tmpl")\n\ndef render(title, accuracy):\n    with open(TEMPLATE) as f:\n        return f.read().format(title=title, accuracy=accuracy)\n' > reports/render.py
_c 'Move the template path into a constant'
quiet 'git push -u origin main v1.4.0'
quiet 'git switch -c docs/render-docstring'
printf 'import os\n\nHERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))\nTEMPLATE = os.path.join(HERE, "templates", "Summary.md.tmpl")\n\ndef render(title, accuracy):\n    """Render the summary report as Markdown."""\n    with open(TEMPLATE) as f:\n        return f.read().format(title=title, accuracy=accuracy)\n' > reports/render.py
_c 'Document render()'
quiet 'git push -u origin docs/render-docstring'
quiet 'git switch main'

inc_end
[ -n "${LAB_REPLAY:-}" ] || printf 'Incident ready. Open a lab shell there:\n  labs/shell "%s"\nThe workflow file and the run report are in incidents/07-ci-passes-locally/evidence/\n' "$LAB_DIR"
