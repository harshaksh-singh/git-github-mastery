# Exercise 16.9: what was reported

**Project:** `shardmap`. **Sandbox:** one repository, `shardmap/`, on `main`. Generate it with `exercises/gen/m16-shardmap/generate.sh`. This repository has no remote: think of it as the copy that is about to be published.

From the platform channel:

> Last week we rebuilt `main` so that `data/shards.bin`, a 600,000-byte debugging dump, is no longer in its history. `git log main -- data/shards.bin` shows nothing, `git ls-files` does not list it, and we ran `git gc` afterwards.
>
> The `.git` directory is as large as before. `git count-objects -v` still reports a `size-pack` that three small text files cannot explain. The dump must not go out with this repository.

What you are asked for:

1. Find every thing in this repository that still keeps the dump's blob alive, and name each one.
2. Remove them, so that the blob no longer exists in the object database. `main` and the tag `v1.0.0` stay exactly as they are. Work that is parked somewhere on the old history may be discarded, but first say what it is.
3. Prove that the blob is gone, and that the repository is intact.

This exercise ends with commands that cannot be undone. That is the point of it. Know what each one deletes before you run it.

When you think you are done, run `exercises/gen/m16-shardmap/check.sh` from the course root.
