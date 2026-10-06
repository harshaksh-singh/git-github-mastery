# labs/ex3/fixture.bash - shared fixture for the exercise scripts of Modules 19 to 34.
#
# Sourced by the scripts in this directory right after lab-env.sh. It is not a demo:
# the file name does not end in .sh, so the build and verify tools skip it.
#
# The project is "chunker", a small library that splits documents into chunks for a
# retrieval pipeline. The topology most scripts build (all on disk inside the sandbox,
# no network):
#
#   $LAB_DIR/server/chunker.git     a bare repository that plays the shared repository
#   $LAB_DIR/you/chunker            your clone
#   $LAB_DIR/asha/chunker           the clone of Asha, who maintains the repository
#   $LAB_DIR/ravi/chunker           the clone of Ravi, a teammate
#
# Clones store the server URL as a relative path, so that no transcript depends on where
# the sandbox lives.
#
# Nothing here talks to GitHub. Where a script imitates something the platform does (a ref
# under refs/pull/, a merge button, a tag created together with a release), the exercise
# says which documented behavior is imitated; the commands are plain Git chosen by the author.
#
# Every secret in these scripts is a dummy such as DUMMY-KEY-not-a-real-secret-0042,
# spelled so that no scanner pattern matches it.

SERVER_URL=../../server/chunker.git
DUMMY_KEY='DUMMY-KEY-not-a-real-secret-0042'

# hidden '<command line>'
# A setup step that the transcript does not show. A failing hidden step stops the script:
# a setup that fails silently would make the transcript lie.
hidden() {
  tick
  eval "$1" > /dev/null 2>&1 || { printf 'fixture: hidden step failed: %s\n' "$1" >&2; exit 1; }
}

# put <path>
# Write standard input to the file, creating its directory.
put() {
  mkdir -p "$(dirname "$1")" && cat > "$1" || { printf 'fixture: put failed: %s\n' "$1" >&2; exit 1; }
}

# commit_all <message>
# Stage everything and commit, silently. Advances the clock by one minute.
commit_all() {
  tick
  { git add -A && git commit -q -m "$1"; } > /dev/null 2>&1 ||
    { printf 'fixture: commit_all failed: %s\n' "$1" >&2; exit 1; }
}

# require_ref <repository> <ref>
require_ref() {
  git -C "$1" rev-parse --verify --quiet "$2" > /dev/null ||
    { printf 'fixture: expected ref %s in %s\n' "$2" "$1" >&2; exit 1; }
}

# setup_done <exercise> <sandbox name> <first command>
setup_done() {
  printf 'Exercise %s is ready in %s\n' "$1" "$LAB_DIR"
  printf 'Open the lab shell there:  labs/shell %s\n' "$2"
  [ -z "${3:-}" ] || printf 'First command:             %s\n' "$3"
}

# ---------------------------------------------------------------- file versions
split_v1() {
  put chunker/split.py <<'PY'
def split(text, size=200):
    """Split text into chunks of at most `size` characters."""
    return [text[i:i + size] for i in range(0, len(text), size)]
PY
}

split_v2() {     # adds overlap
  put chunker/split.py <<'PY'
def split(text, size=200, overlap=0):
    """Split text into chunks of at most `size` characters, repeating `overlap` characters."""
    step = size - overlap
    return [text[i:i + size] for i in range(0, len(text), step)]
PY
}

split_v3() {     # rejects an overlap that would loop forever
  put chunker/split.py <<'PY'
def split(text, size=200, overlap=0):
    """Split text into chunks of at most `size` characters, repeating `overlap` characters."""
    if overlap >= size:
        raise ValueError("overlap must be smaller than size")
    step = size - overlap
    return [text[i:i + size] for i in range(0, len(text), step)]
PY
}

config_v1() { printf 'chunk_size: 200\noverlap: 0\nseparator: paragraph\n' | put config/chunking.yaml; }
config_v2() { printf 'chunk_size: 400\noverlap: 0\nseparator: paragraph\n' | put config/chunking.yaml; }

test_v1() {
  put tests/test_split.py <<'PY'
from chunker.split import split


def test_short_text_is_one_chunk():
    assert split("hello", size=10) == ["hello"]
PY
}

