#!/usr/bin/env bash
# Gate 7 (Actions), prediction part: the Git and shell side of what a runner does, reproduced
# locally. No GitHub command is run. The pN-setup snippets are printed in the gate file, the
# pN-answer snippets only in the answer key.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin gates g7-predict

# ---- P1: the commit a pull_request run checks out
snip p1-setup
note 'The last block imitates GitHub: it records the head of pull request 7 and builds the test merge.'
run 'git init -q gateway'
run 'cd gateway'
run "printf 'MAX_TOKENS = 512\n' > limits.py && git add . && git commit -q -m 'Add limits'"
run 'git switch -q -c feature/streaming'
run "printf 'def stream(chunks):\n    yield from chunks\n' > stream.py && git add . && git commit -q -m 'Add streaming'"
run 'git switch -q main'
run "printf 'MAX_TOKENS = 256\n' > limits.py && git commit -q -am 'Halve the token limit'"
run 'git update-ref refs/pull/7/head feature/streaming'
run 'git switch -q --detach main'
run 'git merge -q --no-ff -m "Merge feature/streaming into main" feature/streaming'
run 'git update-ref refs/pull/7/merge HEAD'
run 'git switch -q feature/streaming'
note 'The runner, on a pull_request event:'
run 'git switch -q --detach refs/pull/7/merge'
snip p1-answer
run 'git status -sb'
run "git log -1 --format='%s (parents: %p)' | sed 's/ [0-9a-f]\\{7\\}/ <id>/g'"
run 'git log -1 --format=%s HEAD^1'
run 'git log -1 --format=%s HEAD^2'
run 'cat limits.py'
run 'git show feature/streaming:limits.py'
run_rc 'test "$(git rev-parse HEAD)" = "$(git rev-parse refs/pull/7/head)"'
cd "$LAB_DIR"

# ---- P2: what a path filter is compared with
snip p2-setup
run 'git init -q mono'
run 'cd mono'
run 'mkdir py-service java-service'
run "printf 'print(1)\n' > py-service/app.py && printf 'class Build {}\n' > java-service/Build.java"
run 'git add . && git commit -q -m "Add two services"'
run 'git switch -q -c feature/py-logging'
run "printf 'print(2)\n' > py-service/app.py && git commit -q -am 'Log the request id'"
run 'git switch -q main'
run "printf 'class Build { int v = 2; }\n' > java-service/Build.java && git commit -q -am 'Bump the Java build'"
snip p2-answer
run 'git diff --name-only main...feature/py-logging'
run 'git diff --name-only main..feature/py-logging'
run_rc 'git diff --quiet main...feature/py-logging -- "java-service/**"'
run_rc 'git diff --quiet main..feature/py-logging -- "java-service/**"'
cd "$LAB_DIR"

# ---- P3: the two shell templates
mkdir shells && cd shells || exit 1
snip p3-setup
run "printf 'test_load PASSED\ntest_save PASSED\n' > results.txt"
run "printf 'grep -c FAILED results.txt | tee failed-count.txt\necho \"report written\"\n' > step.sh"
run 'cat step.sh'
snip p3-answer
note 'A run step without a shell key, on Linux or macOS: bash -e {0}'
run_rc 'bash -e step.sh'
note 'A run step with "shell: bash": bash --noprofile --norc -eo pipefail {0}'
run_rc 'bash --noprofile --norc -eo pipefail step.sh'
cd "$LAB_DIR"

# ---- P4: a cache key built from a lock file
mkdir cache && cd cache || exit 1
key() { printf 'deps-%s\n' "$(shasum -a 256 uv.lock | cut -c1-8)"; }
snip p4-setup
note 'key prints what  deps-${{ hashFiles(...) }}  would be if only uv.lock were hashed (shortened).'
run "printf 'requests==2.32.0\n' > uv.lock"
run "printf '[project]\ndependencies = [\"requests\"]\n' > pyproject.toml"
run 'key > key-1.txt'
run "printf '[project]\ndependencies = [\"requests\", \"httpx\"]\n' > pyproject.toml"
run 'key > key-2.txt'
run "printf 'requests==2.32.0\nhttpx==0.28.0\n' > uv.lock"
run 'key > key-3.txt'
run "printf 'requests==2.32.0\n' > uv.lock"
run 'key > key-4.txt'
snip p4-answer
run 'cmp -s key-1.txt key-2.txt && echo "key 2 = key 1" || echo "key 2 differs from key 1"'
run 'cmp -s key-2.txt key-3.txt && echo "key 3 = key 2" || echo "key 3 differs from key 2"'
run 'cmp -s key-1.txt key-4.txt && echo "key 4 = key 1" || echo "key 4 differs from key 1"'
lab_end
