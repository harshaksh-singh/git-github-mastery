# Exercise 18.9: what was reported

**Project:** `searchstack`, a monorepo. **Sandbox:** `server.git` (the server) and `build/` (the clone on the build machine). Generate it with `exercises/gen/m18-searchstack/generate.sh`. The clone talks to the server through a `file://` URL, which makes Git use the same transfer protocol as over the network.

From the release engineer:

> The build machine has had its clone of `searchstack` for months; whoever set it up has left. Today I need to build the 0.2 maintenance line there and stamp the build with `git describe`.
>
> `git switch release/0.2` says `fatal: invalid reference: release/0.2`. The branch exists on the server, I can see it from my laptop.
> `git describe` says `fatal: No names found, cannot describe anything.` The tags exist on the server too.
> `git log` shows one commit.
> `git fetch` prints nothing and exits with 0, so the clone believes that it is up to date.
>
> I do not want to delete the clone: the build cache next to it is keyed on its path.

What you are asked for:

1. Explain each of the three symptoms from the clone's configuration and files, without looking at how it was created.
2. Turn `build/` into a complete clone in place: full history, every branch of the server as a remote-tracking branch, every tag, and a configuration under which a plain `git fetch` keeps it complete from now on.
3. Afterwards `git switch release/0.2` works and `git describe` on `main` prints what it prints on the server.

When you think you are done, run `exercises/gen/m18-searchstack/check.sh` from the course root.
