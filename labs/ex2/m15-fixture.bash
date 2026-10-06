# labs/ex2/m15-fixture.bash — the library and the service used by the Module 15 exercises.
# Sourced by exercises/gen/m15-*/generate.sh after gen-lib.bash. Never run.
#
#   remotes/metrickit.git   a small metrics library (two releases: v0.1.0 and v0.2.0)
#   remotes/evalboard.git   the service that uses it
# Local path remotes use Git's "file" transport, which the submodule machinery refuses unless
# protocol.file.allow says otherwise (Chapter 23, section 23.4). FILE_OK carries that option.
FILE_OK='-c protocol.file.allow=always'

# m15_lib: create remotes/metrickit.git with v0.1.0 and v0.2.0. Leaves you where you were.
m15_lib() {
  mkdir -p remotes
  quiet 'git init --bare remotes/metrickit.git'
  quiet 'git clone remotes/metrickit.git lib-src'
  (
    cd lib-src || exit 1
    as asha
    put metrickit.py <<'F'
"""metrickit: text overlap metrics."""


def exact_match(answer, reference):
    return float(answer.strip() == reference.strip())
F
    _c 'Add exact match'
    quiet "git tag -a v0.1.0 -m 'metrickit 0.1.0'"
    put metrickit.py <<'F'
"""metrickit: text overlap metrics."""


def exact_match(answer, reference):
    return float(answer.strip() == reference.strip())


def rouge_l(answer, reference):
    a, b = answer.split(), reference.split()
    table = [[0] * (len(b) + 1) for _ in range(len(a) + 1)]
    for i, x in enumerate(a):
        for j, y in enumerate(b):
            table[i + 1][j + 1] = table[i][j] + 1 if x == y else max(table[i][j + 1], table[i + 1][j])
    return table[-1][-1] / max(len(b), 1)
F
    _c 'Add ROUGE-L'
    quiet "git tag -a v0.2.0 -m 'metrickit 0.2.0'"
    quiet 'git push origin main v0.1.0 v0.2.0'
  )
  _lab_clock=$((_lab_clock + 300)); tick       # the subshell's ticks are lost; move past them
  rm -rf lib-src
  as you
}

# m15_app <clone directory>: create remotes/evalboard.git and a clone of it with two commits,
# pushed. Leaves you where you were.
m15_app() {
  mkdir -p remotes
  quiet 'git init --bare remotes/evalboard.git'
  quiet "git clone remotes/evalboard.git $1"
  quiet "git -C $1 remote set-url origin ../remotes/evalboard.git"
  ex_identity "$1"
  (
    cd "$1" || exit 1
    put board.py <<'F'
"""evalboard: a table of evaluation runs."""


def row(run):
    return "%-12s %s" % (run["name"], run["date"])
F
    _c 'Add evaluation dashboard'
    printf '# evalboard\n\nShows evaluation runs and their scores.\n' > README.md
    _c 'Add README'
    quiet 'git push -u origin main'
  )
  _lab_clock=$((_lab_clock + 180)); tick
}

# m15_weights <path> <seed> <bytes>: a deterministic stand-in for a binary model file.
m15_weights() {
  python3 -c '
import hashlib, pathlib, sys
path, seed, size = sys.argv[1], sys.argv[2], int(sys.argv[3])
out, block = bytearray(), hashlib.sha256(seed.encode()).digest()
while len(out) < size:
    out += block
    block = hashlib.sha256(block).digest()
p = pathlib.Path(path); p.parent.mkdir(parents=True, exist_ok=True); p.write_bytes(bytes(out[:size]))
' "$1" "$2" "$3"
}
