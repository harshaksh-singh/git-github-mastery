#!/bin/sh
# Scripted stand-in for the commit message editor, used by run_add_paragraph in fixtures.sh.
# It behaves like a person who keeps the message that Git proposes and adds one paragraph after the
# subject line. The paragraph is taken from the environment variable LAB_PARAGRAPH.
# It prints the message before and after the edit, so the transcript shows what the editor showed.
f="$1"
show() { grep -v '^#' "$f" | awk 'NF { for (i = 0; i < blank; i++) print ""; blank = 0; print; next } { blank++ }'; }
echo "--- message as Git opened it (comment lines removed) ---"
show
awk -v p="$LAB_PARAGRAPH" 'NR == 1 { print; print ""; print p; next } { print }' "$f" > "$f.lab-new" && mv "$f.lab-new" "$f"
echo "--- message as saved ---"
show
exit 0
