# ADR-0009: Material 3 theming, two-way toggle, system decides the first run

## Status
Accepted

## Date
2026-09-13

## Context
The app needs light and dark themes and a user-facing switch. Flutter's `ThemeMode` offers
`system`, `light`, and `dark`, and the obvious design is a three-way control — but the project
owner specified a plain two-state switch.

## Decision
`ColorScheme.fromSeed` generates the light and dark schemes; colours, type, and spacing live only
in `core/ui/themes/`. The app stores a resolved `ThemeMode.light` or `ThemeMode.dark` — never
`system`. On first launch after install no preference exists, so the app reads
`PlatformDispatcher.instance.platformBrightness` once and persists the matching mode. From then on
the stored value wins and later OS theme changes do not flip the app. The settings screen shows a
two-state switch.

## Alternatives Considered
### Keep `ThemeMode.system` as a third selectable option
- Pros: follows the OS for the app's whole lifetime; standard Flutter behaviour.
- Cons: three-state control; rejected by the project owner.
- Rejected on that instruction.

## Consequences
- The OS setting is read exactly once per install, which is a real behavioural difference from
  most Flutter apps and is called out in the README.
- The preference is loaded during bootstrap before the first frame, so the app never flashes the
  wrong theme.
- Tests cover all three paths: fresh install follows the OS, a stored value overrides the OS, and
  the toggle persists across restarts.
