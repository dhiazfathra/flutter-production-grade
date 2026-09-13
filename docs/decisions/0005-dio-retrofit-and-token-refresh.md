# ADR-0005: dio + retrofit, with refresh handled in an interceptor

## Status
Accepted

## Date
2026-09-13

## Context
The scaffold needs a typed HTTP client, a place to attach bearer tokens, and a correct answer to
"the access token expired mid-session" — including when several requests fail with 401 at once.

## Decision
`dio` as the transport, `retrofit` + `retrofit_generator` for typed API service classes. Three
interceptors: `AuthInterceptor` (attach bearer), `RefreshInterceptor` (on 401, lock the queue,
refresh once, replay the queued requests, clear the session on failure), `ErrorInterceptor` (map
transport failures to `AppError`). Debug builds additionally get `pretty_dio_logger` and `alice`.

## Alternatives Considered
### `package:http` with a hand-written client wrapper
- Pros: one fewer dependency; the `flutter-use-http-package` skill covers it.
- Cons: no interceptor chain, so refresh-and-replay must be hand-rolled per call site; no typed
  client generation.
- Rejected: the interceptor chain is exactly the mechanism this problem needs.

### Refresh inside each repository
- Pros: no shared lock.
- Cons: duplicated in every repository; concurrent 401s cause a refresh stampede and can burn a
  single-use refresh token.
- Rejected.

## Consequences
- A concurrency test is mandatory, not optional: N simultaneous 401s must produce exactly one
  refresh call. It is asserted in the suite.
- Repositories never see a `DioException`; they see `Result<T>` carrying an `AppError`.
- Retrofit services are generated, so an endpoint change is a signature change plus `build_runner`.
