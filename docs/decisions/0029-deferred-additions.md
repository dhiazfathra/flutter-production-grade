# ADR-0029: Additions accepted in principle, deferred in sequence

## Status

Proposed

## Date

2026-09-13

## Context

Several batteries are worth having but should not block the first working scaffold. Recording them
as deferred is different from omitting them: the seams they need are being built now, so adding
them later is additive rather than a refactor.

## Decision

Accept the following, scheduled after the scaffold's first green build, and record the seam each
one depends on:

| Addition                                                 | Seam it needs (built now)                                                                 |
| -------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| Remote feature flags (Firebase Remote Config or Unleash) | `AppConfig` provider — flags read through the same interface, so call sites do not change |
| A/B experiment assignment                                | the sealed analytics event set in ADR-0018                                                |
| In-app rating prompt                                     | `package_info_plus` and the settings service from ADR-0017                                |
| Fastlane lanes for TestFlight and Play                   | the flavor entry points in ADR-0011                                                       |
| Sentry performance tracing beyond the default rate       | already wired in ADR-0015; only the sample rate changes                                   |

Desktop targets are not in this table: they are explicitly out of scope for this scaffold (see
Purpose in the design spec), not an accepted addition scheduled after the first green build. There
is no seam for them today, and none is being built.

`flutter_launcher_icons` 0.14.4 and `flutter_native_splash` 2.4.8 are **not** deferred — they are
configuration-only, cost one `pubspec.yaml` block each, and a scaffold without an icon and a splash
screen looks unfinished on first run. They ship with the initial scaffold.

## Alternatives Considered

### Build everything now

- Pros: nothing left to do
- Cons: remote config and experiments need product decisions the scaffold cannot make, and
  Fastlane needs store credentials that do not exist yet
- Rejected

### Leave them unrecorded

- Pros: a shorter decision log
- Cons: the next person cannot tell a deliberate deferral from an oversight
- Rejected — that distinction is the reason this file exists

## Consequences

- This ADR stays `Proposed` and is superseded, item by item, as each addition gets its own ADR.
- Each deferred item names the seam it will use; if that seam changes, this table is the list of
  things to re-check.
