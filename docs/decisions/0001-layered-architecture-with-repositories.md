# ADR-0001: Layered architecture with repositories, use cases optional

## Status
Accepted

## Date
2026-09-13

## Context
This repository is a production-grade Flutter scaffold. It must demonstrate boundaries clearly
enough to be copied into real projects, without accumulating ceremony that teams then delete.
The `flutter-apply-architecture-best-practices` skill and the official Flutter app-architecture
guide both prescribe UI / Domain / Data layers with the Repository pattern, and describe the
use-case (interactor) layer as conditional.

## Decision
Three layers per feature: `ui` (views + view models), `domain` (immutable models, optional use
cases), `data` (services + repositories). Repositories are the single source of truth: they
consume services, map API models to domain models, and own caching, retry, and offline logic.
Use cases are created only when logic spans repositories or would clutter a view model. None
exist at scaffold time.

## Alternatives Considered
### Full Clean Architecture with a use case per action
- Pros: uniform, textbook-recognisable.
- Cons: `GetProducts`, `Login`, `RefreshToken` would each be a one-line pass-through to the
  repository.
- Rejected: it is boilerplate that adds indirection without adding a decision point.

### Providers calling data sources directly (no domain layer)
- Pros: least code.
- Cons: API models leak into widgets; nothing to fake in tests but HTTP.
- Rejected: the boundaries are the point of a scaffold.

## Consequences
- Repositories are the widest unit under test; view models are tested against faked repositories.
- Adding a use case later is additive and touches only the view model that needs it.
- Repository classes will grow; when one exceeds a screenful of logic, that is the signal to
  extract a use case rather than to keep appending methods.
