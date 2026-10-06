# labs/ex2/gen-lib.bash — helpers shared by the exercise generators of Modules 11 to 18
# (exercises/gen/m11-* to exercises/gen/m18-*). Sourced after labs/lib/lab-env.sh. Never run.
#
# A generator runs in two ways: on its own (it then creates the sandbox
# $GIT_MASTERY_LABS/exercises/<name>) and inside a replay script under labs/ex2/ (the replay has
# already created a sandbox with lab_begin and sets LAB_REPLAY=1). Both paths start from the same
# minute of the lab clock and run the same commands, so the commit IDs in your sandbox equal the
# IDs printed in the solutions.

# ex_begin <name>: create the sandbox (standalone only) and put the lab clock on its first tick.
ex_begin() {
  EX_NAME="$1"
  [ -n "${LAB_REPLAY:-}" ] || sandbox_begin exercises "$1"
  _lab_clock=$LAB_EPOCH_BASE
  as you
  tick
  cd "$LAB_DIR" || return 1
}

# ex_end [<directory to open>]: return to the sandbox root as yourself and say where to work.
ex_end() {
  as you
  cd "$LAB_DIR" || return 1
  [ -n "${LAB_REPLAY:-}" ] || printf 'Sandbox ready. Open a lab shell there:\n  labs/shell "%s"\n' "$LAB_DIR${1:+/$1}"
}

# put <path>: write standard input to the file, creating its directory.
put() { mkdir -p "$(dirname "$1")" && cat > "$1"; }

# _c '<subject>': commit everything in the working tree with one tick of the lab clock.
_c() { quiet "git add -A && git commit -m \"$1\""; }

# skip_ticks <n>: let n minutes pass (used to put commits on different hours or days).
skip_ticks() { _lab_clock=$((_lab_clock + 60 * ($1 - 1))); tick; }

# ex_server [<name>]: create the bare repository that plays the server.
ex_server() { quiet "git init --bare ${1:-server.git}"; }

# ex_clone <directory> [<source>]: clone the server for a person; the directory name starts with
# the person (you, asha, ravi). The identity goes into the clone's own configuration so that it
# is still right when you work in the sandbox through labs/shell. The remote URL is stored as a
# relative path, so transcripts and your sandbox print the same text.
ex_clone() {
  local src="${2:-server.git}" n e
  quiet "git clone $src $1"
  quiet "git -C $1 remote set-url origin ../$src"
  ex_identity "$1"
}

# ex_identity <directory>: write user.name and user.email of the directory's owner into its config.
ex_identity() {
  local n e
  case "$1" in
    asha*) n="Asha Rao";   e="asha@example.com" ;;
    ravi*) n="Ravi Menon"; e="ravi@example.com" ;;
    *)     n="Lab User";   e="you@example.com" ;;
  esac
  quiet "git -C $1 config set user.name '$n' && git -C $1 config set user.email $e"
}

# bin_file <path> <seed> <bytes>: a deterministic, incompressible stand-in for a binary file
# (a SHA-256 hash chain started from the seed), the same on every machine.
bin_file() {
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