test_v2() {
  put tests/test_split.py <<'PY'
from chunker.split import split


def test_short_text_is_one_chunk():
    assert split("hello", size=10) == ["hello"]


def test_overlap_repeats_characters():
    assert split("abcdef", size=4, overlap=2) == ["abcd", "cdef", "ef"]
PY
}

# ---------------------------------------------------------------- repositories
# make_server
# Create the bare shared repository with four commits on main, written by Asha.
# Ends in $LAB_DIR with your identity active.
make_server() {
  as asha
  hidden "git init --bare '$LAB_DIR/server/chunker.git'"
  hidden "git clone '$LAB_DIR/server/chunker.git' '$LAB_DIR/.seed'"
  cd "$LAB_DIR/.seed" || exit 1
  printf '# chunker\n\nSplits documents into chunks for a retrieval pipeline.\n' | put README.md
  commit_all 'Add README'
  split_v1
  commit_all 'Add fixed-size splitter'
  config_v1
  commit_all 'Add chunking config'
  test_v1
  commit_all 'Add splitter test'
  hidden 'git push origin main'
  cd "$LAB_DIR" || exit 1
  rm -rf "$LAB_DIR/.seed"
  as you
}

# new_clone <person>
new_clone() {
  local dir="$LAB_DIR/$1/chunker"
  hidden "git clone '$LAB_DIR/server/chunker.git' '$dir'"
  git -C "$dir" remote set-url origin "$SERVER_URL" || exit 1
  case "$1" in
    asha) git -C "$dir" config set user.name 'Asha Rao';   git -C "$dir" config set user.email asha@example.com ;;
    ravi) git -C "$dir" config set user.name 'Ravi Menon'; git -C "$dir" config set user.email ravi@example.com ;;
  esac
}

# enter <person>
enter() {
  as "$1"
  cd "$LAB_DIR/$1/chunker" || exit 1
}

# server_git <git arguments...>: run Git inside the bare server repository.
server_git() { git -C "$LAB_DIR/server/chunker.git" "$@"; }

# server_open_pr <number> <head branch>
# Imitates the Git part of "open a pull request": refs/pull/<number>/head on the server.
server_open_pr() {
  server_git update-ref "refs/pull/$1/head" "refs/heads/$2" ||
    { printf 'fixture: server_open_pr failed\n' >&2; exit 1; }
}

# server_squash_merge <branch> <message>
# Imitates "Squash and merge" with plain Git in Asha's clone: one new commit on main that
# has the content of the merge and one parent. Leaves the head branch on the server alone.
server_squash_merge() {
  enter asha
  hidden 'git fetch'
  hidden 'git switch main'
  hidden 'git merge --ff-only origin/main'
  hidden "git merge --squash 'origin/$1'"
  tick
  git commit -q -m "$2" > /dev/null 2>&1 || { printf 'fixture: squash commit failed\n' >&2; exit 1; }
  hidden 'git push origin main'
}

# ---------------------------------------------------------------- sandbox home (Module 20, 24)
# sandbox_home
# Make the sandbox's home directory the HOME of this script and put ~/lab-bin on PATH.
# ssh does not use $HOME to find its files, so every ssh command names its files with -F.
sandbox_home() {
  export HOME="$LAB_DIR/home"
  mkdir -p "$HOME/lab-bin" "$HOME/.ssh" || exit 1
  chmod 700 "$HOME/.ssh"
  export PATH="$HOME/lab-bin:$PATH"
  unset SSH_AUTH_SOCK SSH_AGENT_PID SSH_ASKPASS
  export GIT_ALLOW_PROTOCOL=file:ssh     # Git cannot open an HTTPS connection from these scripts
  cd "$HOME" || exit 1
}

# make_helper <name> <username>
# A toy credential helper, ~/lab-bin/git-credential-<name>, that always answers with the
# given username and a dummy password. It exists to make the helper order visible.
make_helper() {
  cat > "$HOME/lab-bin/git-credential-$1" <<HELPER
#!/bin/sh
# git-credential-$1: a toy credential helper for the exercises. Not for real secrets.
cat > /dev/null
[ "\$1" = get ] && printf 'username=%s\npassword=FAKE-TOKEN-not-a-real-credential\n' '$2'
exit 0
HELPER
  chmod +x "$HOME/lab-bin/git-credential-$1"
}

