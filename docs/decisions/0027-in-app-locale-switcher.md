# ADR-0027: Locale persists like theme, seeded from the OS once

## Status
Accepted

## Date
2026-09-13

## Context
ADR-0009 established a mechanism for a user preference that overrides an OS default: read the OS
value once on first launch, persist the resolution, and let the stored value win afterwards.
Locale is the same shape, and the ARB files for `en` and `id` already exist. Leaving locale on
`system` while theme is user-controlled is an inconsistency with no reason behind it.

## Decision
`SettingsService` stores a locale alongside the theme mode. On first launch the OS locale is
matched against the supported set, falling back to `en`, and the result is persisted. The settings
screen offers an explicit choice. `MaterialApp.locale` reads the stored value.

## Alternatives Considered

### Follow the OS locale always
- Pros: no UI, no storage
- Cons: users in multilingual regions routinely want an app in a language other than their device
  language; no way to test the other locale by hand
- Rejected

### Store `null` meaning "follow the system"
- Pros: OS changes propagate
- Cons: a tri-state that contradicts the two-state theme decision for no gain
- Rejected: consistency with ADR-0009 is the point

## Consequences
- Locale changes at runtime, so any cached formatted string must be rebuilt; formatting happens at
  build time through `context.l10n`, never cached in a view model.
- The existing test asserting that the ARB files carry identical key sets becomes load-bearing:
  a missing key in `id` is now reachable by a user, not just theoretical.
- Adding a locale means an ARB file and one entry in the supported list.
