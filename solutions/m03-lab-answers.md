# Module 3 lab answers: Commits

Answers to the Questions in [lab-manual/m03-commits.md](../lab-manual/m03-commits.md). Read them after you have written your own. The IDs quoted here are the ones printed by the replay scripts; where your own run produced other IDs, the reasoning is the same.

## Lab 3.1: Amend a commit and find the old one

1. **Two.** `f17f3d5 Add F1 metrc` and `575b500 Add F1 metric` are separate commit objects with the same parent `d4c9fab`. `refs/heads/main` and therefore HEAD point at `575b500`. Nothing under `refs/` points at `f17f3d5`; it is named only by reflog entries, `HEAD@{1}` in `.git/logs/HEAD` and `main@{1}` in `.git/logs/refs/heads/main`. After the failure scenario and the recovery there are four such objects, three of them dangling.

2. **The author date.** `git commit --amend` copies the `author` line of the commit it replaces, name, email and timestamp, and writes a fresh `committer` line. The summary shows the author date whenever it differs from the committer date, which after an amend it always does. `git log -1 --format=fuller` prints both: `AuthorDate` is 10:04, `CommitDate` is the time of the amend.

3. **Because the reflog counts as a reference for `git fsck`.** By default `fsck` treats every object that a reflog entry points at as reachable, so the old commit is not reported. `--no-reflogs` tells it to ignore reflog entries, and then the old commit has no referrer and is "dangling". The option exists for exactly this question: which commits used to be on a ref and are now held only by a reflog.

4. **`--soft` moves the branch and leaves the index and working tree alone**, so everything the bad commit contained is still staged and can be sorted out with `git restore --staged`. `--mixed` would also have reset the index to the restored commit, leaving `evalkit/bleu.py` and the new test as unstaged changes in the working tree: recoverable, but with more re-staging to do. `--hard` would have reset index and working tree to the restored commit, deleting `evalkit/bleu.py` from disk and discarding the new test; the content would survive only as objects in the database, because `git add` had stored the blobs, and finding them again would need `git fsck --lost-found`.

5. **`git reflog expire --expire=now --all` removes every reflog entry**, so nothing refers to the three dangling commits any more. **`git gc --prune=now` then deletes unreachable objects immediately**, without the two-week grace period, as part of repacking. Together they are the documented way to make deletion final. During an incident you need the opposite: the reflog is the record of where every ref was, and the dangling objects are often the data you are trying to recover. The `git gc` manual also warns that pruning immediately can corrupt the repository if another process is writing to it at the same time.

## Lab 3.2: Change only the committer date and watch the ID change

1. **Kept:** `tree`, `parent`, `author` (name, email, timestamp and offset) and the message. **Rewritten:** the `committer` line, with the current identity and the current time. The committer identity happened to be the same, so in step 3 `diff` showed exactly one differing line, the committer timestamp.

2. **Because the ID is a function of the object's bytes and nothing else.** In step 4 both amends had the same tree, parent, author, message and committer line including the pinned date, so Git computed the same hash and found the object already in the database. In steps 2 and the failure scenario the committer date was the current second on your machine, so the bytes differed from every earlier version and from the book.

3. **No. Nothing was undone; a commit with the same content was created again, or rather found again.** `git commit --amend` built an object from the current index, the parent, the preserved author line and the committer line with the restored date. That object is byte for byte the original commit, so its ID is the original ID. The reflog says what happened: `main` moved from the original to `92602dd`, to `5e292d6` twice, and back to `1f9c5d8`, one entry per amend.

4. `git diff --quiet "$deployed" HEAD` compared the **trees** of the two commits and found them identical (exit 0). `git merge-base --is-ancestor "$deployed" HEAD` asked whether the deployed **commit** is in the history of HEAD, by following parent links, and found that it is not (exit 1): the two commits are siblings, not ancestor and descendant.

5. **Both, for different purposes.** Comparing trees (`git rev-parse <a>^{tree} <b>^{tree}`) proves that the content is identical, which is what a reviewer approved. Comparing IDs proves that the very same commit object is being deployed: the same content, the same parents and therefore the same history, the same author and committer lines and the same message. A pipeline that deploys only the approved ID protects against a rewritten history slipping in under identical content; a check that compares trees lets you recognise a harmless rewrite (an amended message) for what it is. The strict rule is to require the approved ID and to re-approve anything else, with the tree comparison as the first step of that re-approval.

## Lab 3.3: Trailers

1. **From the committer identity**, which in the lab shell comes from `user.name` and `user.email` in the isolated configuration; the environment variables would take precedence if set. The manual says `-s` adds "a Signed-off-by trailer by the committer". By itself the line certifies nothing: its meaning is defined by the project that receives the commit, most often the Developer Certificate of Origin. It is plain text that anyone can type, not a cryptographic signature.

2. **The rule:** a trailer block is a group of lines at the end of the message, preceded by an empty line, in which every line is a trailer, or at least a quarter of the lines are trailers and one of them has a Git-generated or configured key. In the failure scenario the last paragraph was prose, so the block containing `Refs:` was not last. Another layout that fails: the trailer directly under the title with no empty line between them, because the title paragraph then contains a non-trailer line. A third: `Refs: EVAL-240` followed on the next line by an ordinary sentence in the same paragraph, when `Refs` is neither configured nor Git-generated.

3. **Because the alias is configuration, not content.** `trailer.ticket.key` lives in `.git/config` of your clone. `--trailer 'ticket=EVAL-230'` was expanded on your machine and the commit message received `Refs: EVAL-230`. A colleague without that configuration gets no expansion: `git commit --trailer 'ticket=EVAL-250'` writes the line `ticket: EVAL-250`, which the report, which looks for `Refs`, does not find. Team-wide aliases need a shared way to install them, or the team writes the full key.

4. **`6eab4a9 Add README`.** It has no `Refs` trailer, and the manual states that "commits that do not include the trailer will not be counted". The grouping is also case-insensitive, which is why `--group=trailer:refs` matched the key `Refs`.

5. **GitHub attributes the commit to the co-author as well as to the author**: the commit counts as a contribution for both and is shown with both. A name in the body is text that GitHub does not interpret. For the attribution to work, the email address in the trailer must be an address associated with the co-author's GitHub account, or their GitHub-provided `noreply` address if they keep their email private. Git itself does nothing with the trailer beyond storing it and, on request, parsing it.
