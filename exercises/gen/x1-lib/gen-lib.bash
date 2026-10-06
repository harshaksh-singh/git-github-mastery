# exercises/gen/x1-lib/gen-lib.bash — helpers shared by the exercise generators of Modules 1 to 10.
# Sourced by exercises/gen/<name>/generate.sh after labs/lib/lab-env.sh. Never run directly.
#
# A generator runs in two ways: on its own (after sandbox_begin) and inside a replay script under
# labs/ex1/ (after lab_begin, with LAB_REPLAY=1). ex_begin puts the lab clock on its first tick in
# both cases, which is why the commit IDs in your sandbox equal the IDs printed in the solutions.

# ex_begin <name>: reset clock and identity, and create the marker directory that check.sh reads.
ex_begin() {
  _lab_clock=$LAB_EPOCH_BASE; as you; tick
  cd "$LAB_DIR" || return 1
  mkdir -p "$LAB_DIR/.exercise"
  printf '%s\n' "$1" > "$LAB_DIR/.exercise/name"
}

# ex_end: back to the sandbox root, as yourself.
ex_end() { as you; cd "$LAB_DIR" || return 1; }

# _c '<message>': commit everything in the working tree with one tick of the lab clock.
_c() { quiet "git add -A && git commit -m \"$1\""; }

# _e '<message>': an empty commit, for histories where only the shape of the graph matters.
_e() { quiet "git commit --allow-empty -m \"$1\""; }

# ex_note <key> <value>: record a value that check.sh compares against later (for example the ID
# of a commit that must survive unchanged). Stored outside every repository of the sandbox.
ex_note() { printf '%s\n' "$2" > "$LAB_DIR/.exercise/$1"; }

# ex_server [<name>]: create the bare repository that plays the server.
ex_server() { quiet "git init --bare ${1:-server.git}"; }

# ex_clone <directory> [<source>]: clone the server for a person. A directory that starts with
# asha or ravi gets that person's identity in its own configuration, so the identity is still
# correct when you work in the sandbox through labs/shell. The remote URL is stored as a relative
# path, so the solutions and your sandbox print the same text.
ex_clone() {
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
