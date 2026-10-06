# labs/ch12/fixture.bash - shared fixture for the Chapter 12 demos and the Module 7 labs.
#
# Sourced by the scripts in this directory right after lab-env.sh. It is not a demo:
# the file name does not end in .sh, so the build and verify tools skip it.
#
# The topology every script builds (all on disk inside the sandbox, no network):
#
#   $LAB_DIR/server/support-bot.git     a bare repository that plays the server
#   $LAB_DIR/you/support-bot            your clone
#   $LAB_DIR/asha/support-bot           Asha's clone
#   $LAB_DIR/ravi/support-bot           Ravi's clone
#
# Every clone stores the server URL as the relative path ../../server/support-bot.git.
# "git clone <local path>" records an absolute path; the fixture rewrites it because
# "git pull" writes the URL into the message of the merge commit it creates, and a commit
# ID is a hash that covers the message. With an absolute path the IDs in the book would
# depend on where the sandbox lives; with the relative path they are the same everywhere.

SERVER_URL=../../server/support-bot.git

# hidden '<command line>'
# A setup step that the transcript does not show. Unlike "quiet" from lab-env.sh, a failing
# hidden step stops the script: a setup that fails silently would make the transcript lie.
hidden() {
  tick
  eval "$1" > /dev/null 2>&1 || { printf 'fixture: hidden step failed: %s\n' "$1" >&2; exit 1; }
}

# commit_file <path> <printf format> <message>
# Write one file and commit it in the current repository, silently. Advances the clock.
commit_file() {
  tick
  {
    mkdir -p "$(dirname "$1")" &&
      printf "$2" > "$1" &&
      git add "$1" &&
      git commit -q -m "$3"
  } > /dev/null 2>&1 || { printf 'fixture: commit_file failed: %s\n' "$1" >&2; exit 1; }
}

# make_server
# Create the bare server repository and give it three commits on main, written by Ravi.
# Ends in $LAB_DIR with your identity active.
make_server() {
  as ravi
  hidden "git init --bare '$LAB_DIR/server/support-bot.git'"
  hidden "git clone '$LAB_DIR/server/support-bot.git' '$LAB_DIR/.seed'"
  cd "$LAB_DIR/.seed" || exit 1
  commit_file README.md '# support-bot\n\nRetrieval-augmented answers for the help desk.\n' 'Add README'
  commit_file app/retriever.py 'def retrieve(query, top_k):\n    return []\n' 'Add retriever skeleton'
  commit_file config.yaml 'model: small-v1\ntop_k: 5\n' 'Add retrieval config'
  hidden 'git push origin main'
  cd "$LAB_DIR" || exit 1
  rm -rf "$LAB_DIR/.seed"
  as you
}

# new_clone <person>
# Clone the server into $LAB_DIR/<person>/support-bot and store the relative server URL.
# Teammates also get user.name and user.email in the clone's own configuration, so that
# commits you type by hand inside their clone (labs/shell) carry their name.
# Does not change the current directory or the active identity.
new_clone() {
  local dir="$LAB_DIR/$1/support-bot"
  hidden "git clone '$LAB_DIR/server/support-bot.git' '$dir'"
  git -C "$dir" remote set-url origin "$SERVER_URL" || exit 1
  case "$1" in
    asha) git -C "$dir" config set user.name 'Asha Rao';   git -C "$dir" config set user.email asha@example.com ;;
    ravi) git -C "$dir" config set user.name 'Ravi Menon'; git -C "$dir" config set user.email ravi@example.com ;;
  esac
}

# enter <person>
# Become that person and move into their clone, without printing anything.
# Scripts use it for hidden setup. In transcripts the visible form is:  as <person>; run 'cd ...'
enter() {
  as "$1"
  cd "$LAB_DIR/$1/support-bot" || exit 1
}

# require_ref <repository> <ref>
# Used by the hands-on setup scripts as a final sanity check: stop with an error if the
# fixture did not produce the expected starting state.
require_ref() {
  git -C "$1" rev-parse --verify --quiet "$2" > /dev/null ||
    { printf 'fixture: expected ref %s in %s\n' "$2" "$1" >&2; exit 1; }
}

# ---------------------------------------------------------------- lab starting states
# Each scenario_* function builds the starting state of one hands-on lab of Module 7.
# The lab's replay script (lab-07-k-*.sh) and its setup script (setup-07-k-*.sh) call the
# same function, so the commits that already exist when you start typing have the same
# IDs as in the book. Every function ends in $LAB_DIR with your identity active.

