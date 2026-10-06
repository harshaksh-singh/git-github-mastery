#!/usr/bin/env bash
# Stage 6: a branch that a teammate needs is gone from the server. Applies the incident on top
# of the state that the solution of stage 5 leaves, and writes evidence files into the sandbox.
# Read BRIEFING.md, not this file, before you start: the script is part of the answer.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/capstone-lib.bash"
cap_inject_begin 6 "$@"
B=feature/multilingual-intents

# Monday 21 September. Kabir starts multilingual intents. The first two commits are reviewed
# and merged with a merge commit; the server deletes the head branch, as it does after a merge.
cap_go kabir
quiet 'git switch main'
quiet 'git pull --ff-only'
quiet "git switch -c $B"
printf '"""Detect the language of a message."""\n\n\ndef detect(text):\n    return "en"\n' > router/lang.py
_cp 'Add a language detection stub' router/lang.py
cat > router/lang.py <<'F'
"""Detect the language of a message."""


def detect(text):
    """Two-letter language code. Text in Devanagari script counts as Hindi."""
    if any("ऀ" <= ch <= "ॿ" for ch in text):
        return "hi"
    return "en"
F
_cp 'Detect Devanagari script as Hindi' router/lang.py
quiet "git push -u origin $B"
cap_pr "open $B --title 'Language detection groundwork'"

# Tanvi fetches while the branch is on the server. She does not prune, today or later.
cap_go tanvi
quiet 'git switch main'
quiet 'git fetch'

cap_as nandini
cap_pr "merge $B --merge"

# Kabir keeps working on his local branch and pushes it again under the same name.
cap_go kabir
printf '"""Keywords of each intent in Hindi, transliterated."""\n\nKEYWORDS = {\n    "billing_refund": {"refund", "paisa", "wapas"},\n    "order_status": {"order", "kahan", "kab"},\n}\n' > router/keywords_hi.py
_cp 'Add Hindi keyword lists' router/keywords_hi.py
printf '"""Keywords of each intent in Tamil, transliterated."""\n\nKEYWORDS = {\n    "billing_refund": {"refund", "panam", "thirumba"},\n    "order_status": {"order", "enge", "eppo"},\n}\n' > router/keywords_ta.py
_cp 'Add Tamil keyword lists' router/keywords_ta.py
quiet "git push -u origin $B"
cap_pr "open $B --title 'Hindi and Tamil intents'"

# You fetch in the evening.
cap_go you
quiet 'git fetch'

# Kabir pushes one more commit and leaves for the airport.
cap_go kabir
cat >> router/lang.py <<'F'


def keywords_for(language, default):
    """The keyword lists of a language, or the default lists when there are none."""
    if language == "hi":
        from router.keywords_hi import KEYWORDS
    elif language == "ta":
        from router.keywords_ta import KEYWORDS
    else:
        return default
    return KEYWORDS
F
cat > tests/test_lang.py <<'F'
import unittest

from router.lang import detect, keywords_for


class LangTest(unittest.TestCase):
    def test_default_language_is_english(self):
        self.assertEqual(detect("where is my order"), "en")

    def test_keywords_follow_the_language(self):
        default = {"billing_refund": {"refund"}}
        self.assertIn("wapas", keywords_for("hi", default)["billing_refund"])
        self.assertIn("thirumba", keywords_for("ta", default)["billing_refund"])
        self.assertIs(keywords_for("en", default), default)
F
_cp 'Pick the keyword lists by detected language' router/lang.py tests/test_lang.py
quiet 'git push'
quiet 'git switch main'

# Tuesday morning, before stand-up: Tanvi tidies up the branch list on the server.
cap_at 15 -60
E="$LAB_DIR/evidence/stage-06"
mkdir -p "$E"
cat > "$E/cleanup-merged-branches.sh" <<'F'
#!/usr/bin/env bash
# Delete branches on the server that are already merged into main.
git fetch origin main
for b in $(git branch -r --merged origin/main | sed 's|^ *origin/||' | grep -Ev '^(main|HEAD|release/)'); do
  echo "merged, deleting: $b ($(git rev-parse --short "origin/$b"))"
  git push origin --delete "$b"
done
F
cap_go tanvi
tick
bash "$E/cleanup-merged-branches.sh" 2>&1 | _lab_filter > "$E/cleanup-output.txt"

cap_inject_end 6
