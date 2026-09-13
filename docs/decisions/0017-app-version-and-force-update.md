# ADR-0017: Minimum-version gate at startup

## Status
Accepted

## Date
2026-09-13

## Context
Every deployed mobile app eventually needs to stop an old build from talking to a changed API.
Teams that add this after the incident cannot use it for that incident, because the clients in
the field do not have the check.

## Decision
Read the running version with `package_info_plus` 10.2.1. `bootstrap()` asks a
`VersionGateRepository` for the minimum supported version and, if the running build is below it,
routes to a blocking update screen before any authenticated route renders.

For the scaffold the minimum version comes from `AppConfig` (a `--dart-define` value), with the
repository interface shaped so a remote source drops in without touching callers. The gate is a
route guard in go_router, so it composes with the auth redirect rather than competing with it.

## Alternatives Considered

### Only check on the store side (Play/App Store forced update)
- Pros: no app code
- Cons: no web coverage, slow propagation, no soft-update option
- Rejected: web is a target

### Check lazily on the first 426 response from the API
- Pros: server-driven, no config
- Cons: requires backend support DummyJSON does not have
- Rejected for the scaffold; the repository interface leaves room for it

## Consequences
- Version comparison is semantic, not lexicographic (`1.10.0 > 1.9.0`), and is unit-tested with
  that exact case.
- On web the gate degrades to a reload prompt; there is no store to send the user to.
- The check adds a startup dependency: if the remote source is added later it must have a timeout
  and fail open, or an outage becomes an app-wide outage.
