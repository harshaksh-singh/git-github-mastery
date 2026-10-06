# incidents/lib/incident-lib.bash — helpers shared by the incident generators.
# Sourced by incidents/NN-slug/generate.sh after labs/lib/lab-env.sh. Never run directly.
#
# Every incident sandbox has the same layout:
#   server.git   a bare repository that plays the server (the role GitHub has in real life)
#   you/         your clone
#   asha/ ravi/  clones of two teammates, each with its own user.name and user.email
# The remote URL is stored as a relative path, so the transcripts in the book and the output in
# your sandbox print the same text.

# inc_begin: put the lab clock on its first tick. A generator runs in two ways: on its own
# (after sandbox_begin) and inside a replay script (after lab_begin). This line makes both start
# from the same minute, which is why the commit IDs in your sandbox equal the IDs in the book.
inc_begin() { _lab_clock=$LAB_EPOCH_BASE; as you; tick; cd "$LAB_DIR" || return 1; }

# _c '<message>': commit everything in the working tree with one tick of the lab clock.
_c() { quiet "git add -A && git commit -m \"$1\""; }

# inc_server [<name>]: create the bare repository that plays the server.
inc_server() { quiet "git init --bare ${1:-server.git}"; }

# inc_clone <directory> [<source>]: clone the server for a person. The directory name is the
# person: you, asha or ravi. The identity is written into the clone's own configuration, so it
# is still correct when you work in the sandbox through labs/shell.
inc_clone() {
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

# inc_end: return to the sandbox root as yourself.
inc_end() { as you; cd "$LAB_DIR" || return 1; }
