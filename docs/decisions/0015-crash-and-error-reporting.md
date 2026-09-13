# ADR-0015: Sentry behind an ErrorReporter interface

## Status

Accepted

## Date

2026-09-13

## Context

The design already had an `ErrorReporter` abstraction with no implementation behind it. An
abstraction with no real sink is dead code: nobody finds out whether the interface is the right
shape until a vendor is wired in, and by then the app is shipping.

Three separate handlers must be installed or errors are silently lost: `FlutterError.onError`
(framework errors), `PlatformDispatcher.instance.onError` (uncaught async errors outside the
framework), and `runZonedGuarded` (everything else on the zone).

## Decision

Keep `ErrorReporter` as the interface used by the whole app. Provide two implementations:
`NoopErrorReporter` (default, and what tests get) and `SentryErrorReporter` using
`sentry_flutter` 9.30.0, selected per flavor — off in dev, on in staging and prod. `bootstrap()`
installs all three handlers and routes each into `ErrorReporter`.

## Alternatives Considered

### Firebase Crashlytics

- Pros: free, standard on mobile, already in most Firebase projects
- Cons: no web support worth the name, and this app targets web; native symbol upload is a build
  step per platform
- Rejected: web is a first-class target here

### No reporter, just logs

- Pros: nothing to configure
- Cons: you learn about production crashes from users
- Rejected

## Consequences

- The DSN is a per-flavor `--dart-define` value, so it lives in `config/*.json` alongside the base
  URL and never in source.
- `beforeSend` scrubs the `Authorization` header and the request body of auth calls. This is the
  same class of leak that ADR-0012 restricts alice for, and it needs the same care.
- Release health and performance tracing are enabled at a low sample rate rather than disabled, so
  the wiring is proven; the rate is a config value.
- Swapping vendors touches one class.
