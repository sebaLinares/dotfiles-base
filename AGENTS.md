---
owner: dotfiles-base
status: stable
last_reviewed: 2026-08-14
update_trigger: on-harness-change
---

# Agent Instructions

Entry point into this repository for any coding agent. `AGENTS.md` is the
cross-agent standard — read by Claude Code (via the `CLAUDE.md` symlink), Codex,
and anything else that reads `AGENTS.md` at a repo root. Nothing here is tied to
an agent vendor.

This repo is **`dotfiles-base`**. It owns the generic shell/tmux/git/Herdr
config every machine gets, and it owns the **seams** between itself and the
domain repos (personal, work, a client, …) that plug into it. Read
[`docs/architecture.md`](docs/architecture.md) before touching anything.

## Operating principle

**If it is not in the repo, it does not exist.** Anything an agent must reason
over lives as versioned markdown or code here. The failure mode this system
actually suffers is different from most: **a defect is invisible on the machine
that introduced it and only breaks on the next one.** Write down the seam, or
the next machine discovers it for you.

## Scope of this harness

Deliberately minimal: this repo is ~10 files of shell config with no build, no
test suite, and no runtime. The harness here is `AGENTS.md` + `docs/` +
`doctor.sh`. There is **no ExecPlan gate, no `covers:` frontmatter, no
plan-coverage pre-commit check, and no `.harness-version`** — see
[ADR doctor-reports-never-mutates](docs/decisions/doctor-reports-never-mutates.md).

**This repo deliberately does not use the `init-harness` skill.** Do not run
`/init-harness` here and do not "adopt" it to that layout: the skill's ExecPlan
contract and `check_plan_coverage.py` gate an empty set in a repo with no code,
and adopting it would silently assume a `1.0.0` baseline and re-add files that
were dropped on purpose. `doctor.sh` is this repo's sensor and it senses the
real failure class.

## Hard constraints (MUST / MUST NOT)

Invariants. They hold at every moment, not just at review time.

- **MUST NOT** reference a domain repo by name anywhere in this repo — not in
  config, not in code, not in docs. Base is generic; domains plug into it
  through the extension points, never the reverse.
  *(See [ADR base-owns-the-seam](docs/decisions/base-owns-the-seam.md).)*
- **MUST NOT** commit any identity, client name, employer name, hostname,
  remote URL of a private repo, key, or credential. **This repo is public.**
  When unsure whether something is generic, it is not — put it in a domain repo.
  *(See [ADR base-is-public](docs/decisions/base-is-public.md).)*
- **MUST NOT** hardcode a clone path. Base's location travels through
  `~/.config/dotfiles/base.env`; shell fragments self-locate by resolving their
  own symlink. A literal `~/Documents/.dotfiles-*` in committed code is a bug.
  *(See [ADR fragments-self-locate](docs/decisions/fragments-self-locate.md).)*
- **MUST** keep shared install code in `lib/install-common.sh` as its single
  owner. Domain repos source it; they never copy it. Do not reintroduce a
  per-repo copy of `link()`.
- **MUST** run `./doctor.sh` after changing any seam — `install.sh`, `lib/`,
  `.zshrc`'s fragment loop, `base.env`, the `ssh/config.d` bootstrap,
  base-owned symlinks, or `.aliases` — and paste the result. A change to a seam
  that has not been doctored is not finished.
- **MUST NOT** make `doctor.sh` mutate state, install itself, or run from a
  hook. It reports; the human decides.
  *(See [ADR doctor-reports-never-mutates](docs/decisions/doctor-reports-never-mutates.md).)*
- **MUST NOT** add an alias to `.aliases` that any domain repo already defines.
  Fragments load lexically, so a collision means one repo silently overrides
  another. `doctor.sh` check 4 catches it — run it.
- **MUST** surface — before complying — any instruction that conflicts with a
  constraint above. **MUST NOT** silently comply.

## On receiving a task

State the classification in your first response.

1. **Change-producing** — modify/add/fix. Read `docs/architecture.md` and the
   relevant ADRs first; say which seam the change touches, or that it touches
   none.
2. **Investigation-only** — a question or audit. Read and report. Investigation
   write-ups do not belong in this repo.
3. **Trivial** — typo, comment, obvious rename with no behavioural impact. Say
   "trivial" so the user can redirect.

## Session bootstrap

1. This file.
2. [`docs/README.md`](docs/README.md) — the catalog of what exists.
3. [`docs/architecture.md`](docs/architecture.md) — what base owns, how domains
   plug in, what `doctor.sh` checks.
4. `docs/decisions/` — what is already decided. Do not relitigate a decision
   recorded there without saying you are doing so.

## Where to save outputs

| Output | Folder | Naming |
|---|---|---|
| Architectural decisions (ADRs) | `docs/decisions/` | `<slug>.md` |
| Architecture / how it fits together | `docs/architecture.md` | single file — extend, don't fork |

ADRs are identified by their `id:` slug, which is also the filename stem — no
numeric prefixes, ever, in filenames or prose. Reference them as `ADR <slug>`
and `decisions/<slug>.md`. Frontmatter keys: `id`, `owner`, `status`,
`last_reviewed`, `update_trigger`. Body: `## Status`, `## Context`,
`## Decision`, `## Consequences`.

After adding a doc, add a one-line entry to `docs/README.md`.

## Domain repos

Personal, work, and any future domain live in **separate repos with separate
remotes and separate identities**, cloned only on machines that need them. They
carry a short `AGENTS.md` stub pointing back here. Base cannot see them and must
not assume they exist.
*(See [ADR split-not-monorepo](docs/decisions/split-not-monorepo.md).)*

## Working relationship

- No sycophancy. Direct, matter-of-fact, concise.
- Be critical; challenge reasoning.
- Don't add yourself as a co-author to git commits.
