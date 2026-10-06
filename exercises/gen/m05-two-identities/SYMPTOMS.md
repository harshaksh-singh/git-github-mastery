# Exercise 5.9: what was reported

**Sandbox:** a home directory, `home/`, with the global configuration `home/.gitconfig`, two work repositories (`home/work/billing-llm`, `home/work/invoice-ocr`) and one personal repository (`home/oss/dotfiles`).

**First step, as in every exercise of this module.** After `labs/shell "<sandbox path>"`, move into the sandbox's home so that `~` and `git config --global` mean the sandbox:

```bash
export HOME="$PWD/home"
export GIT_CONFIG_GLOBAL="$HOME/.gitconfig" XDG_CONFIG_HOME="$HOME/.config"
```

You, after the company's server rejected two pushes:

> The server only accepts commits whose author and committer address is my company address, `lab.user@corp.example`. It rejected my last commit in `billing-llm` because it carries my personal address, and my last commit in `invoice-ocr` because it carries `intern@corp.example`, which is not even mine. The earlier commit in each repository was accepted long ago, before the rule existed, and must stay as it is.
>
> I set this laptop up from the handbook months ago: one conditional include that gives everything under `~/work/` the company address. `cat ~/.gitconfig-work` shows the right address. My personal projects under `~/oss/` must keep the personal address.

What you are asked for: find every reason why a work repository does not use the company address and remove each one at its source, so that a new repository created under `~/work/` tomorrow is right without any further step. Then correct the last commit of each work repository (author and committer address) and leave the older commits untouched.

When you think you are done, run `exercises/gen/m05-two-identities/check.sh` from the course root.
