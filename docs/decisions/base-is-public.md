---
id: base-is-public
owner: dotfiles-base
status: accepted
last_reviewed: 2026-08-14
update_trigger: on-supersession
---

# ADR base-is-public — Base is published and carries no identity

## Status

Accepted.

## Context

Base must be cloneable on any machine, including a corporate laptop, with no
credential and no SSH key. That argues for publishing it. Publishing, in turn,
constrains what may ever land in it — and the constraint is easy to violate by
accident, because the natural place to put "one small thing" is wherever you are
already editing.

The pressure is real: base owns the seam ([ADR base-owns-the-seam](base-owns-the-seam.md)),
so it is where cross-repo work goes, and cross-repo work is exactly where a
domain's name wants to appear.

## Decision

Base is a public repository. It contains **no** identity of any kind:

- no personal or employer name, no client name, no colleague name
- no email address, username, or account handle
- no remote URL of a private repository, no internal hostname, cluster name,
  AWS profile, or account number
- no key, credential, or token — public or private
- no path that only exists on one person's machine
- no name of a domain repo, in config, code, or prose

Documentation in base refers to domains generically ("a domain repo", "domain
A"). Each domain repo documents its own remote, identity, and install steps in
its own `README.md` — which also puts that documentation on the machines that
actually run it.

The test for a candidate addition: *would this be equally true and equally
useful for a stranger who has never heard of any of my employers?* If not, it
belongs in a domain repo.

## Consequences

- **MUST** treat anything identity-bearing as belonging to a domain repo, and
  when uncertain, treat it as identity-bearing.
- **MUST** keep base cloneable over HTTPS with no auth — no submodules pointing
  at private remotes, no install step requiring a key.
- Some duplication between domain repos is accepted rather than hoisting a
  shared-but-identifying value into base.
- Git history is public too. A secret committed and then removed is still
  disclosed and must be rotated, not just deleted.
- Base cannot mechanically verify this property; it is a review-time constraint
  stated in `AGENTS.md`. Accepted — the alternative is a secret scanner in a
  repo with no CI.