# make_repo <directory> <remote url>
# A one-commit repository with an origin. Ends inside it.
make_repo() {
  hidden "git init '$1'"
  cd "$1" || exit 1
  printf '# %s\n' "$(basename "$1")" | put README.md
  commit_all 'Add README'
  hidden "git remote add origin '$2'"
}

# make_key_files <name>...
# Throwaway Ed25519 key pairs in ~/.ssh. Only their file names ever appear in a transcript.
make_key_files() {
  local k
  for k in "$@"; do
    ssh-keygen -q -t ed25519 -N '' -C "exercise key $k" -f "$HOME/.ssh/$k" < /dev/null > /dev/null 2>&1 ||
      { printf 'fixture: ssh-keygen failed\n' >&2; exit 1; }
  done
}

# make_signing_key <name> <comment>; allow_signer <principal> <key name>
# Signing keys for the Module 24 exercise, in ~/keys. Scripts that call this are --volatile.
make_signing_key() {
  mkdir -p "$HOME/keys" || exit 1
  ssh-keygen -q -t ed25519 -N '' -C "$2" -f "$HOME/keys/$1" < /dev/null > /dev/null 2>&1 ||
    { printf 'fixture: ssh-keygen failed\n' >&2; exit 1; }
}
allow_signer() {
  printf '%s namespaces="git" %s\n' "$1" "$(cut -d' ' -f1,2 "$HOME/keys/$2.pub")" >> "$HOME/allowed_signers"
}

# ---------------------------------------------------------------- exercise starting states
# Each scenario_* function builds the starting state of one exercise. The replay script and,
# where the exercise is hands-on, the setup script call the same function.

# Exercise 20.6: a home directory with three planted faults in the Git and ssh configuration.
# Nothing connects anywhere: the exercise is solved with git config, git remote and "ssh -G".
scenario_x20_faults() {
  local keep="$HOME"
  export HOME="$LAB_DIR/home"; mkdir -p "$HOME/.ssh" || exit 1
  chmod 700 "$HOME/.ssh"
  make_key_files id_ed25519_personal id_ed25519_northwind
  put "$HOME/.ssh/config" <<'CFG'
# Added by the CI bootstrap script
Host github*
  User deploy
  IdentityFile ~/.ssh/id_rsa_ci

# Work account: URLs written with the alias, git@github-work:ORG/REPO.git
Host github-work
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_work
  IdentitiesOnly yes

# Personal account: plain github.com URLs
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_personal
  IdentitiesOnly yes
CFG
  chmod 600 "$HOME/.ssh/config"
  put "$HOME/.gitconfig" <<'CFG'
[user]
	name = Lab User
	email = lab-user@personal.example
[init]
	defaultBranch = main
[gc]
	reflogExpire = never
	reflogExpireUnreachable = never
[includeIf "gitdir:~/work"]
	path = ~/.gitconfig-work
CFG
  put "$HOME/.gitconfig-work" <<'CFG'
[user]
	email = lab.user@northwind.example
[url "git@github-work:"]
	insteadOf = git@github.com:
CFG
  as config
  GIT_CONFIG_GLOBAL="$HOME/.gitconfig" make_repo "$HOME/work/chunker" git@github.com:northwind-ml/chunker.git
  export HOME="$keep"
  as you
  cd "$LAB_DIR" || exit 1
}

