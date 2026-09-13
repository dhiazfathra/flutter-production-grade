# ADR-0002: Riverpod (code-generated) for state management and DI

## Status
Accepted

## Date
2026-09-13

## Context
The scaffold needs one mechanism for both dependency injection and UI state, and the brief asks
for as much code generation as practical. The architecture skill's examples use `ChangeNotifier`
view models wired through `provider` or `get_it`.

## Decision
Use Riverpod 3 with `riverpod_annotation` / `riverpod_generator`. Every provider is declared with
`@riverpod`; view models are generated `Notifier` / `AsyncNotifier` classes. Dependencies are
injected by `ref.watch`, and swapped in tests and per flavor through `ProviderScope(overrides:)`.
`riverpod_lint` runs via `custom_lint` in CI.

## Alternatives Considered
### `ChangeNotifier` + `provider`, verbatim from the skill
- Pros: matches the skill example literally; fewer generated files.
- Cons: manual `notifyListeners`, no first-class async state, no compile-time provider checks,
  separate `get_it` registry for non-UI dependencies.
- Rejected: Riverpod covers DI and state with one tool and generates the wiring.

### `bloc`
- Pros: explicit event/state modelling, mature tooling.
- Cons: an event class per interaction; a second DI mechanism still required.
- Rejected: more boilerplate for no boundary this scaffold lacks.

## Consequences
- Deliberate deviation from the skill: our view models are Riverpod `Notifier`s, not
  `ChangeNotifier`s. The role is identical (a listenable that owns UI state, takes repositories as
  dependencies, and exposes immutable snapshots); only the injection mechanism differs.
- `build_runner` is on the critical path. CI fails if committed generated output is stale.
- Widget tests must wrap widgets in `ProviderScope` with overrides rather than passing constructor
  arguments.
