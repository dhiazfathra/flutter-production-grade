# ADR-0019: A design-system module, verified by goldens

## Status
Accepted

## Date
2026-09-13

## Context
ADR-0009 puts colour and typography tokens in `core/ui/themes/`, but nothing stops a feature from
writing `padding: EdgeInsets.all(13)` or building its own button. Without shared widgets, every
feature reinvents spacing, loading, empty, and error presentation, and the theme tokens end up
describing a consistency the app does not have.

Widget tests assert structure and behaviour. They do not catch a dark-theme contrast regression or
a spacing change, which is exactly what a token refactor breaks.

## Decision
Add `core/ui/design_system/` with `AppSpacing`, `AppTypography`, `AppRadius`, and a small widget
set: `AppButton`, `AppTextField`, `AppScaffold`, `AppEmptyState`, `AppErrorView`, `AppLoading`.
Features compose these; raw `Padding` with literal values and bare `ElevatedButton` are lint
violations under the custom rule set.

Verify with golden tests using `alchemist` 0.14.0: every design-system widget in light and dark,
plus each screen's four states. Goldens run on CI in the Flutter-only job, where font rendering is
deterministic; platform-specific goldens are not generated.

Loading states use `skeletonizer` 3.0.0, which builds skeletons from the real widget tree rather
than from a second hand-maintained placeholder layout.

## Alternatives Considered

### No design system, tokens only
- Pros: less code up front
- Cons: the drift it allows is the thing this scaffold exists to prevent
- Rejected

### Plain `matchesGoldenFile`
- Pros: no dependency
- Cons: no theme matrix, no font loading helper, per-test boilerplate
- Rejected: alchemist is a thin wrapper over exactly this boilerplate

### `shimmer`
- Pros: fewer concepts
- Cons: needs a parallel placeholder layout per screen that silently rots
- Rejected in favour of skeletonizer

## Consequences
- Goldens are binary files in the repo and will produce review noise on intentional design changes.
  `make goldens` regenerates them; a golden update in a PR that claims no visual change is a
  review signal.
- Goldens are excluded from the line-coverage measure but are part of the merge gate.
- A font must be bundled and loaded in the test harness, or goldens render boxes.
