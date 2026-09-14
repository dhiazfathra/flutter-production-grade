# flutter_production_grade

A production-grade Flutter scaffold: layered architecture, Riverpod, go_router,
build flavors, and a 100% line-coverage gate enforced in CI.

## Requirements

- Flutter, pinned via [FVM](https://fvm.app) (`.fvmrc`). Every Make target
  prefers `fvm flutter` / `fvm dart` when `fvm` is on the `PATH`.
- `make doctor` checks the local toolchain.

## Setup

```sh
make get   # pub get
make gen   # build_runner (freezed / riverpod / json_serializable)
make l10n  # regenerate localizations
```

## Configuration and flavors

Runtime configuration comes from JSON passed with `--dart-define-from-file`.
Only `config/example.json` is committed; every other `config/*.json` is
gitignored because it carries secrets and per-environment values.

| Key | Meaning |
| --- | --- |
| `BASE_URL` | API base URL |
| `APP_NAME` | Display name for the flavor |
| `SENTRY_DSN` | Crash reporting DSN (empty disables it) |
| `MIN_SUPPORTED_VERSION` | Minimum version for the force-update check |

Three flavors, each with its own entrypoint:

| Flavor | Entrypoint | Config |
| --- | --- | --- |
| dev | `lib/main_dev.dart` | `config/dev.json` |
| staging | `lib/main_staging.dart` | `config/staging.json` |
| prod | `lib/main.dart` | `config/prod.json` |

Copy `config/example.json` to the flavor file you need, then:

```sh
make run-dev   # flutter run --flavor dev -t lib/main_dev.dart
```

## Tests

```sh
make test         # unit + widget tests
make cov          # tests with coverage, then the 100% gate
make goldens      # regenerate golden files
make integration  # flutter drive against chromedriver on :4444
make lint         # dart format --set-exit-if-changed + flutter analyze --fatal-infos
```

`make cov` runs `tool/coverage.sh`, which strips generated and
platform-conditional files from `coverage/lcov.info` (the exclusion list is
explicit, per ADR-0010) and fails unless every remaining line is covered — and
also fails if the exclusions leave nothing measured.

`make integration` needs `chromedriver` running on port 4444:

```sh
chromedriver --port=4444 &
make integration
```

## Documentation

- `docs/decisions/` — architecture decision records (ADR-0001 … ADR-0029).
- `docs/evidence/` — captured evidence for shipped work.
