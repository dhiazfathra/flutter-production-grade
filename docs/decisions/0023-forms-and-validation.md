# ADR-0023: Hand-rolled validators, not a forms framework

## Status
Accepted

## Date
2026-09-13

## Context
The scaffold has one form (login) and will grow more. Validation logic that lives inside widget
callbacks is untestable without pumping a widget, and error messages written at the call site
bypass localization.

## Decision
Keep Flutter's `Form` and `TextFormField`. Put the rules in `core/utils/validators.dart` as pure
functions of the shape `String? Function(String?)`, composed with a `combine` helper, returning
localization keys rather than literal strings. View models own submission state; the widget owns
only the `GlobalKey<FormState>`.

## Alternatives Considered

### `reactive_forms` 18.2.2
- Pros: declarative model, cross-field validation, async validators, less widget wiring on large
  forms
- Cons: a second state system beside Riverpod, with its own lifecycle and its own idea of where
  form state lives — for one login form and one settings screen that is a net loss
- Rejected for now: revisit with an ADR if a form exceeds roughly ten interdependent fields

### Validation inside the view model only
- Pros: one place
- Cons: loses the per-field inline error UX that `TextFormField` gives for free
- Rejected

## Consequences
- Validators are pure and unit-tested directly, with no widget pump — the fastest tests in the
  suite.
- Cross-field rules (password confirmation) have no framework support and are handled in the view
  model at submit time.
- This is the one place in this batch where the lazier option is the chosen one; it is recorded so
  the omission reads as a decision rather than an oversight.
