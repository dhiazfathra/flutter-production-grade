# ADR-0020: Push and deep links resolve to routes, decided now

## Status

Accepted

## Date

2026-09-13

## Context

This is the most expensive item on the list to retrofit. Both push notification taps and deep
links arrive as a URL or payload that must become a navigation, potentially before the router
exists, potentially while the user is logged out, and potentially while the app is cold. Apps that
add this late end up with a second navigation mechanism next to the router, and the auth redirect
then races it.

## Decision

One entry point: every external navigation is converted to a route path string and handed to
go_router, so the existing `redirect` in ADR-0008 applies the auth rules uniformly.

- `firebase_messaging` 16.6.0 for transport, `firebase_core` 4.14.0, `flutter_local_notifications`
  22.3.1 to render foreground notifications (Android does not show them otherwise).
- `app_links` 7.2.1 for universal links, App Links, and custom schemes; the web path needs nothing
  beyond the URL strategy in ADR-0022.
- A `PendingDeepLink` provider holds the target when it arrives before the router is ready or
  while the user is unauthenticated; the redirect reads it after login but only clears it once
  navigation to that target has committed. go_router can re-evaluate the top-level `redirect`
  before the previous navigation finishes, so clearing eagerly on redirect can discard the target
  before it is reached; retaining it until commit keeps it retryable.
- Notification payloads carry a `route` field. Unknown or malformed routes fall back to the home
  route and are reported, never crash.

## Alternatives Considered

### Navigate imperatively from the notification handler

- Pros: direct
- Cons: bypasses the auth redirect, and a cold start has no navigator yet
- Rejected: it is precisely the second mechanism this ADR exists to avoid

### Defer push entirely

- Pros: less scope now
- Cons: retrofitting it means revisiting routing, auth, and startup together
- Rejected

## Consequences

- Firebase is a real configuration burden: `google-services.json`, `GoogleService-Info.plist`, an
  APNs key, and a web `firebaseConfig`. These are per-flavor and git-ignored, with committed
  examples. The scaffold runs without them — push initialisation is skipped when config is absent,
  and that path is tested.
- A payload with a `route` field is untrusted input from the network. It is matched against known
  routes, not passed to the router verbatim.
- Deep-link handling is covered by a widget-level test over the URL-to-route mapper, not by an
  integration test that needs a real link.
