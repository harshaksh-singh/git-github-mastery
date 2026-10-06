#!/usr/bin/env bash
# Exercise 5.9 (Level 4): two work repositories, two wrong addresses.
# Builds home/ with a global configuration, the work repositories home/work/billing-llm and
# home/work/invoice-ocr, and the personal repository home/oss/dotfiles. Read SYMPTOMS.md, not this
# file, before you start.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/exercises/gen/x1-lib/gen-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin exercises m05-two-identities
ex_begin m05-two-identities

H="$LAB_DIR/home"
# The global file: a personal identity, and a conditional include for everything under ~/work/.
# The include names a file that does not exist (the real one is ~/.gitconfig-work), so Git
# skips it without a message.
cat > "$H/.gitconfig" <<'CFG'
[user]
	name = Lab User
	email = lab.user@personal.example
[init]
	defaultBranch = main
[gc]
	reflogExpire = never
	reflogExpireUnreachable = never
[includeIf "gitdir:~/work/"]
	path = ~/.gitconfig-wrok
CFG
printf '[user]\n\temail = lab.user@corp.example\n' > "$H/.gitconfig-work"

export GIT_AUTHOR_NAME="Lab User" GIT_COMMITTER_NAME="Lab User"
mk() {   # mk <directory> <email> <file> <message>...: a repository whose commits carry <email>
  local d="$1" e="$2"; shift 2
  quiet "git init $d"
  export GIT_AUTHOR_EMAIL="$e" GIT_COMMITTER_EMAIL="$e"
  ( cd "$d" && printf 'placeholder\n' > "$1" && git add "$1" && git commit -q -m "$2" ) ; tick
  ( cd "$d" && printf 'placeholder\nmore\n' > "$1" && git commit -q -am "$3" ) ; tick
}
mk "$H/work/billing-llm" lab.user@personal.example prompts.txt 'Add invoice prompts' 'Add dunning prompt'
mk "$H/work/invoice-ocr" intern@corp.example ocr.py 'Add OCR client' 'Retry OCR on timeout'
mk "$H/oss/dotfiles" lab.user@personal.example zshrc 'Add zshrc' 'Add git aliases'
# The second cause: a repository-local address, left by whoever set this clone up.
git -C "$H/work/invoice-ocr" config set user.email intern@corp.example
ex_note billing_parent "$(git -C "$H/work/billing-llm" rev-parse HEAD~1)"
ex_note ocr_parent "$(git -C "$H/work/invoice-ocr" rev-parse HEAD~1)"
ex_note dotfiles_tip "$(git -C "$H/oss/dotfiles" rev-parse HEAD)"

ex_end
[ -n "${LAB_REPLAY:-}" ] || printf 'Exercise ready. Open a lab shell there:\n  labs/shell "%s"\n' "$LAB_DIR"
