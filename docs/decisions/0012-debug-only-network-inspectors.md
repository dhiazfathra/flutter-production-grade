# ADR-0012: alice and pretty_dio_logger, debug builds only

## Status
Accepted

## Date
2026-09-13

## Context
Inspecting traffic on a device is the fastest way to debug an integration. Both requested tools
carry a cost in production: `pretty_dio_logger` prints request and response bodies (including
tokens) to the system log, and `alice` retains a request history in memory and exposes a UI that
can display it.

## Decision
Register both interceptors only when `kDebugMode` is true. The alice inspector is reachable from a
debug-only entry point. Release builds contain neither interceptor in the dio chain.

## Alternatives Considered
### Always on, gated by a runtime flag
- Pros: can be enabled on a production build to debug a live issue.
- Cons: the capture code and its stored payloads remain in the shipped app; a flag flip or a bug
  exposes tokens and personal data.
- Rejected.

### Neither tool
- Pros: nothing to gate.
- Cons: explicitly requested.
- Rejected.

## Consequences
- The interceptor list differs between debug and release, so the "does the chain behave the same"
  question is covered by a test asserting the release chain excludes both.
- Anyone adding a logging interceptor later must follow the same gate; this is noted in the README
  and in the code comment at the registration site.
