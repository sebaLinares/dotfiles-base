---
id: fragments-self-locate
owner: dotfiles-base
status: accepted
last_reviewed: 2026-08-14
update_trigger: on-supersession
---

# ADR fragments-self-locate — No clone path is ever hardcoded

## Status

Accepted.

## Context

Every repo here is installed by symlinking files into `$HOME`, so a shell
fragment executes from `~/.config/dotfiles/<domain>.zsh` while the files it
wants to source — its own `.aliases` — sit next to the *original* in the clone.

The first implementation resolved that by hardcoding the clone path:

```zsh
source ~/Documents/.dotfiles/.aliases
```

That pins every clone to one directory on one machine. Moving a clone, or
cloning to a different path on a new machine, breaks the shell — and breaks it
at the sourcing step, where the error is a `404` print rather than a failure.
The same problem applied to domain installers finding base's `lib/`.

## Decision

Nothing committed hardcodes a clone path.

**Shell fragments self-locate** by resolving their own symlink back to the
repository:

```zsh
DOMAIN_DIR="${${(%):-%x}:A:h}"   # this file's path, symlink resolved, dirname
source "$DOMAIN_DIR/.aliases"
unset DOMAIN_DIR
```

`%x` is the file being sourced; `:A` resolves symlinks to an absolute path;
`:h` takes the directory. Base's own `.zshrc` uses the same form for its
`.aliases`.

**Installers locate base** through `~/.config/dotfiles/base.env`, which base's
`install.sh` rewrites with its resolved `REPO_DIR` on every run. Domain
installers source it, verify `$DOTFILES_BASE/lib/install-common.sh` exists, and
abort with a clear message otherwise.

Aliases that point at a personal checkout (`godotfiles`, editor shortcuts) are
domain-repo content and are exempt — they are per-identity by nature, and
`doctor.sh` check 5 verifies their targets still exist.

## Consequences

- **MUST NOT** introduce a literal clone path into committed shell code. A
  hardcoded `~/Documents/.dotfiles*` is a bug.
- **MUST** re-run base's `install.sh` after moving the base clone, so `base.env`
  is rewritten. `doctor.sh` check 2 detects a stale one.
- Clones may live anywhere, and a new machine may use a different layout.
- The `${${(%):-%x}:A:h}` idiom is zsh-specific and cryptic. That is the reason
  this ADR exists: the incantation is not self-explanatory at the call site.