# Lab 7.2: Asha has pushed a commit nobody has fetched; you and Ravi each have one
# local commit that is not on the server.
scenario_07_2() {
  make_server
  new_clone you
  new_clone asha
  new_clone ravi
  enter asha
  commit_file config.yaml 'model: small-v1\ntop_k: 8\n' 'Raise top_k to 8'
  hidden 'git push'
  enter you
  commit_file requirements-dev.txt 'pytest\n' 'Add dev requirements'
  enter ravi
  commit_file eval/run_eval.py 'print("eval")\n' 'Add eval harness entry point'
  cd "$LAB_DIR" || exit 1
  as you
}

# Lab 7.3: main has diverged. Asha has pushed one commit and holds a second one locally;
# you have one local commit; you have not fetched.
scenario_07_3() {
  make_server
  new_clone you
  new_clone asha
  enter asha
  commit_file config.yaml 'model: small-v1\ntop_k: 8\n' 'Raise top_k to 8'
  hidden 'git push'
  commit_file docs/eval.md '# Evaluation\n\nRun eval/run_eval.py before every release.\n' 'Describe the evaluation run'
  enter you
  commit_file requirements-dev.txt 'pytest\n' 'Add dev requirements'
  cd "$LAB_DIR" || exit 1
  as you
}

# Lab 7.4: you published feature/prompt-cache with two commits, the second one with a
# typo in its message. Asha checked the branch out and committed a test on top, unpushed.
scenario_07_4() {
  make_server
  new_clone you
  enter you
  hidden 'git switch -c feature/prompt-cache'
  commit_file app/cache.py 'CACHE = {}\n' 'Add prompt cache'
  commit_file app/cache.py 'CACHE = {}\nTTL_SECONDS = 300\n' 'Add cahce TTL'
  hidden 'git push -u origin feature/prompt-cache'
  new_clone asha
  enter asha
  hidden 'git switch feature/prompt-cache'
  commit_file tests/test_cache.py 'def test_cache_starts_empty():\n    assert True\n' 'Add cache test'
  cd "$LAB_DIR" || exit 1
  as you
}

# Lab 7.5: the shared repository and Ravi, its maintainer, with his clone. You create
# your fork and your clone yourself during the lab.
scenario_07_5() {
  make_server
  new_clone ravi
  cd "$LAB_DIR" || exit 1
  as you
}

# Lab 7.6: your clone has local branches for three server branches and has seen a branch
# called "release". Then Asha merges one branch, abandons another, and the team replaces
# "release" by "release/1.0". You have not fetched since.
scenario_07_6() {
  make_server
  new_clone asha
  enter asha
  hidden 'git switch -c feature/reranker'
  commit_file app/reranker.py 'def rerank(docs):\n    return docs\n' 'Add reranker stub'
  hidden 'git push -u origin feature/reranker'
  hidden 'git switch -c feature/eval-harness main'
  commit_file eval/run_eval.py 'print("eval")\n' 'Add eval harness entry point'
  hidden 'git push -u origin feature/eval-harness'
  hidden 'git switch -c spike/hybrid-search main'
  commit_file app/hybrid.py 'def hybrid_search(query):\n    return []\n' 'Try hybrid search'
  hidden 'git push -u origin spike/hybrid-search'
  hidden 'git switch main'
  hidden 'git push origin main:refs/heads/release'
  new_clone you
  enter you
  hidden 'git switch feature/reranker'
  hidden 'git switch feature/eval-harness'
  hidden 'git switch spike/hybrid-search'
  hidden 'git switch main'
  enter asha
  hidden 'git merge --no-ff -m "Merge branch feature/reranker" feature/reranker'
  hidden 'git push'
  hidden 'git push origin --delete feature/reranker'
  hidden 'git push origin --delete spike/hybrid-search'
  hidden 'git push origin --delete release'
  hidden 'git push origin main:refs/heads/release/1.0'
  cd "$LAB_DIR" || exit 1
  as you
}

# Lab 7.7: a server with main, release/0.1, a bot branch and one ref outside refs/heads
# that imitates a hosting platform's ref for pull request 7. Your clone was made with
# --single-branch, as a CI job would make it. Asha has a clone with release/0.1 checked out.
scenario_07_7() {
  make_server
  new_clone asha
  enter asha
  hidden 'git push origin main:refs/heads/release/0.1'
  hidden 'git push origin main:refs/heads/dependabot/pip/requests-2.33'
  hidden 'git switch -c feature/reranker'
  commit_file app/reranker.py 'def rerank(docs):\n    return docs\n' 'Add reranker stub'
  hidden 'git push origin HEAD:refs/pull/7/head'
  hidden 'git fetch'
  hidden 'git switch release/0.1'
  commit_file VERSION '0.1.0\n' 'Add VERSION file'
  hidden 'git push'
  hidden "git clone --single-branch '$LAB_DIR/server/support-bot.git' '$LAB_DIR/you/support-bot'"
  git -C "$LAB_DIR/you/support-bot" remote set-url origin "$SERVER_URL" || exit 1
  cd "$LAB_DIR" || exit 1
  as you
}
