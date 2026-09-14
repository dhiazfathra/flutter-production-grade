# ADR-0008: go_router with type-safe routes and an auth redirect

## Status

Accepted

## Date

2026-09-13

## Context

Navigation must work on web (real URLs, deep links, back button) as well as mobile, and
unauthenticated users must never reach an authenticated screen.

## Decision

`go_router`, exposed as a `@riverpod` provider so it can watch the auth state. Routes are declared
with `go_router_builder`'s typed route classes, so navigation is a constructor call rather than a
string. A single `redirect` handles the guard: unauthenticated users going to a protected route
land on `/login`; authenticated users on `/login` are sent to `/products`.

## Alternatives Considered

### Imperative `Navigator` calls

- Pros: no dependency.
- Cons: no URL story on web, guard logic duplicated at every call site.
- Rejected.

### `auto_route`

- Pros: richer generated API.
- Cons: heavier generator; go_router is the Flutter-team-supported option and the
  `flutter-setup-declarative-routing` skill targets it.
- Rejected.

## Consequences

- One `redirect` function is the only place authorisation affects navigation, and it is unit
  tested per state (unauthenticated, authenticated, expired).
- Because the router provider watches auth, session expiry navigates the user out automatically
  with no call from the interceptor into the widget tree.
