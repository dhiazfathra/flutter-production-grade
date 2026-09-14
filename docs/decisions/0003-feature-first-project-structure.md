# ADR-0003: Feature-first project structure

## Status

Accepted

## Date

2026-09-13

## Context

The architecture skill (and the official Compass sample) groups code layer-first: top-level
`data/`, `domain/`, `ui/` directories, with only the UI grouped by feature. Sample apps with two
or three features read well that way; the layout degrades as feature count grows, because one
feature's code ends up split across three distant trees.

## Decision

Group by feature first, then by layer inside each feature:
`lib/features/<feature>/{data,domain,ui}`. Cross-feature code lives in `lib/core/` with the same
internal layer split. Features never import each other.

## Alternatives Considered

### Layer-first, as the skill specifies

- Pros: literal skill compliance; matches the official sample.
- Cons: a feature's repository, model, and screens sit in three unrelated directories; deleting a
  feature means touching every top-level tree.
- Rejected by explicit project-owner decision after both options were compared.

### Melos monorepo, one package per feature

- Pros: boundaries enforced by the compiler.
- Cons: five pubspecs, bootstrap step, slower codegen, heavier CI.
- Rejected: lint-enforced boundaries are sufficient at this size.

## Consequences

- Deliberate deviation from the skill's directory diagram. The layer names, responsibilities, and
  dependency direction are kept exactly; only the grouping axis differs.
- The layer rule (`ui -> domain <- data`, no feature-to-feature imports) is enforced by import
  lint rules, not by package boundaries, so the lint configuration is load-bearing.
- Adding a feature is one new directory; deleting one is one `rm -r` plus a route entry.
