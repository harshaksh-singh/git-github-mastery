#!/bin/sh
# Print the commit that a release is built from: the tip of main.
# Ask Git. It knows where refs are stored and how long an object ID is.
id=$(git rev-parse --verify --quiet 'refs/heads/main^{commit}') || {
  echo "release-id: this repository has no branch main" >&2
  exit 1
}
echo "$id"
