#!/usr/bin/env bash
# Exercise 15.9 (Level 4): the build machine fails on a function that works on your machine.
# Builds remotes/metrickit.git, remotes/evalboard.git and your clone you/ of the service
# "evalboard", which uses the library "metrickit" as a submodule. Read SYMPTOMS.md, not this
# file: the script is the answer to "what happened".
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/labs/ex2/gen-lib.bash"
. "$COURSE_ROOT/labs/ex2/m15-fixture.bash"
ex_begin m15-evalboard

m15_lib
m15_app you
cd you || exit 1
quiet "git $FILE_OK submodule add ../metrickit.git vendor/metrickit"
quiet 'git -C vendor/metrickit checkout v0.1.0'
_c 'Add metrickit 0.1.0 as a submodule'
quiet 'git push'
cd "$LAB_DIR" || exit 1

# Ravi clones now, with the submodule at 0.1.0.
quiet "git $FILE_OK clone --recurse-submodules remotes/evalboard.git ravi"
quiet 'git -C ravi remote set-url origin ../remotes/evalboard.git'
ex_identity ravi

cd you || exit 1
as asha
quiet 'git -C vendor/metrickit checkout v0.2.0'
_c 'Use metrickit 0.2.0'
as you
put board.py <<'F'
"""evalboard: a table of evaluation runs."""

from vendor.metrickit.metrickit import rouge_l


def row(run):
    return "%-12s %s %.2f" % (run["name"], run["date"], rouge_l(run["answer"], run["reference"]))
F
_c 'Show ROUGE-L on the dashboard'
quiet 'git push'

# Ravi pulls (his submodule stays where it was), edits one file and commits everything modified.
cd "$LAB_DIR/ravi" || exit 1
as ravi
quiet "git $FILE_OK pull"
put runs.py <<'F'
def newest_first(runs):
    return sorted(runs, key=lambda run: run["date"], reverse=True)
F
quiet 'git add runs.py'
printf '\nRuns are listed newest first.\n' >> README.md
quiet "git commit -am 'Sort runs by date'"
quiet 'git push'

cd "$LAB_DIR/you" || exit 1
as asha
quiet 'git pull'
put export.py <<'F'
import csv
import sys


def export(runs):
    writer = csv.writer(sys.stdout)
    for run in runs:
        writer.writerow([run["name"], run["date"]])
F
quiet "git add export.py && git commit -m 'Add CSV export'"
as you
printf 'VERSION = "0.5.0"\n' > version.py
quiet "git add version.py && git commit -m 'Bump dashboard version to 0.5.0'"
quiet 'git push'
cd "$LAB_DIR" || exit 1
rm -rf ravi

ex_end you
