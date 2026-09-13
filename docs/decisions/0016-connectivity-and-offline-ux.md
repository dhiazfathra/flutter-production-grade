# ADR-0016: Surface connectivity, do not branch on it

## Status
Accepted

## Date
2026-09-13

## Context
The app is offline-first (ADR-0004): reads render from drift and revalidate from the network.
That works without any connectivity awareness, but the user cannot tell the difference between
"this is fresh" and "this is three days old and the network is gone".

`connectivity_plus` reports the presence of a transport, not the reachability of the backend. A
device on a captive-portal WiFi reports connected and every request still fails.

## Decision
Add `connectivity_plus` 7.3.1 behind a `ConnectivityService`, exposed as a Riverpod stream
provider. Use it only for presentation: an offline banner above the products list, and a "showing
cached data from {time}" line driven by the drift `fetchedAt` column.

Do not gate requests on it. The repository always attempts the call and handles
`AppError.network` — the transport state is a hint, the request result is the truth.

## Alternatives Considered

### Skip requests when reported offline
- Pros: saves a doomed request
- Cons: false negatives strand a working connection; false positives still fail
- Rejected: it adds a second source of truth that disagrees with the first

### Poll the backend for reachability
- Pros: accurate
- Cons: battery and traffic cost for information the next real request provides anyway
- Rejected

## Consequences
- The banner is a widget-tested state, driven by an overridden provider, so no plugin channel is
  needed in tests.
- On regaining connectivity the products view model triggers one revalidation rather than
  retrying every failed call.
- `fetchedAt` becomes user-visible, so it must be stored as UTC and rendered through the
  localization layer.
