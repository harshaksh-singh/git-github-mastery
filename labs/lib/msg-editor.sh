#!/usr/bin/env bash
# Scripted stand-in for the commit message editor.
#   LAB_MSG        if set, every opened message is replaced by this text
#   LAB_MSG_QUEUE  path of a file holding several messages separated by lines that contain only "----";
#                  each time the editor is opened, the first remaining message is used and removed
# With neither set, the message is kept exactly as Git proposed it.
f="$1"
if [ -n "${LAB_MSG_QUEUE:-}" ] && [ -s "${LAB_MSG_QUEUE}" ]; then
  awk 'BEGIN{n=0} /^----$/ {n++; next} n==0 {print}' "$LAB_MSG_QUEUE" > "$f"
  awk 'BEGIN{n=0} /^----$/ {n++; if (n==1) next} n>=1 {print}' "$LAB_MSG_QUEUE" > "$LAB_MSG_QUEUE.rest"
  mv "$LAB_MSG_QUEUE.rest" "$LAB_MSG_QUEUE"
elif [ -n "${LAB_MSG:-}" ]; then
  printf '%s\n' "$LAB_MSG" > "$f"
fi
exit 0
