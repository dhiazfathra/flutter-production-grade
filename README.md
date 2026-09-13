# flutter-production-grade

A production-grade Flutter scaffold: layered architecture, Riverpod with code generation,
offline-first caching, real token refresh, and a test suite that gates every merge.

Status: **design phase.** The decisions are recorded and the specification is written; no
application code exists yet. Start with [the spec](docs/superpowers/specs/2026-09-13-flutter-production-scaffold-design.md),
then the [decision records](docs/decisions/).

## Stack

| Concern | Choice | Rationale |
|---|---|---|
| State + DI | Riverpod 3 (`riverpod_generator`) | [ADR-0002](docs/decisions/0002-riverpod-with-code-generation.md) |
| Architecture | Feature-first, UI / domain / data per feature | [ADR-0001](docs/decisions/0001-layered-architecture-with-repositories.md), [ADR-0003](docs/decisions/0003-feature-first-project-structure.md) |
| Networking | dio + retrofit, refresh in an interceptor | [ADR-0005](docs/decisions/0005-dio-retrofit-and-token-refresh.md) |
| Local cache | drift (SQLite, wasm on web) | [ADR-0004](docs/decisions/0004-drift-for-offline-cache.md) |
| Models | freezed domain models, `json_serializable` API models | [ADR-0007](docs/decisions/0007-freezed-models-and-dto-split.md) |
| Routing | go_router with typed routes and an auth redirect | [ADR-0008](docs/decisions/0008-go-router-declarative-routing.md) |
| Backend | DummyJSON (no account, no keys) | [ADR-0006](docs/decisions/0006-dummyjson-as-backend.md) |
| Tests | flutter_test, mockito codegen, integration_test | [ADR-0010](docs/decisions/0010-testing-strategy.md) |

Targets iOS, Android, and web. Flutter 3.47.4, pinned with [fvm](https://fvm.app).

## Quick start

```bash
fvm install                       # installs the pinned SDK
make get                          # flutter pub get
cp config/example.json config/dev.json
make gen                          # build_runner: providers, models, routes, drift, mocks
make run-dev
```

Sign in with the DummyJSON demo account shown on the login screen (`emilys` / `emilyspass`).
These are public sample credentials, not secrets.

## Commands

| Command | Description |
|---|---|
| `make get` | Fetch dependencies |
| `make gen` | Run `build_runner` once |
| `make watch` | Run `build_runner` in watch mode |
| `make l10n` | Regenerate localizations from ARB files |
| `make run-dev` | Run the dev flavor |
| `make test` | Unit and widget tests |
| `make cov` | Tests with coverage, enforcing the gate |
| `make lint` | `format --set-exit-if-changed`, `analyze --fatal-infos`, `custom_lint` |
| `make integration` | Integration tests via `flutter drive` |

## Architecture

```
lib/
  main.dart  main_dev.dart  main_staging.dart   # one per flavor, each calls bootstrap()
  core/                                          # shared by two or more features
    data/   api (dio, interceptors), local (drift), storage (secure tokens, settings)
    ui/     themes, shared widgets, localization helpers
    utils/  Result, AppError, logger, error reporter
  config/    flavor, AppConfig, provider overrides
  routing/   router, typed routes, auth redirect
  features/
    auth/     data/ domain/ ui/
    products/ data/ domain/ ui/
    settings/ ui/
```

Dependency rule: `ui -> domain <- data`. Domain models are pure Dart — no Flutter, no dio, no
drift. Features never import each other; anything shared moves to `core/`. Enforced by lint, and
CI runs `analyze --fatal-infos`, so a violation cannot merge.

### Behaviour worth knowing before you read the code

- **Theme.** The app stores light or dark, never `system`. On the first launch after install it
  reads the OS brightness once and persists the match; after that the stored value wins and OS
  changes do not flip the app. See [ADR-0009](docs/decisions/0009-theme-mode-strategy.md).
- **Token refresh.** A 401 locks the dio queue, refreshes once, and replays the queued requests.
  Concurrent 401s produce exactly one refresh call, and that is asserted in the suite.
- **Offline-first reads.** The products list renders from drift immediately and revalidates from
  the network, writing through to the cache. The UI watches a drift stream, so cache writes
  update the screen without a second fetch.
- **Debug-only inspectors.** `alice` and `pretty_dio_logger` are registered only when
  `kDebugMode`. They log and retain request bodies including tokens, so they must never ship in a
  release chain. See [ADR-0012](docs/decisions/0012-debug-only-network-inspectors.md).
- **Coverage.** The gate is 100% of measured lines, with generated files and platform-conditional
  files excluded explicitly in `tool/coverage.sh`. The exclusions are listed rather than hidden;
  [ADR-0010](docs/decisions/0010-testing-strategy.md) explains what that leaves uncovered.

## Configuration

`config/*.json` holds per-flavor values (API base URL, app name, log level) and is git-ignored;
`config/example.json` is committed. Values reach the app through `--dart-define-from-file` and a
single `AppConfig` provider. They are compiled into the binary, so they are configuration, not
secrets. See [ADR-0011](docs/decisions/0011-build-flavors-and-configuration.md).

## Contributing

- Conventional commits (`feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `style`, `perf`).
- Run `make lint` and `make cov` before opening a pull request; CI runs the same commands plus a
  codegen freshness check that fails if committed generated output is stale.
- Record any decision that would be expensive to reverse as a new ADR in `docs/decisions/`.
  Supersede old ADRs, never rewrite them.
