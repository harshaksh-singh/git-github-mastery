# labs/ch15/fixture.bash - shared fixture for the Chapter 15 demos and the labs of
# Modules 19 and 25.
#
# Sourced by the scripts in this directory right after lab-env.sh. It is not a demo:
# the file name does not end in .sh, so the build and verify tools skip it.
#
# The project is "prompt-registry", a very small package that stores versioned prompt
# templates for an LLM application. Its files are in labs/ch15/practice-repo-template/,
# the same files the learner pushes to the practice repository in Lab 19.1.
#
# Nothing here talks to GitHub. Where a script imitates something the platform does (a fork,
# a tag created by a release, a squash merge), a note in the transcript says so, and the
# chapter names the documented behavior that is being imitated. The commands that play the
# platform are plain Git chosen by the author. They are not GitHub's implementation.

TEMPLATE="$LAB_SCRIPT_DIR/practice-repo-template"

# hidden '<command line>'
# A setup step that the transcript does not show. A failing hidden step stops the script:
# a setup that fails silently would make the transcript lie.
hidden() {
  tick
  eval "$1" > /dev/null 2>&1 || { printf 'fixture: hidden step failed: %s\n' "$1" >&2; exit 1; }
}

# commit_paths <message> <path>...
# Stage the given paths and commit them, silently. Advances the clock.
commit_paths() {
  local msg="$1"; shift
  tick
  { git add -- "$@" && git commit -q -m "$msg"; } > /dev/null 2>&1 ||
    { printf 'fixture: commit_paths failed: %s\n' "$msg" >&2; exit 1; }
}

# copy_template <directory>
# Copy the practice repository files (dotfiles included) into a directory. No Git commands.
copy_template() {
  mkdir -p "$1" && cp -R "$TEMPLATE/." "$1/" || { printf 'fixture: copy_template failed\n' >&2; exit 1; }
  find "$1" -name __pycache__ -prune -exec rm -rf {} + 2>/dev/null
  return 0
}

# make_registry <directory>
# The prompt-registry repository with four commits on main. Ends inside it.
make_registry() {
  copy_template "$1"
  cd "$1" || exit 1
  hidden 'git init'
  commit_paths 'Add README' README.md
  commit_paths 'Add prompt registry package' .gitignore pyproject.toml src
  commit_paths 'Add registry tests' tests
  commit_paths 'Add contribution guide, security policy and templates' CONTRIBUTING.md SECURITY.md .github docs
}

# make_server <name>
# A bare repository $LAB_DIR/server/<name>.git that plays the shared repository on the
# platform, seeded with the four commits of make_registry. Ends in $LAB_DIR.
make_server() {
  make_registry "$LAB_DIR/.seed"
  hidden "git init --bare '$LAB_DIR/server/$1.git'"
  hidden "git push '$LAB_DIR/server/$1.git' main"
  cd "$LAB_DIR" || exit 1
  rm -rf "$LAB_DIR/.seed"
}

# clone_for <person> <name>
# A clone in $LAB_DIR/<person>/<name> whose origin URL is a relative path, so that no
# transcript depends on where the sandbox lives.
clone_for() {
  hidden "git clone '$LAB_DIR/server/$2.git' '$LAB_DIR/$1/$2'"
  git -C "$LAB_DIR/$1/$2" remote set-url origin "../../server/$2.git" || exit 1
  case "$1" in
    asha) git -C "$LAB_DIR/$1/$2" config set user.name 'Asha Rao'; git -C "$LAB_DIR/$1/$2" config set user.email asha@example.com ;;
  esac
}

# add_professional_extras
# In the current repository, add the files that turn the practice skeleton into the
# "professional layout" of Chapter 15. The Dockerfile was written from the Docker reference
# and was not built here (no image pulls while authoring).
add_professional_extras() {
  mkdir -p scripts configs .github || exit 1
  printf 'Placeholder license file for the layout demo.\nIn Lab 19.1 the real text comes from: gh repo license view MIT\n' > LICENSE
  printf '# Every change needs a review from the maintainers team (Chapter 19).\n*       @acme-ml/maintainers\n/docs/  @acme-ml/docs\n' > .github/CODEOWNERS
  printf '#!/usr/bin/env bash\n# Tag a release from an up-to-date main. Usage: scripts/release.sh v0.2.0\nset -euo pipefail\ngit fetch origin\ngit tag -a "$1" -m "prompt-registry $1" origin/main\ngit push origin "$1"\n' > scripts/release.sh
  chmod +x scripts/release.sh
  printf 'max_versions_per_prompt: 50\nstore: memory\n' > configs/default.yaml
  printf 'FROM python:3.12-slim\nWORKDIR /app\nCOPY pyproject.toml README.md ./\nCOPY src ./src\nRUN pip install --no-cache-dir .\nCMD ["python", "-c", "import prompt_registry; print(prompt_registry.__doc__)"]\n' > Dockerfile
}

# platform_squash_merge <name> <branch> <subject>
# Stand-in for the platform's "Squash and merge": one new commit on the server's main that
# contains the branch's changes, then the branch is deleted on the server. Uses a scratch
# clone and plain Git. Ends in the directory it was called from.
platform_squash_merge() {
  local back="$PWD"
  hidden "git clone '$LAB_DIR/server/$1.git' '$LAB_DIR/.platform'"
  cd "$LAB_DIR/.platform" || exit 1
  hidden "git merge --squash 'origin/$2'"
  hidden "git commit -m '$3'"
  hidden 'git push origin main'
  hidden "git push origin --delete '$2'"
  cd "$back" || exit 1
  rm -rf "$LAB_DIR/.platform"
}

# setup_done <lab number> <sandbox name> <first command>
setup_done() {
  printf 'Lab %s is ready in %s\n' "$1" "$LAB_DIR"
  printf 'Open the lab shell there:  labs/shell %s\n' "$2"
  printf 'First command of the lab:  %s\n' "$3"
}

# ---------------------------------------------------------------- lab starting states
# Lab 19.1 (local part): the practice repository files in a plain directory. No repository yet.
scenario_19_1() {
  copy_template "$LAB_DIR/practice-repo"
  cd "$LAB_DIR" || exit 1
}

# Lab 19.2 (local part): a server that stands in for the platform, with a feature branch,
# an annotated tag, and your clone.
scenario_19_2() {
  make_server practice-repo
  clone_for asha practice-repo
  cd "$LAB_DIR/asha/practice-repo" || exit 1
  as asha
  hidden 'git tag -a v0.1.0 -m "practice-repo 0.1.0"'
  hidden 'git push origin v0.1.0'
  hidden 'git switch -c feature/list-names'
  printf '\n    def names(self):\n        """Return the registered prompt names, sorted."""\n        return sorted(self._versions)\n' >> src/prompt_registry/registry.py
  commit_paths 'Add names() to list registered prompts

Fixes #12' src/prompt_registry/registry.py
  hidden 'git push -u origin feature/list-names'
  as you
  cd "$LAB_DIR" || exit 1
  clone_for you practice-repo
}

# Lab 25.1 (local part): the server and your clone, nothing else.
scenario_25_1() {
  make_server practice-repo
  clone_for you practice-repo
  cd "$LAB_DIR" || exit 1
}
