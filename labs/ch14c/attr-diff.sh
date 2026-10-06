#!/usr/bin/env bash
# Chapter 14C, section 14C.6: diff drivers. A textconv driver that shows notebook diffs as source
# code, the attribute without the driver, and the built-in "python" hunk-header pattern.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch14c attr-diff

quiet 'git init analysis'
cd analysis || exit 1
quiet 'mkdir tools'
quiet "cp '$LAB_SCRIPT_DIR/files/nbsource.py' tools/nbsource.py && cp '$LAB_SCRIPT_DIR/files/eda-run1.ipynb' eda.ipynb"
cat > metrics.py <<'PY'
class Accuracy:
    def update(self, pred, gold):
        self.total += 1
        self.seen.append(pred)
        if gold is None:
            return
        self.pairs.append((pred, gold))
        self.hits += int(pred == gold)

    def result(self):
        return self.hits / self.total
PY
quiet "git add . && git commit -m 'Add error-analysis notebook and metric'"
# The notebook is run again with a changed cell: new source, new output, new execution count.
quiet "cp '$LAB_SCRIPT_DIR/files/eda-run3.ipynb' eda.ipynb"

snip 01-raw-diff
run 'git diff --stat'
run 'git diff eda.ipynb'

snip 02-attribute-only
run "printf '*.ipynb diff=notebook\n' > .gitattributes"
run 'git check-attr diff -- eda.ipynb'
note 'The attribute names a driver that no configuration defines yet, so nothing changes:'
run 'git diff --stat eda.ipynb'

snip 03-driver
run 'cat tools/nbsource.py'
run "git config set diff.notebook.textconv 'python3 tools/nbsource.py'"
run 'git diff eda.ipynb'

snip 04-scope
note 'textconv is for reading. Commands that produce patches for machines ignore it:'
run 'git diff --no-textconv --stat eda.ipynb'
run 'git add . && git commit -q -m "Evaluate on the test split"'
run 'git log -1 -p --format=%s -- eda.ipynb'
run 'git format-patch -1 --stdout -- eda.ipynb | grep -c "execution_count"'

snip 05-funcname
quiet "sed 's/int(pred == gold)/int(pred.strip() == gold.strip())/' metrics.py > metrics.tmp && mv metrics.tmp metrics.py"
run 'git diff metrics.py'
run "printf '*.py diff=python\n' >> .gitattributes"
run 'git diff metrics.py'

lab_end
