---
id: doctor-reports-never-mutates
owner: dotfiles-base
status: accepted
last_reviewed: 2026-08-14
update_trigger: on-supersession
---

# ADR doctor-reports-never-mutates — One sensor, advisory, run by hand

## Status

Accepted.

## Context

This system's defects share a shape: **invisible on the machine that introduced
them, breaking only on the next one.** A dangling symlink, a stale `base.env`, an
alias defined in two domain repos, an alias pointing at a deleted file, a
`core.excludesFile` shadowing the global excludes — none of these break the
machine where the change was made. They surface on a fresh install, months
later, with no obvious cause.

That is a feedback problem, and feedback needs a sensor. But this repo has no
build, no test suite, and no CI, and a general-purpose harness sensor — a
plan-coverage check gating commits against an ExecPlan's declared file list —
would gate an empty set here: there is no code for a plan to cover.

Two further constraints shaped the form:

- The checks are inherently **machine-local**: they inspect `$HOME`, installed
  symlinks, and global git config. CI cannot run them meaningfully.
- Several findings are ambiguous. `core.excludesFile` may have been set
  deliberately; a missing alias target may mean a project was archived on
  purpose. Auto-fixing would destroy state the human wanted.

## Decision

`doctor.sh` is this repo's only mechanical sensor, and it is **advisory**:

- It **reports and exits nonzero**. It never creates, moves, deletes, or edits
  anything, and never changes git config.
- It is **not installed** — no symlink into `$HOME`, no entry in `install.sh`.
  It runs from the clone: `~/…/.dotfiles-base/doctor.sh`.
- It is **not hooked** — no pre-commit, no shell startup, no CI. Startup cost
  and false alarms on a machine mid-setup are not worth the automation.
- It checks the seams, not the content: symlinks resolve and base owns its
  files; `base.env` exists and matches this clone; domain repos are reachable;
  no alias name is defined in two repos; no alias points at a missing file
  inside a repo; `core.excludesFile` is unset.
- Convention is that it runs after any seam change and after adding a domain.
  `AGENTS.md` states this as a MUST for agents; for humans it is a habit.

This repo therefore does **not** adopt the `init-harness` skill layout: no
ExecPlan contract, no `covers:` frontmatter, no `check_plan_coverage.py`, and
no `.harness-version` marker.

## Consequences

- **MUST NOT** add mutation, installation, or hook wiring to `doctor.sh`. A fix
  it suggests is applied by a human who read the reason.
- **MUST** extend `doctor.sh` when a new seam is added — a seam with no check is
  the next silent defect.
- **MUST NOT** run `/init-harness` in this repo, and **MUST NOT** let it "adopt"
  the repo: with harness-shaped files present and no `.harness-version`, the
  skill assumes a `1.0.0` baseline and re-adds what was dropped deliberately.
- Nothing forces the check to run. A seam can break unnoticed until the next
  machine — the exact failure this addresses. Accepted: the alternative is a
  gate that fires on every commit in a repo where most commits are one alias.
- Checks are additive and cheap; the script stays a single dependency-free bash
  file so it runs on a machine that has nothing else installed yet.
