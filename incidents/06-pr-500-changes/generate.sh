#!/usr/bin/env bash
# Incident 6: a pull request suddenly shows 500 unrelated changes.
# Builds server.git and the clones you/, asha/ and ravi/ of the project "doc-search". There is
# no GitHub here: the "pull request" is the commit list and the diff that GitHub would compute
# for feature/snippet-highlight into main. Read SYMPTOMS.md before you start.
. "$(dirname "${BASH_SOURCE[0]}")/../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/incidents/lib/incident-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin incidents 06-pr-500-changes
inc_begin

inc_server
inc_clone you
cd you || exit 1
mkdir -p search tests
printf 'def tokenize(text):\n    return text.lower().split()\n' > search/tokenize.py
printf 'def search(index, query):\n    return index.lookup(tokenize(query))\n' > search/query.py
_c 'Add query pipeline'
printf 'def test_tokenize():\n    assert tokenize("Hello World") == ["hello", "world"]\n' > tests/test_tokenize.py
_c 'Add tokenizer test'
quiet 'git push -u origin main'
cd "$LAB_DIR" || exit 1
inc_clone asha
inc_clone ravi

# Asha: the long-running branch "develop" with a fixture refresh that is not released yet.
cd "$LAB_DIR/asha" || exit 1
as asha
quiet 'git switch -c develop'
printf 'import json\n\ndef write_golden(queries, outdir):\n    for i, q in enumerate(queries, 1):\n        json.dump({"query": q}, open(f"{outdir}/q{i:04d}.json", "w"))\n' > tests/make_golden.py
_c 'Add golden fixture generator'
mkdir -p tests/golden
for i in $(seq -w 1 500); do
  printf '{"query": "sample query %s", "top_doc": "doc-%s"}\n' "$i" "$i" > "tests/golden/q0$i.json"
done
_c 'Regenerate golden fixtures'
printf 'import icu\n\ndef tokenize(text):\n    return [t.lower() for t in icu.words(text)]\n' > search/tokenize.py
_c 'Switch the tokenizer to ICU word breaking'
quiet 'git push -u origin develop'

# Ravi: a small feature branch from main, with an open pull request into main.
cd "$LAB_DIR/ravi" || exit 1
as ravi
quiet 'git switch -c feature/snippet-highlight'
printf 'def highlight(snippet, term):\n    return snippet.replace(term, f"<em>{term}</em>")\n' > search/highlight.py
_c 'Add snippet highlighting'
printf 'def test_highlight():\n    assert highlight("a cat sat", "cat") == "a <em>cat</em> sat"\n' > tests/test_highlight.py
_c 'Test snippet highlighting'
printf 'import html\n\ndef highlight(snippet, term):\n    return html.escape(snippet).replace(html.escape(term), f"<em>{html.escape(term)}</em>")\n' > search/highlight.py
_c 'Escape HTML in snippets'
quiet 'git push -u origin feature/snippet-highlight'
# "Update my branch with the latest", from the wrong branch, then one more commit and a push.
quiet 'git pull --no-rebase origin develop'
printf 'import html\n\ndef highlight(snippet, terms):\n    out = html.escape(snippet)\n    for term in terms:\n        out = out.replace(html.escape(term), f"<em>{html.escape(term)}</em>")\n    return out\n' > search/highlight.py
_c 'Highlight every query term'
quiet 'git push'

inc_end
[ -n "${LAB_REPLAY:-}" ] || printf 'Incident ready. Open a lab shell there:\n  labs/shell "%s"\n' "$LAB_DIR"
