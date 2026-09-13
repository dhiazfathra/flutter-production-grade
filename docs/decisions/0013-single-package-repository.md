# ADR-0013: One package, no monorepo tooling

## Status

Accepted

## Date

2026-09-13

## Context

A scaffold can either be a single Flutter package or a melos-managed monorepo with a package per
feature and a shared core.

## Decision

A single Flutter package. Boundaries between features and layers are enforced by import lint
rules. One `pubspec.yaml`, one `build_runner` invocation, one test command.

## Alternatives Considered

### Melos monorepo

- Pros: the compiler enforces boundaries; features are independently versionable.
- Cons: five pubspecs, a bootstrap step before anything runs, slower codegen, a larger CI matrix.
- Rejected at this size; revisit when a feature needs to be consumed by a second app.

## Consequences

- Boundary violations are caught by lint, which can be silenced with an ignore comment. The lint
  configuration therefore carries weight that a package boundary would carry automatically, and CI
  runs `analyze --fatal-infos` so violations cannot merge quietly.
- Migrating to melos later is mechanical, because features already have no cross-imports.
