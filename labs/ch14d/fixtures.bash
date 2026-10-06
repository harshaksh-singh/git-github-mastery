# labs/ch14d/fixtures.bash — starting states shared by the Chapter 14D demos and the Module 42
# labs (Lab 42.1 to Lab 42.3).
#
# This file is sourced, never run:   . "$LAB_SCRIPT_DIR/fixtures.bash"
# Each function builds one starting state inside the current sandbox ($LAB_DIR) and returns with
# the current directory set back to $LAB_DIR. A hands-on setup script and the replay script of
# the same lab call the same function at the same point of the lab clock, so the commits that the
# fixture creates have the same IDs in your hands-on sandbox as in the book.

# ------------------------------------------------------------------ git history demo
# evalkit: four commits on main, the first with a typo in its subject, the second mixing a
# metric and its test; release/0.1 points at the third commit; topic/judge adds one commit.
fx_history_repo() {
  quiet 'git init evalkit'
  cd evalkit || return 1
  quiet "printf 'def exact(pred, gold):\n    return pred == gold\n' > metrics.py && git add . && git commit -m 'Add exact match metirc'"
  quiet "printf 'def exact(pred, gold):\n    return pred == gold\n\n\ndef f1(tp, fp, fn):\n    return 2 * tp / (2 * tp + fp + fn)\n' > metrics.py && printf 'from metrics import f1\n\n\ndef test_f1():\n    assert f1(1, 0, 0) == 1.0\n' > test_metrics.py && git add . && git commit -m 'Add F1 and its test'"
  quiet "printf '# evalkit\n\nMetrics for the evaluation harness.\n' > README.md && git add . && git commit -m 'Add README'"
  quiet 'git branch release/0.1'
  quiet 'git switch -c topic/judge'
  quiet "printf 'You are a strict grader. Reply PASS or FAIL.\n' > judge.txt && git add . && git commit -m 'Add judge prompt'"
  quiet 'git switch main'
  quiet "printf 'pytest\n' > requirements-dev.txt && git add . && git commit -m 'Add development requirements'"
  cd "$LAB_DIR" || return 1
}

# ------------------------------------------------------------------ git replay, last-modified, repo
# server.git (bare) holds main (two commits) and fix/timeout (two commits that branch off the
# first commit of main). "dev" is the clone that pushed them.
fx_gateway_server() {
  quiet 'git init --bare server.git'
  quiet 'git clone server.git dev'
  cd dev || return 1
  quiet "mkdir -p src docs && printf 'def route(request):\n    return upstream(request)\n' > src/router.py && printf 'requests_per_minute: 60\n' > src/limits.yaml && printf '# Gateway\n' > docs/README.md && git add . && git commit -m 'Add gateway skeleton'"
  quiet "printf 'requests_per_minute: 120\n' > src/limits.yaml && git commit -am 'Raise the rate limit to 120'"
  quiet 'git switch -c fix/timeout HEAD~1'
  quiet "printf 'def route(request):\n    return with_timeout(upstream, request, seconds=10)\n' > src/router.py && git commit -am 'Add a 10 second timeout to routing'"
  quiet "printf '# Gateway\n\nRequests time out after 10 seconds.\n' > docs/README.md && git commit -am 'Document the timeout'"
  quiet 'git switch main'
  quiet 'git push --all origin'
  cd "$LAB_DIR" || return 1
}

# ------------------------------------------------------------------ patch workflow
# upstream: the maintainer's repository (Ravi Menon), one commit on main.
# contributor: a clone in which Asha Rao has the branch "casefold" with two signed-off commits.
# Neither repository can push to the other: changes travel as patch files, as they do on the
# Git project's mailing list.
fx_patch_repos() {
  as ravi
  quiet 'git init upstream'
  quiet 'git -C upstream config set user.name "Ravi Menon" && git -C upstream config set user.email ravi@example.com'
  quiet "cd upstream && printf 'def tokenize(text):\n    return text.split()\n' > tok.py && printf '# tok\n\nA whitespace tokenizer.\n' > README.md && git add . && git commit -m 'Add whitespace tokenizer' && cd .."
  quiet 'git clone upstream contributor'
  as asha
  quiet 'git -C contributor config set user.name "Asha Rao" && git -C contributor config set user.email asha@example.com'
  cd contributor || return 1
  quiet 'git switch -c casefold'
  quiet "printf 'def tokenize(text):\n    return text.lower().split()\n' > tok.py && git commit -s -am 'tok: lowercase the input before splitting'"
  quiet "printf '# tok\n\nA whitespace tokenizer. Input is lowercased first.\n' > README.md && git commit -s -am 'README: document the lowercasing'"
  cd "$LAB_DIR" || return 1
  as you
}

