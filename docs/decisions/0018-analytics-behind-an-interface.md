# ADR-0018: Analytics as an interface with a no-op default

## Status

Accepted

## Date

2026-09-13

## Context

Analytics arrives late and lands badly: vendor calls scattered through widgets, event names
invented at the call site, and no way to test that a screen reports anything. The vendor choice is
a product decision the scaffold should not make, but the seam is an architectural one it should.

## Decision

Define `AnalyticsService` in `core/` with a closed set of events modelled as a sealed class
(`ScreenViewed`, `LoginSucceeded`, `LoginFailed`, `ProductOpened`, `ThemeChanged`), not free-form
strings. Ship `NoopAnalytics` as the default and a `SentryAnalytics` adapter (breadcrumbs) to
prove the seam. Calls come from view models, never from widgets.

A go_router `NavigatorObserver` emits `ScreenViewed` automatically, so screen tracking is not a
per-screen obligation people forget.

## Alternatives Considered

### `log(String name, Map<String, Object?> params)`

- Pros: matches every vendor SDK exactly
- Cons: typos are silent, parameters drift per call site, nothing is checkable
- Rejected: a sealed event set costs a line per event and makes the taxonomy reviewable

### Firebase Analytics directly

- Pros: fastest path to a dashboard
- Cons: a vendor in every view model
- Rejected: same reasoning as ADR-0015

## Consequences

- Tests assert on emitted events via a recording fake, which makes "does login report failure"
  a real assertion.
- Adding an event is a deliberate edit to one sealed class — visible in review, which is the point.
- Anything a vendor cannot express as a typed event needs an ADR, not a workaround.