# Exercise 21.6: your branch fix/unicode-split was cut from Ravi's unmerged branch, which Ravi
# has since rewritten and force-pushed. "Pull request 23" (your branch into main) exists on
# the server as refs/pull/23/head. Ends in your clone, on your branch, nothing fetched since.
scenario_x21_foreign() {
  make_server
  new_clone you
  new_clone asha
  new_clone ravi
  enter ravi
  hidden 'git switch -c feature/semantic-split'
  printf 'import re\n\nBOUNDARY = re.compile(r"(?<=[.!?])\\s+")\n\n\ndef sentences(text):\n    return BOUNDARY.split(text)\n' | put chunker/sentences.py
  commit_all 'Add sentence boundary detection'
  printf 'from chunker.sentences import sentences\n\n\ndef split_semantic(text, size=200):\n    chunks, current = [], ""\n    for s in sentences(text):\n        if current and len(current) + len(s) > size:\n            chunks.append(current)\n            current = ""\n        current = (current + " " + s).strip()\n    return chunks + [current] if current else chunks\n' | put chunker/semantic.py
  commit_all 'Split on sentence boundaries'
  printf 'chunk_size: 200\noverlap: 0\nseparator: sentence\nmin_sentence_chars: 12\n' | put config/chunking.yaml
  commit_all 'WIP tune thresholds'
  hidden 'git push -u origin feature/semantic-split'
  # You: the mistake. The new branch starts from Ravi's branch, not from main.
  enter you
  hidden 'git fetch'
  hidden 'git switch -c fix/unicode-split --no-track origin/feature/semantic-split'
  put chunker/split.py <<'PY'
def split(text, size=200):
    """Split text into chunks of at most `size` characters (code points, not bytes)."""
    chars = list(text)
    return ["".join(chars[i:i + size]) for i in range(0, len(chars), size)]
PY
  commit_all 'Count characters, not bytes, when splitting'
  put tests/test_unicode.py <<'PY'
from chunker.split import split


def test_multibyte_characters_are_not_cut():
    assert split("naïve café", size=5) == ["naïve", " café"]
PY
  commit_all 'Test splitting text with multi-byte characters'
  hidden 'git push -u origin fix/unicode-split'
  # main moves on, then Ravi tidies his branch and force-pushes it.
  enter asha
  printf '# chunker\n\nSplits documents into chunks for a retrieval pipeline.\n\n## Development\n\nRun the tests with: python3 -m unittest discover -s tests\n' | put README.md
  commit_all 'Document how to run the tests'
  hidden 'git push origin main'
  enter ravi
  hidden 'git fetch'
  hidden 'git reset --soft HEAD~1'
  tick
  git commit -q --amend -m 'Split on sentence boundaries' > /dev/null 2>&1 || exit 1
  hidden 'git rebase origin/main'
  hidden 'git push --force-with-lease'
  server_open_pr 23 fix/unicode-split
  enter you
}

# Exercise 22.5: a release was created on the platform before the tag existed, and before the
# fix it advertises was merged. Ends in your clone, on main, with nothing fetched since v0.8.0.
scenario_x22_release() {
  make_server
  new_clone you
  new_clone asha
  enter asha
  tick
  git tag -a v0.8.0 -m 'chunker 0.8.0' > /dev/null 2>&1 || exit 1
  hidden 'git push origin v0.8.0'
  enter you
  hidden 'git fetch --tags'
  enter asha
  split_v2
  commit_all 'Add overlap parameter'
  hidden 'git push origin main'
  # The release "v0.9.0" is created in the web interface now. No such tag exists, so the
  # platform creates one at the tip of the default branch. Imitated with a plain lightweight tag.
  server_git tag v0.9.0 refs/heads/main || exit 1
  split_v3
  commit_all 'Reject an overlap that is not smaller than the size'
  config_v2
  commit_all 'Double the default chunk size'
  hidden 'git push origin main'
  enter you
}

# Exercise 28.5: works on your machine, fails in a fresh clone, for two reasons that Git can
# show. scripts/smoke.sh stands in for the CI command. Ends in your clone, on main, pushed.
scenario_x28_fresh_clone() {
  make_server
  new_clone you
  enter you
  printf 'build/\nfixtures/\n__pycache__/\n' | put .gitignore
  put scripts/smoke.sh <<'SH'
#!/bin/sh
# The CI command: split the sample document and report how many lines it has.
set -e
lines=$(grep -c '' tests/fixtures/sample.txt)
echo "smoke ok: sample has $lines lines"
SH
  printf 'First paragraph.\n\nSecond paragraph.\n' | put tests/fixtures/sample.txt
  chmod +x scripts/smoke.sh
  hidden 'git config set core.fileMode false'
  hidden 'git add .gitignore scripts/smoke.sh'
  hidden 'git update-index --chmod=-x scripts/smoke.sh'
  tick
  git commit -q -m 'Add smoke test for CI' > /dev/null 2>&1 || exit 1
  hidden 'git push origin main'
}

