# assessments/gen/final-lib/final-lib.bash — helpers shared by the generators of the final test's
# practical labs. Sourced by assessments/gen/final-<name>/generate.sh after labs/lib/lab-env.sh.
# Never run directly.
#
# A generator runs in two ways: on its own (after sandbox_begin) and inside a replay script under
# labs/final/ (after lab_begin, with LAB_REPLAY=1). final_begin puts the lab clock on its first
# tick in both cases, which is why the commit IDs in your sandbox equal the IDs in the answer key.

# final_begin <sandbox name>: reset clock and identity; create the marker that check.sh reads.
final_begin() {
  _lab_clock=$LAB_EPOCH_BASE; as you; tick
  cd "$LAB_DIR" || return 1
  mkdir -p "$LAB_DIR/.final"
  printf '%s\n' "$1" > "$LAB_DIR/.final/name"
}

# final_end: back to the sandbox root, as yourself.
final_end() { as you; cd "$LAB_DIR" || return 1; }

# final_ready: the closing message of a standalone run.
final_ready() {
  [ -n "${LAB_REPLAY:-}" ] || printf 'Lab sandbox ready. Open a lab shell there:\n  labs/shell "%s"\n' "$LAB_DIR"
}

# _c '<message>': commit everything in the working tree with one tick of the lab clock.
_c() { quiet "git add -A && git commit -m \"$1\""; }

# _e '<message>': an empty commit, for histories where only the shape of the graph matters.
_e() { quiet "git commit --allow-empty -m \"$1\""; }

# final_note <key> <value>: record a value that check.sh compares against later (for example the
# ID of a commit that must survive unchanged). Stored outside every repository of the sandbox.
final_note() { printf '%s\n' "$2" > "$LAB_DIR/.final/$1"; }

# final_server [<name>]: create a bare repository that plays a server.
final_server() { quiet "git init --bare ${1:-server.git}"; }

# final_clone <directory> [<source>]: clone a server for a person. A directory that starts with
# asha or ravi gets that person's identity in its own configuration, so the identity is still
# correct when you work in the sandbox through labs/shell. The remote URL is stored as a relative
# path, so the answer key and your sandbox print the same text.
final_clone() {
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
