#!/usr/bin/env bash
# X8 reference, reference/professional-git-configuration.md.
# Loads the recommended global configuration (labs/ref/professional.gitconfig) in a sandbox,
# shows that Git 2.55.0 accepts every line, shows the conditional include at work, and runs
# every alias once. The signing block is only parsed here: the end-to-end signing run is
# Chapter 14B, section 14B.16 (it needs a freshly generated key and is therefore volatile).
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ref professional-config

# The sandbox home becomes HOME, so that "~" in the file means $LAB_DIR/home. lab-env.sh has
# already pointed GIT_CONFIG_GLOBAL at $LAB_DIR/home/.gitconfig, which is now also ~/.gitconfig.
export HOME="$LAB_DIR/home"
cd "$HOME" || exit 1
hidden() { tick; eval "$1" > /dev/null 2>&1 || { printf 'professional-config: hidden step failed: %s\n' "$1" >&2; exit 1; }; }
# The lab keeps reflog expiry switched off (style guide, section 12). The file under test must
# not contain those lab-only lines, so each repository created below gets them locally.
lab_repo_settings() { hidden 'git config set gc.reflogExpire never'; hidden 'git config set gc.reflogExpireUnreachable never'; }

hidden "cp '$LAB_SCRIPT_DIR/professional.gitconfig' ~/.gitconfig"
hidden "cp '$LAB_SCRIPT_DIR/professional-work.gitconfig' ~/.gitconfig-work"
hidden "cp '$LAB_SCRIPT_DIR/professional-signing.gitconfig' ~/.gitconfig-signing"
hidden "mkdir -p ~/.config/git && printf '.DS_Store\n.idea/\n' > ~/.config/git/ignore"

snip 01-the-file
run 'cat ~/.gitconfig'

snip 02-accepted
note 'Git parses the file and lists every key. A syntax error would stop here with "bad config line".'
run_rc 'git config list --file ~/.gitconfig > /dev/null'
run 'git config list --file ~/.gitconfig --name-only | grep -c .'
note 'Every key is a name that Git 2.55.0 documents. A mistyped key is accepted silently by the'
note 'parser, so compare the names with "git help --config". Alias names and include conditions'
note 'carry a part that you choose; they are counted separately.'
run 'git config list --file ~/.gitconfig --name-only | grep -v -e "^alias\." -e "^includeif\." | while read -r key; do git help --config | grep -q -i -x "$key" || echo "not documented: $key"; done'
run 'git config list --file ~/.gitconfig --name-only | grep -c -e "^alias\." -e "^includeif\."'

snip 03-identities
hidden 'git init ~/oss/retrieval-api'
hidden 'git init ~/work/retrieval-api'
run 'cd ~/oss/retrieval-api'
run 'git config get --show-origin user.email'
run 'cd ~/work/retrieval-api'
run 'git config get --show-origin user.email'
run 'git var GIT_DEFAULT_BRANCH'
run 'git config get --show-origin --show-scope merge.conflictStyle'

# A server and a clone for the aliases.
cd "$HOME" || exit 1
hidden 'rm -rf ~/oss/retrieval-api ~/work/retrieval-api'
hidden 'git init --bare ~/server/retrieval-api.git'
hidden 'git clone ~/server/retrieval-api.git ~/work/retrieval-api'
cd "$HOME/work/retrieval-api" || exit 1
lab_repo_settings
as config
hidden "mkdir -p api config && printf '# retrieval-api\n\nServes nearest-neighbour search for the RAG pipeline.\n' > README.md && git add README.md && git commit -m 'Add README'"
hidden "printf 'def search(query, k=5):\n    return index.nearest(embed(query), k)\n' > api/search.py && git add api/search.py && git commit -m 'Add search endpoint'"
hidden "printf 'top_k: 5\n' > config/search.yaml && git add config/search.yaml && git commit -m 'Add search defaults'"
hidden 'git push'
hidden 'git switch -c feature/rerank'
hidden "printf 'def rerank(hits):\n    return sorted(hits, key=score, reverse=True)\n' > api/rerank.py && git add api/rerank.py && git commit -m 'Add reranker'"
hidden 'git switch main'

snip 04-st-lg-last
run 'git st'
run 'git lg'
run 'git last'
run 'git last feature/rerank'

snip 05-unstage-amend
run "printf 'timeout_ms: 800\n' >> config/search.yaml"
run "printf 'scratch\n' > notes.txt"
run 'git add .'
run 'git st'
run 'git unstage notes.txt'
run 'git st'
run 'git amend'
run 'git st'

snip 06-pushf
note 'The amended commit replaced one that the server already has, so a plain push is rejected.'
run_rc 'git push'
run 'git pushf --dry-run'
run 'git pushf'
run 'git st'

snip 07-signing-block
run 'cat ~/.gitconfig-signing'
run_rc 'git config list --file ~/.gitconfig-signing'
lab_end
