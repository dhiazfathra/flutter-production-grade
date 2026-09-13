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
| Credentials | `flutter_secure_storage` (Keychain / Keystore) | [ADR-0014](docs/decisions/0014-secure-token-storage.md) |
| Crash reporting | Sentry behind an `ErrorReporter` interface | [ADR-0015](docs/decisions/0015-crash-and-error-reporting.md) |
| Analytics | sealed event set, no-op by default | [ADR-0018](docs/decisions/0018-analytics-behind-an-interface.md) |
| Design system | tokens plus shared widgets, verified by goldens | [ADR-0019](docs/decisions/0019-design-system-and-golden-tests.md) |
| Push + deep links | everything resolves to a go_router route | [ADR-0020](docs/decisions/0020-push-notifications-and-deep-links.md) |
| Accessibility | guideline matchers in the merge gate | [ADR-0025](docs/decisions/0025-accessibility-baseline.md) |
| Automation | lefthook, Renovate, release-please, Codecov | [ADR-0028](docs/decisions/0028-repository-automation.md) |

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
| `make goldens` | Regenerate golden files |
| `make patrol` | Native-dialog tests on an Android device or emulator |
| `make schema` | Dump the current drift schema into `drift_schemas/` |
| `make doctor` | Check the pinned SDK, config files, and codegen freshness |

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
    update/   ui/
```

`core/` also carries `platform/` (connectivity, biometrics, push, deep links, URL strategy),
`observability/` (error reporter, analytics), and `ui/design_system/`. Each platform capability is
an interface with a fake for tests — nothing above `core/` touches a plugin directly.

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
- **Coverage.** The gate is 100% of measured lines, with generated files, platform-conditional
  files, and thin plugin adapters excluded explicitly in `tool/coverage.sh`. The exclusions are
  listed rather than hidden; [ADR-0010](docs/decisions/0010-testing-strategy.md) explains what that
  leaves uncovered. Goldens, accessibility, and Patrol tests gate the merge but are not part of the
  line measure.
- **Tokens.** Access and refresh tokens live in the platform keystore, never in
  `shared_preferences`. On web that is WebCrypto over `localStorage`, which defends against casual
  inspection and not against XSS — a real web deployment should move to httpOnly cookies. See
  [ADR-0014](docs/decisions/0014-secure-token-storage.md).
- **Deep links and notifications.** Both are converted to a route path and handed to go_router, so
  the auth redirect applies to them like any other navigation. A link that arrives while signed out
  is held and replayed after login. Payload routes are matched against known routes, never pushed
  verbatim — they are untrusted network input.
  See [ADR-0020](docs/decisions/0020-push-notifications-and-deep-links.md).
- **Offline.** Connectivity drives the banner and the "cached {time}" line, and nothing else.
  Requests are never skipped because the device reports offline; a captive portal reports connected
  and still fails. See [ADR-0016](docs/decisions/0016-connectivity-and-offline-ux.md).
- **Startup.** Seven ordered steps before the first frame: URL strategy, config validation, error
  reporter, settings, version gate, push, `runApp`. A missing config key fails immediately by name.
- **Firebase is optional to run.** With no `google-services.json` / `GoogleService-Info.plist` /
  web config present, push initialisation is skipped and the app runs normally. That branch is
  tested, so a fresh clone always starts.
- **Drift schema.** Versioned from v1 with a committed dump per version and a generated migration
  test for every step. `make schema` after any schema change, or CI fails. See
  [ADR-0021](docs/decisions/0021-drift-migrations-and-schema-tests.md).
- **Web URLs.** The path URL strategy is on, so routes are real URLs. Any host must rewrite unknown
  paths to `index.html` or deep links 404; `_redirects` and an nginx snippet are committed as
  examples. See [ADR-0022](docs/decisions/0022-web-delivery.md).

## Configuration

`config/*.json` holds per-flavor values (API base URL, app name, log level, Sentry DSN, minimum
supported version) and is git-ignored; `config/example.json` is committed. Values reach the app
through `--dart-define-from-file` and a single `AppConfig` provider, which asserts at startup that
every required key is present. They are compiled into the binary, so they are configuration, not
secrets. See [ADR-0011](docs/decisions/0011-build-flavors-and-configuration.md).

Firebase configuration (`google-services.json`, `GoogleService-Info.plist`, the web
`firebaseConfig`) is per-flavor and git-ignored, with committed examples. The app runs without it —
push is simply skipped.

## What this scaffold costs you

Batteries included means dependencies included. Each of these is behind an interface, so removing
one is a deleted file and a changed provider override, not a refactor:

| Dependency | What it buys | What it costs |
|---|---|---|
| Firebase (core, messaging) | push notifications | per-flavor config files, an APNs key, native build weight |
| Sentry | crash and error reporting | a DSN per environment, and a `beforeSend` scrubber you must keep honest |
| local_auth | biometric session lock | a platform permission, no web support |
| Patrol | tests that can dismiss native dialogs | its own Android test harness and a separate CI job |
| alchemist | golden coverage of the design system | binary files in the repo and review noise on design changes |

[ADR-0029](docs/decisions/0029-deferred-additions.md) lists what was deliberately *not* added yet —
remote feature flags, experiments, Fastlane lanes — and which seam each one will use.

## Contributing

- Conventional commits (`feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `style`, `perf`).
- Run `make lint` and `make cov` before opening a pull request; CI runs the same commands plus a
  codegen freshness check that fails if committed generated output is stale.
- Record any decision that would be expensive to reverse as a new ADR in `docs/decisions/`.
  Supersede old ADRs, never rewrite them.
