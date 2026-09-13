# ADR-0007: freezed domain models, separate API models

## Status

Accepted

## Date

2026-09-13

## Context

The API's JSON shape and the app's model should be free to diverge. The architecture skill
requires services to return raw API models and repositories to transform them into domain models.

## Decision

Two model families. `*ApiModel` classes live in a feature's `data/models/`, use
`json_serializable`, and mirror the wire format exactly. Domain models live in `domain/models/`,
use `freezed` for immutability, equality, copy, and pattern matching, and contain no JSON code.
Repositories map API model to domain model, in one direction only.

## Alternatives Considered

### One model used for both wire and domain

- Pros: half the classes and no mapper.
- Cons: a backend rename propagates into widgets; JSON annotations end up in the domain layer.
- Rejected: it trades a small amount of code for the boundary that makes backend swaps cheap.

### `built_value`

- Pros: equivalent immutability guarantees.
- Cons: heavier syntax, smaller community, no pattern-matching sugar.
- Rejected.

## Consequences

- Every feature carries a mapper; each has a unit test asserting round-trip field mapping.
- `freezed` sealed unions model `AppError` and `Result`, so exhaustive `switch` handling is
  compiler-checked.
- More generated files; `build_runner` runtime grows with the model count.
