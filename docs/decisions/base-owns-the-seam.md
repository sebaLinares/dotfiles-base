---
id: base-owns-the-seam
owner: dotfiles-base
status: accepted
last_reviewed: 2026-08-14
update_trigger: on-supersession
---

# ADR base-owns-the-seam — Base owns the shared code and extension points

## Status

Accepted.

## Context

With base and domain repos split ([ADR split-not-monorepo](split-not-monorepo.md)),
work that belongs to *neither* repo alone has no natural home, and defects
accumulate there unseen:

- The `link()` install helper existed as three byte-identical copies, one per
  repo, with no owner. Any fix had to be applied three times.
- The document describing the whole architecture lived in the *personal* repo.
  The corporate laptop clones base and work only — so the document explaining
  the system was absent from a machine running it.
- Two aliases were defined in two different domain repos. Fragments load
  lexically, so one silently overrode the other, on one machine, with no error.

Every one of these lives *between* the repos. A per-repo convention cannot fix
them, because no repo can see the others.

## Decision

Base owns the seam. Concretely, base owns:

- **`lib/install-common.sh`** — the shared `link()` helper. Sourced by every
  domain installer, never copied.
- **`~/.config/dotfiles/base.env`** — written by base's `install.sh` on every
  run, recording this clone's resolved path so domains can find `lib/`.
- **`~/.config/dotfiles/`** — the fragment extension point. Base's `.zshrc`
  sources `*.zsh` there in lexical order; base never names a fragment.
- **`~/.ssh/config.d/`** and the `Include` line — domains drop a `.conf` in.
- **`~/.zshrc`, `~/.tmux.conf`, `~/.config/git/ignore`** — symlinked outright;
  base is the only repo that touches them.
- **`~/.config/herdr/config.toml`** — generic Herdr preferences; plugin state
  remains machine-specific.
- **`.aliases`** — aliases generic enough to belong on any machine.
- **`docs/architecture.md`** and `docs/decisions/` — the cross-repo contract.
- **`doctor.sh`** — the checks over all of the above.

Domain repos own their fragment, their aliases, their SSH stanza, and their own
`README.md` documenting their remote and identity — nothing else.

## Consequences

- **MUST NOT** copy shared install code into a domain repo. Source it from
  `$DOTFILES_BASE/lib/`.
- **MUST NOT** document the cross-repo architecture anywhere but base — a
  machine that doesn't clone that domain will not have it.
- **MUST** keep base's ownership generic: owning the seam does not license
  naming a domain. See [ADR base-is-public](base-is-public.md).
- Domain installers gain a hard dependency on base at install time, and fail
  loudly without it. This is the point: "run base first" becomes enforced rather
  than a comment in a README.
- A stale `base.env` (base clone moved, not reinstalled) breaks domain installs.
  `doctor.sh` check 2 detects this.