# ------------------------------------------------------------------ Lab 42.1
# inference: an ordinary repository of today (SHA-1 object IDs, refs in files) with two
# branches and an annotated tag. scripts/ holds a release script that reads the repository
# directly, and the corrected version that the Recovery installs.
fx_42_1() {
  quiet 'git init inference'
  cd inference || return 1
  quiet "printf 'def predict(batch):\n    return model(batch)\n' > serve.py && printf 'batch_size: 8\n' > serve.yaml && git add . && git commit -m 'Add inference service'"
  quiet "printf 'batch_size: 16\n' > serve.yaml && git commit -am 'Raise batch size to 16'"
  quiet 'git tag -a v0.1.0 -m "First internal release"'
  quiet 'git switch -c feature/batching'
  quiet "printf 'def predict(batch):\n    return model(pad(batch))\n' > serve.py && git commit -am 'Pad batches to a fixed length'"
  quiet 'git switch main'
  cd "$LAB_DIR" || return 1
  mkdir -p scripts
  cp "$LAB_SCRIPT_DIR/files/release-id.sh" scripts/release-id.sh
  cp "$LAB_SCRIPT_DIR/files/release-id.v2.sh" scripts/release-id.v2.sh
}

# ------------------------------------------------------------------ Lab 42.2
# server.git (bare, plays origin) and your clone evalkit. Two commits are pushed. Two more are
# local, the first of them with a typo in its subject, and the local branch topic/judge adds
# one commit on top.
fx_42_2() {
  quiet 'git init --bare server.git'
  quiet 'git clone server.git evalkit'
  cd evalkit || return 1
  quiet "printf 'def exact(pred, gold):\n    return pred == gold\n' > metrics.py && git add . && git commit -m 'Add exact-match metric'"
  quiet "printf 'def f1(tp, fp, fn):\n    return 2 * tp / (2 * tp + fp + fn)\n' > f1.py && git add . && git commit -m 'Add F1'"
  quiet 'git push -u origin main'
  quiet "printf 'def recall(tp, fn):\n    return tp / (tp + fn)\n' > recall.py && git add . && git commit -m 'Add recall metirc'"
  quiet "printf '# evalkit\n\nMetrics for the evaluation harness.\n' > README.md && git add . && git commit -m 'Add README'"
  quiet 'git switch -c topic/judge'
  quiet "printf 'You are a strict grader. Reply PASS or FAIL.\n' > judge.txt && git add . && git commit -m 'Add judge prompt'"
  quiet 'git switch main'
  cd "$LAB_DIR" || return 1
}

# ------------------------------------------------------------------ Lab 42.3
# upstream: the maintainer's repository (Ravi Menon is configured as its identity).
# fork: your clone with the branch fix/casefold (two commits). No push access: the changes
# travel as patch files.
fx_42_3() {
  as ravi
  quiet 'git init upstream'
  quiet 'git -C upstream config set user.name "Ravi Menon" && git -C upstream config set user.email ravi@example.com'
  quiet "cd upstream && printf 'def tokenize(text):\n    return text.split()\n' > tok.py && printf '# tok\n\nA whitespace tokenizer.\n' > README.md && git add . && git commit -m 'Add whitespace tokenizer' && cd .."
  as you
  quiet 'git clone upstream fork'
  cd fork || return 1
  quiet 'git switch -c fix/casefold'
  quiet "printf 'def tokenize(text):\n    return text.casefold().split()\n' > tok.py && git commit -am 'tok: casefold the input before splitting'"
  quiet "printf '# tok\n\nA whitespace tokenizer. Input is casefolded first.\n' > README.md && git commit -am 'README: document the casefolding'"
  cd "$LAB_DIR" || return 1
}
