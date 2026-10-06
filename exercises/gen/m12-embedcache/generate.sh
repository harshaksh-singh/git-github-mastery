#!/usr/bin/env bash
# Exercise 12.10 (Level 4): an hour of work inside an interactive rebase, then "git rebase --abort".
# Builds server.git and the clones you/ and asha/ of the project "embedcache"; the damage is in
# asha/. Read SYMPTOMS.md, not this file: the script is the answer to "what happened".
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/labs/ex2/gen-lib.bash"
ex_begin m12-embedcache

ex_server
ex_clone you
cd you || exit 1
put embedcache/__init__.py <<'F'
"""embedcache: a cache in front of the embedding model."""
F
put embedcache/digest.py <<'F'
import hashlib


def digest(text):
    return hashlib.sha256(text.encode("utf-8")).hexdigest()[:16]
F
_c 'Add text digest'
printf '# embedcache\n\nCaches embeddings by model and text.\n' > README.md
_c 'Add README'
quiet 'git push -u origin main'
cd "$LAB_DIR" || exit 1

ex_clone asha
cd asha || exit 1
as asha
quiet 'git switch -c feature/lru-cache'
put embedcache/key.py <<'F'
from embedcache.digest import digest


def key(model, text):
    return model + ":" + digest(text)
F
_c 'Add cache key builder'
put embedcache/key.py <<'F'
from embedcache.digest import digest


def key(model, text):
    return model.lower() + ":" + digest(text)
F
_c 'Normalize the model name in the key'
put embedcache/lru.py <<'F'
from collections import OrderedDict


class LRU(OrderedDict):
    def __init__(self, capacity):
        super().__init__()
        self.capacity = capacity

    def put(self, k, value):
        self[k] = value
        self.move_to_end(k)
        if len(self) > self.capacity:
            self.popitem(last=False)
F
_c 'Add LRU eviction'

# The interactive rebase: stop at the first commit, improve it, add a test, continue, conflict, abort.
tick
GIT_SEQUENCE_EDITOR="sed -i.bak -e '1s/^pick/edit/'" git rebase -i main > /dev/null 2>&1
put embedcache/key.py <<'F'
from embedcache.digest import digest

KEY_VERSION = "v2"


def key(model, text):
    return KEY_VERSION + ":" + model + ":" + digest(text)
F
quiet 'git commit -a --amend --no-edit'
put tests/test_key.py <<'F'
import unittest

from embedcache.key import KEY_VERSION, key


class KeyTest(unittest.TestCase):
    def test_key_carries_the_version(self):
        self.assertTrue(key("embed-small", "hello").startswith(KEY_VERSION + ":"))

    def test_same_text_same_key(self):
        self.assertEqual(key("embed-small", "hello"), key("embed-small", "hello"))


if __name__ == "__main__":
    unittest.main()
F
_c 'Add cache key test'
quiet 'git rebase --continue'            # stops: conflict in embedcache/key.py
quiet 'git rebase --abort'

ex_end asha
