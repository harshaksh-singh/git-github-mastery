#!/bin/sh
# Print the commit that a release is built from: the tip of main. (Written in 2019.)
id=$(cat .git/refs/heads/main) || exit 1
if ! echo "$id" | grep -Eq '^[0-9a-f]{40}$'; then
  echo "release-id: not a commit ID: $id" >&2
  exit 1
fi
echo "$id"
