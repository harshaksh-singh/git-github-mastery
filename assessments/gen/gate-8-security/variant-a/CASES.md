# Gate 8, hands-on, variant A: three cases to diagnose

Everything in this directory was constructed for the gate. The workflow file parses as YAML and is insecure on purpose; it is teaching material and must never be run. Every "secret" in the transcripts is an obvious dummy. The Git transcripts are real output of `labs/gates/g8-evidence.sh`, in which a bare repository plays the server. Nothing was run on GitHub.

This gate is defensive. You are asked to find weaknesses, explain the mechanism at the level the textbook does, and repair them. You are not asked to write an exploit, and an answer that contains one earns nothing extra.

## Case 1 (12 points): review this workflow before it is merged

**File:** [`preview-docs.yml`](preview-docs.yml). The repository is public and receives pull requests from forks. A colleague opened a pull request that adds this workflow, with the description: "Builds a documentation preview for every pull request, including forks, and uploads it. Uses `pull_request_target` because fork pull requests do not get the secret otherwise."

**Your task.** Review it with the checklist of Chapter 21A, section 21A.19. List the findings in order of severity. For each: the lines, what an outsider controls, what that reaches (token, secret, machine), and the repair. Then describe, in outline and without writing the full YAML, a design that gives fork pull requests a documentation preview without any of the findings. State which single line of the file should have stopped the reviewer first, and why it was put there.

## Case 2 (9 points): a key in a settings file

Wednesday, 16:10. A scanner reports a storage account key in the repository `acme-pay/uploader`, which has been public since Monday. Ravi answers within a minute: "Already handled. I deleted that file this morning and pushed. The key is not in the repository any more."

What you find in a fresh clone:

<!-- snippet: gates/g8-evidence/a2-evidence -->
```text
$ git grep -c 'STORAGE_KEY' HEAD || echo 'no match in the tip of main'
no match in the tip of main
$ git log --all --format='%h %an: %s' -S'dummy-storage-key'
fb5a484 Ravi Menon: Remove settings file, use the vault
80297d2 Ravi Menon: Add deployment settings
$ git for-each-ref --format='%(refname)' --contains "$(git log --all --format=%H -S'dummy-storage-key' | tail -1)"
refs/heads/feature/resume
refs/heads/main
refs/remotes/origin/feature/resume
refs/remotes/origin/main
refs/tags/v0.5.0
$ git ls-remote origin
fb5a4848354c28af4731c8f44a425b2818ef6e6b	HEAD
b04e9024a1a9e248f859b27a564c532199e0cf89	refs/heads/feature/resume
fb5a4848354c28af4731c8f44a425b2818ef6e6b	refs/heads/main
3a906d2a93063de53807c548b97c3fa5baa0bc99	refs/tags/v0.4.0
d2950d62efad00f3c72ab95013d16a6f9ce1df09	refs/tags/v0.4.0^{}
4c485c9623700015b19f6e7d564898a7f19dae80	refs/tags/v0.5.0
baeed0fbb21e2ce943454bbd21ba6f5b2703c330	refs/tags/v0.5.0^{}
$ for r in main v0.4.0 v0.5.0 feature/resume; do git cat-file -e "$r:deploy/settings.env" 2>/dev/null && echo "$r: the tree has deploy/settings.env" || echo "$r: not in the tree"; done
main: not in the tree
v0.4.0: not in the tree
v0.5.0: the tree has deploy/settings.env
feature/resume: the tree has deploy/settings.env
```
<!-- /snippet -->

**Your task.**

1. Say what the evidence shows: in which commits the key is, which refs reach them, and what Ravi's commit changed and did not change. Is the key "in the repository"?
2. Write the response as an ordered list of actions for the next two hours, with the owner of each action and the evidence that it is done. Put the first action first and say why it is first.
3. Decide whether a history rewrite is warranted here, and give the argument for and against. If the team rewrites: name every ref that must be rewritten or deleted, and what happens to the commit IDs, to the two release tags and to open pull requests.
4. Name three places outside this repository where the key may still be, which no Git command of yours can reach.

## Case 3 (9 points): the next morning

The team rotated the key and rewrote `main` on Wednesday evening. On Thursday at 09:00 the scanner reports the same key on `main` again. After a fetch, your clone shows:

<!-- snippet: gates/g8-evidence/a3-evidence -->
```text
# The day after the clean-up, in your clone, after a fetch:
$ git log --graph --format='%h %an: %s' origin/main
*   13b67b0 Asha Rao: Merge branch 'main' of ../server
|\  
| * 15e86fc Lab User: Retry uploads
* | 6b5f798 Asha Rao: Add README
* | fb5a484 Ravi Menon: Remove settings file, use the vault
* | baeed0f Lab User: Retry uploads
* | 80297d2 Ravi Menon: Add deployment settings
|/  
* d2950d6 Lab User: Add uploader
$ git log --format='%h %s' -S'dummy-storage-key' origin/main
fb5a484 Remove settings file, use the vault
80297d2 Add deployment settings
$ git log -1 --format='%h parents: %p' origin/main
13b67b0 parents: 6b5f798 15e86fc
$ git reflog show origin/main --format="%h %gs"
13b67b0 fetch origin: fast-forward
15e86fc update by push
fb5a484 update by push
```
<!-- /snippet -->

**Your task.** Explain what happened, from the graph and the reflog of `origin/main`: who pushed what, and why the server accepted it although force pushes to `main` are blocked. Say what is at risk now, given Wednesday's actions. Give the repair as an ordered list, including what happens to Asha's commit and to Asha's clone, and the exact kind of command that must not be used to bring her clone up to date. Then name two controls, one of process and one on the server, that would have prevented it.
