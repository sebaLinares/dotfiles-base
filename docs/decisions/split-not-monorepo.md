---
id: split-not-monorepo
owner: dotfiles-base
status: accepted
last_reviewed: 2026-08-14
update_trigger: on-supersession
---

# ADR split-not-monorepo — Base plus domain repos, not one repo

## Status

Accepted.

## Context

Dotfiles started as a single repo owning the full `.zshrc`/`.tmux.conf`,
duplicated with drift into a second repo for employer-specific config. Three
forces make one repo untenable:

- **Publication.** The generic shell config is worth publishing. Employer config
  is not: it carries cluster names, AWS profile names, and internal repository
  names. One repo forces the whole thing private, or leaks.
- **Identity.** Each domain commits under a different git identity, resolved by
  `includeIf` on the clone path. One repo collapses them into one identity.
- **Machine scope.** A corporate laptop should never have personal SSH config on
  disk, and a personal machine should be able to take on employer config
  temporarily and then remove it cleanly. That is a property of *what is
  cloned*, which one repo cannot express.

The considered alternative — one repo with submodules or sparse-checkout —
reintroduces the split with more machinery and a worse failure mode.

## Decision

One **base** repo plus N **domain** repos.

- **Base** (this repo) is public, carries no identity, and owns the generic
  config and the seams. It is cloned on every machine, first, always.
- **Each domain** is a separate repo with its own remote and identity, holding
  only what is specific to that identity: a shell fragment, aliases, an SSH
  config stanza. A machine clones the domains it needs and nothing else.
- Domains depend on base; base never depends on a domain and never names one.
  The arrow points one way.
- Removing a domain is deleting its clone and its symlinks. Nothing in base or
  another domain is touched.

**Clone protocol:** base over **HTTPS** — it is public, so this needs no key and
no SSH `Host` alias, and it avoids putting a personal key on a corporate
machine. Domains over **SSH**, since they are private and identity-bound.

## Consequences

- **MUST** clone and install base before any domain. Domain installers fail
  loudly when base is absent rather than half-working.
- **MUST NOT** move content between base and a domain without re-checking the
  publication rule in [ADR base-is-public](base-is-public.md).
- Cross-repo concerns — the install helper, the fragment contract, the alias
  namespace, this architecture — have exactly one home: base. Anything living in
  a domain repo that describes the whole system is misplaced, because the other
  machines never clone that domain.
- Adding a domain requires no change to base.
- Cost: a change spanning base and a domain is two commits in two repos, and
  cannot be atomic. Accepted — such changes are rare, and `doctor.sh` catches
  the resulting seam breakage.