# Exercise 31.5: a dummy key leaked in several places of one repository. Ends in your clone.
scenario_x31_exposure() {
  make_server
  new_clone you
  new_clone ravi
  enter ravi
  printf 'STORAGE_KEY=%s\nREGION=ap-south-1\n' "$DUMMY_KEY" | put config/settings.env
  split_v2
  commit_all 'Add overlap parameter'
  hidden 'git push origin main'
  tick; git tag -a v0.5.0 -m 'chunker 0.5.0' > /dev/null 2>&1 || exit 1
  hidden 'git push origin v0.5.0'
  hidden 'git switch -c debug/storage'
  printf 'retry: 3\n' | put config/storage.yaml
  tick
  { git add -A && git commit -q -m 'Debug storage timeouts' -m "Reproduce with STORAGE_KEY=$DUMMY_KEY"; } > /dev/null 2>&1 || exit 1
  hidden 'git push -u origin debug/storage'
  hidden 'git switch main'
  split_v3
  commit_all 'Reject an overlap that is not smaller than the size'
  hidden 'git rm -q --cached config/settings.env'
  printf '*.env\n' | put .gitignore
  commit_all 'Stop tracking the settings file'
  hidden 'git push origin main'
  enter you
  hidden 'git pull --ff-only'
  hidden 'git fetch --tags'
}

# Exercise 32.5: main and release/2.3. The team's rule is "fix on main first, cherry-pick down".
# Four commits sit on the release branch after v2.3.0: a version bump, a fix that was picked
# from main with -x, a fix that was ported from main by hand because the pick conflicted, and
# a fix that was made on the release branch and never taken to main. Ends in your clone on main.
scenario_x32_missing_fix() {
  make_server
  new_clone you
  enter you
  tick; git tag -a v2.3.0 -m 'chunker 2.3.0' > /dev/null 2>&1 || exit 1
  hidden 'git branch release/2.3'
  # main moves on: a feature that rewrites the splitter.
  split_v2
  commit_all 'feat: add overlap parameter'
  # Fix 1, on main first: empty text.
  printf 'chunk_size: 200\noverlap: 0\nseparator: paragraph\nstrip_whitespace: true\n' | put config/chunking.yaml
  commit_all 'fix: strip whitespace before splitting'
  FIX1=$(git rev-parse HEAD)
  # Fix 2, on main first: touches the splitter, which differs between the two lines.
  put chunker/split.py <<'PY'
def split(text, size=200, overlap=0):
    """Split text into chunks of at most `size` characters, repeating `overlap` characters."""
    if size <= 0:
        raise ValueError("size must be positive")
    step = size - overlap
    return [text[i:i + size] for i in range(0, len(text), step)]
PY
  commit_all 'fix: reject a chunk size that is not positive'
  FIX2=$(git rev-parse HEAD)
  hidden 'git switch release/2.3'
  printf '2.3.1\n' | put VERSION
  commit_all 'chore: bump version to 2.3.1'
  hidden "git cherry-pick -x $FIX1"
  # The port of fix 2 conflicts (the release line has no overlap parameter): resolved by hand.
  git cherry-pick -x "$FIX2" > /dev/null 2>&1
  put chunker/split.py <<'PY'
def split(text, size=200):
    """Split text into chunks of at most `size` characters."""
    if size <= 0:
        raise ValueError("size must be positive")
    return [text[i:i + size] for i in range(0, len(text), size)]
PY
  tick
  { git add chunker/split.py && git -c core.editor=true cherry-pick --continue; } > /dev/null 2>&1 || exit 1
  # Fix 3: made on the release branch during an incident, never taken to main.
  put tests/test_split.py <<'PY'
from chunker.split import split


def test_short_text_is_one_chunk():
    assert split("hello", size=10) == ["hello"]


def test_empty_text_gives_no_chunks():
    assert split("", size=10) == []
PY
  printf 'chunk_size: 200\noverlap: 0\nseparator: paragraph\nstrip_whitespace: true\nmax_chunks: 10000\n' | put config/chunking.yaml
  commit_all 'fix: cap the number of chunks per document'
  tick; git tag -a v2.3.1 -m 'chunker 2.3.1' > /dev/null 2>&1 || exit 1
  hidden 'git switch main'
  printf '# chunker\n\nSplits documents into chunks for a retrieval pipeline.\n\nSee docs/ for the 2.4 plan.\n' | put README.md
  commit_all 'docs: point to the 2.4 plan'
  hidden 'git push origin main release/2.3 v2.3.0 v2.3.1'
}
