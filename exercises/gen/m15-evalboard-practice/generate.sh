#!/usr/bin/env bash
# Practice repositories for the Module 15 exercises 15.1 to 15.8 (submodules, subtrees, Git LFS).
# Each exercise has its own directory ex-15-N/ with the service "evalboard" and, where needed,
# the library "metrickit" in a bare repository under remotes/.
# Do the exercises before you read this file: the script is the answer to several of them.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/labs/ex2/gen-lib.bash"
. "$COURSE_ROOT/labs/ex2/m15-fixture.bash"
ex_begin m15-evalboard-practice

# with_submodule <clone>: record metrickit v0.2.0 as a submodule in the clone, commit and push.
with_submodule() {
  (
    cd "$1" || exit 1
    quiet "git $FILE_OK submodule add ../metrickit.git vendor/metrickit"
    quiet 'git -C vendor/metrickit checkout v0.2.0'
    _c 'Add metrickit 0.2.0 as a submodule'
    quiet 'git push'
  )
  _lab_clock=$((_lab_clock + 240)); tick
}

# ---------------------------------------------------------------- 15.1 add a submodule
mkdir ex-15-1 && cd ex-15-1 || exit 1
m15_lib; m15_app evalboard
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 15.2 a first LFS pointer
mkdir ex-15-2 && cd ex-15-2 || exit 1
m15_app evalboard
m15_weights evalboard/weights/encoder.bin encoder-v1 300000
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 15.3 the same library as a subtree
mkdir ex-15-3 && cd ex-15-3 || exit 1
m15_lib; m15_app evalboard
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 15.4 what "submodule status" says
mkdir ex-15-4 && cd ex-15-4 || exit 1
m15_lib; m15_app seed; with_submodule seed
rm -rf seed
quiet 'git clone remotes/evalboard.git fresh'
quiet 'git -C fresh remote set-url origin ../remotes/evalboard.git'
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 15.5 draw the subtree graph
mkdir ex-15-5 && cd ex-15-5 || exit 1
m15_lib; m15_app evalboard
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 15.6 tracked too late
mkdir ex-15-6 && cd ex-15-6 || exit 1
m15_app evalboard
m15_weights evalboard/weights/encoder.bin encoder-v1 300000
( cd evalboard && _c 'Add encoder weights' )
_lab_clock=$((_lab_clock + 60)); tick
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 15.7 an empty directory on the build machine
mkdir ex-15-7 && cd ex-15-7 || exit 1
m15_lib; m15_app seed; with_submodule seed
( cd seed && put board.py <<'F'
"""evalboard: a table of evaluation runs."""

from vendor.metrickit.metrickit import rouge_l


def row(run):
    return "%-12s %s %.2f" % (run["name"], run["date"], rouge_l(run["answer"], run["reference"]))
F
  _c 'Show ROUGE-L on the dashboard'; quiet 'git push' )
_lab_clock=$((_lab_clock + 120)); tick
rm -rf seed
quiet 'git clone remotes/evalboard.git ci'
quiet 'git -C ci remote set-url origin ../remotes/evalboard.git'
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 15.8 a model file of 131 bytes
mkdir ex-15-8 && cd ex-15-8 || exit 1
m15_app seed
( cd seed || exit 1
  quiet 'git lfs install --local'
  quiet 'git lfs track "*.bin"'
  _c 'Track model weights with Git LFS'
  m15_weights weights/encoder.bin encoder-v1 300000
  put load.py <<'F'
import pickle


def load(path="weights/encoder.bin"):
    return pickle.load(open(path, "rb"))
F
  _c 'Add encoder weights and loader'
  quiet 'git push' )
_lab_clock=$((_lab_clock + 300)); tick
rm -rf seed
quiet 'git clone remotes/evalboard.git newclone'
quiet 'git -C newclone remote set-url origin ../remotes/evalboard.git'
cd "$LAB_DIR" || exit 1

unset -f with_submodule
ex_end
