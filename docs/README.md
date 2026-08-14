---
owner: dotfiles-base
status: stable
last_reviewed: 2026-08-14
update_trigger: on-doc-added
---

# Docs Catalog

Entry point for agent context. Read this before any task requiring repo
knowledge. When you add a doc, add a one-line entry to the matching section.

---

## Repo-root anchors

- [`/AGENTS.md`](../AGENTS.md) — agent entry point: operating principle, hard
  constraints, session bootstrap, harness scope. `CLAUDE.md` symlinks to it.

## Architecture

- [Architecture](architecture.md) — what base owns, how domain repos plug in
  (shell fragments, install lib, SSH, git identity), and what `doctor.sh`
  checks. The single map; extend it rather than adding a second.

## Decisions

Architecture Decision Records — *why* the system is the way it is. Identified by
`id:` slug, which is also the filename stem: no numeric prefixes in filenames or
prose. Reference as `ADR <slug>` and `decisions/<slug>.md`.

- [ADR split-not-monorepo](decisions/split-not-monorepo.md) — base plus N domain
  repos rather than one repo; publication, identity, and machine-scope forces;
  HTTPS for base, SSH for domains.
- [ADR base-owns-the-seam](decisions/base-owns-the-seam.md) — the shared install
  lib, `base.env`, the fragment and SSH extension points, and the cross-repo
  docs all live in base.
- [ADR base-is-public](decisions/base-is-public.md) — base is published and
  carries no identity; what may never land here.
- [ADR fragments-self-locate](decisions/fragments-self-locate.md) — no clone path
  is ever hardcoded; fragments resolve their own symlink, installers read
  `base.env`.
- [ADR doctor-reports-never-mutates](decisions/doctor-reports-never-mutates.md) —
  one advisory sensor, run by hand; why this repo does not adopt `init-harness`.

## Domain repos

Personal, work, and any future domain are **separate repos** with their own
remotes and identities, cloned only where needed. Each carries its own
`README.md` (remote, identity, install) and a short `AGENTS.md` stub pointing
back here. Base does not name them — see
[ADR base-is-public](decisions/base-is-public.md).
