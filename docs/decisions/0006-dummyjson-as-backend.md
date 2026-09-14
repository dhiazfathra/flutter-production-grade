# ADR-0006: DummyJSON as the reference backend

## Status

Accepted

## Date

2026-09-13

## Context

The scaffold demonstrates real login, real token refresh, and a real paginated list. It must run
for anyone who clones it, with no account creation, no API keys, and no secrets in the repo.

## Decision

Target `https://dummyjson.com`: `/auth/login` and `/auth/refresh` for the session lifecycle,
`/products?limit=&skip=` and `/products/search?q=` for the list. Demo credentials ship in the
README because they are public sample credentials, not secrets.

## Alternatives Considered

### Supabase or Firebase

- Pros: production-shaped auth and data.
- Cons: requires an account and project keys per clone; the SDK absorbs the very layers the
  scaffold exists to show.
- Rejected.

### A local fake server (`dart_frog`) in-repo

- Pros: fully deterministic, works offline.
- Cons: a second application to maintain and run before the app works.
- Rejected for the default path; tests achieve determinism by stubbing dio instead.

## Consequences

- The app depends on a third-party service being up. Tests never hit it: unit, widget, and
  integration tests all run against stubbed responses.
- DummyJSON's refresh endpoint returns a new token pair, which is what makes the refresh
  interceptor testable end to end.
- Swapping backends means replacing the retrofit services and API models; repository interfaces,
  domain models, and everything above them are unaffected. That is the boundary working.
