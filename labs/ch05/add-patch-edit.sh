#!/usr/bin/env bash
# "git add -p" where "s" cannot help: changed lines that touch each other need the answer
# "e" (manual hunk edit), and a file that is still untracked needs "git add -N" first.
# Also shows the trap of hunk editing: the index can end up with a line order that exists
# in neither HEAD nor the working tree. Chapter 5, section 5.5.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/keys.inc"
lab_begin ch05 add-patch-edit

# A scripted stand-in for the person at the editor that "git add -p" opens for the answer "e".
# It prints the hunk file as Git wrote it, applies the sed program in LAB_HUNK_SED, and prints
# the result. With LAB_HUNK_SHOW=saved only the result is printed.
cat > "$LAB_DIR/hunk-editor" <<'ED'
#!/bin/sh
f="$1"
if [ "${LAB_HUNK_SHOW:-both}" = "both" ]; then
  echo "--- the hunk file as Git opened it in the editor ---"
  cat "$f"
fi
sed -e "$LAB_HUNK_SED" "$f" > "$f.lab-new" && mv "$f.lab-new" "$f"
echo "--- the hunk as saved (comment lines left out) ---"
grep -v '^#' "$f"
exit 0
ED
chmod +x "$LAB_DIR/hunk-editor"
export GIT_EDITOR="'$LAB_DIR/hunk-editor'"

git init -q support-bot
cd support-bot || exit 1
mkdir -p config src
printf 'model: small-v1\ntop_k: 5\ntemperature: 0.7\nmax_tokens: 512\n' > config/settings.yaml
printf 'def answer(question):\n    return "ok"\n' > src/app.py
quiet 'git add . && git commit -m "Add settings and service skeleton"'

# Three edits on neighbouring lines: two value changes and a debug switch.
printf 'model: small-v1\ntop_k: 8\ntemperature: 0.2\ndebug: true\nmax_tokens: 512\n' > config/settings.yaml

snip 01-cannot-split
note 'The changed lines touch each other, so the prompt offers no "s". Typing it anyway:'
run_keys 's q' 'git add -p'

snip 02-edit
note 'Answer "e". In the editor, delete the line "+debug: true", then save and close.'
export LAB_HUNK_SED='/^+debug/d' LAB_HUNK_SHOW=both
run_keys 'e' 'git add -p'

snip 03-result
run 'git status --short'
run 'git diff --cached'
run 'git diff'

snip 04-edit-one-of-two
note 'Start again. This time stage only the top_k change.'
run 'git restore --staged config/settings.yaml'
note 'In the editor: turn "-temperature: 0.7" into a context line, delete "+temperature: 0.2" and "+debug: true".'
export LAB_HUNK_SED='s/^-temperature/ temperature/;/^+temperature/d;/^+debug/d' LAB_HUNK_SHOW=saved
run_keys 'e' 'git add -p'

snip 05-order-changed
note 'The staged file. Compare the order of its lines with HEAD and with the working tree.'
run 'git show :config/settings.yaml'
run 'git show HEAD:config/settings.yaml'
run 'cat config/settings.yaml'

snip 06-new-file
quiet 'git restore --staged config/settings.yaml'
printf 'SYSTEM = "You are a support assistant."\nMAX_TURNS = 6\n' > src/prompts.py
note 'The hunk selector reads the same comparison as "git diff", so it does not see an untracked file.'
run 'git add -p src/prompts.py'
run 'git add -N src/prompts.py'
run_keys 'y' 'git add -p src/prompts.py'
run 'git status --short'

lab_end
