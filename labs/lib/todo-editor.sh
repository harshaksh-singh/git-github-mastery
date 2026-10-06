#!/usr/bin/env bash
# Scripted stand-in for the editor that "git rebase -i" opens on the todo list.
# Use as:  LAB_TODO_SED='2s/^pick/squash/' GIT_SEQUENCE_EDITOR="$LAB_LIB/todo-editor.sh" git rebase -i <base>
#   LAB_TODO_SED  a sed program applied to the todo file, or
#   LAB_TODO_CMD  a shell command; the todo file path is available as $f
# It prints the todo list before and after the edit so that the transcript shows what a human would see.
f="$1"
echo "--- todo list as Git opened it (comment lines removed) ---"
grep -v '^#' "$f" | grep -v '^$'
if [ -n "${LAB_TODO_SED:-}" ]; then
  sed -e "$LAB_TODO_SED" "$f" > "$f.lab-new" && mv "$f.lab-new" "$f"
fi
if [ -n "${LAB_TODO_CMD:-}" ]; then
  eval "$LAB_TODO_CMD"
fi
echo "--- todo list as saved ---"
grep -v '^#' "$f" | grep -v '^$'
exit 0
