# assessments/gen/lib/gate-lib.bash — helpers shared by the generators of the mastery gates.
# Sourced by assessments/gen/gate-N-<name>/variant-<x>/generate.sh after labs/lib/lab-env.sh.
# Never run directly.
#
# A generator runs in two ways: on its own (after sandbox_begin) and inside a replay script under
# labs/gates/ (after lab_begin, with LAB_REPLAY=1). gate_begin puts the lab clock on its first
# tick in both cases, which is why the commit IDs in your sandbox equal the IDs in the answer key.

# gate_begin <sandbox name>: reset clock and identity; create the marker that check.sh reads.
gate_begin() {
  _lab_clock=$LAB_EPOCH_BASE; as you; tick
  cd "$LAB_DIR" || return 1
  mkdir -p "$LAB_DIR/.gate"
  printf '%s\n' "$1" > "$LAB_DIR/.gate/name"
}

# gate_end: back to the sandbox root, as yourself.
gate_end() { as you; cd "$LAB_DIR" || return 1; }

# gate_ready: the closing message of a standalone run.
gate_ready() {
  [ -n "${LAB_REPLAY:-}" ] || printf 'Gate sandbox ready. Open a lab shell there:\n  labs/shell "%s"\n' "$LAB_DIR"
}

# _c '<message>': commit everything in the working tree with one tick of the lab clock.
_c() { quiet "git add -A && git commit -m \"$1\""; }

# _e '<message>': an empty commit, for histories where only the shape of the graph matters.
_e() { quiet "git commit --allow-empty -m \"$1\""; }

# gate_note <key> <value>: record a value that check.sh compares against later (for example the
# ID of a commit that must survive unchanged). Stored outside every repository of the sandbox.
gate_note() { printf '%s\n' "$2" > "$LAB_DIR/.gate/$1"; }

# gate_server [<name>]: create the bare repository that plays the server.
gate_server() { quiet "git init --bare ${1:-server.git}"; }

# gate_clone <directory> [<source>]: clone the server for a person. A directory that starts with
# asha or ravi gets that person's identity in its own configuration, so the identity is still
# correct when you work in the sandbox through labs/shell. The remote URL is stored as a relative
# path, so the answer key and your sandbox print the same text.
gate_clone() {
  local src="${2:-server.git}" n e
  quiet "git clone $src $1"
  quiet "git -C $1 remote set-url origin ../$src"
  case "$1" in
    asha*) n="Asha Rao";   e="asha@example.com" ;;
    ravi*) n="Ravi Menon"; e="ravi@example.com" ;;
    *)     n="Lab User";   e="you@example.com" ;;
  esac
  quiet "git -C $1 config set user.name '$n' && git -C $1 config set user.email $e"
}
