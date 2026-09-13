# ADR-0011: Three flavors configured by `--dart-define-from-file`

## Status
Accepted

## Date
2026-09-13

## Context
Real apps need dev, staging, and production builds that differ in API base URL, app name, bundle
identifier, and log verbosity, with no secret committed to the repository.

## Decision
Three entry points (`main_dev.dart`, `main_staging.dart`, `main.dart`) that each call
`bootstrap(Flavor.x)`. Values come from `--dart-define-from-file=config/dev.json`, read through a
single `AppConfig` provider. `config/*.json` files are git-ignored; `config/example.json` is
committed.

## Alternatives Considered
### `.env` files loaded at runtime (`flutter_dotenv`)
- Pros: familiar from server work.
- Cons: the file ships inside the bundle and is readable; values are strings resolved at runtime
  rather than compile time.
- Rejected.

### Hard-coded constants behind `kDebugMode`
- Pros: no tooling.
- Cons: only two environments, and it conflates build mode with deployment target.
- Rejected.

## Consequences
- Every run and build command needs its `--dart-define-from-file` flag; the `Makefile` wraps them
  so nobody types them by hand.
- `AppConfig` is a provider, so tests override it instead of mutating globals.
- `--dart-define` values are compiled into the binary. They are configuration, not secrets: this
  mechanism must not be used for anything that would matter if extracted from the bundle.
