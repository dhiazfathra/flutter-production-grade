# ADR-0022: Web delivery — path URLs, PWA, and a wasm build check

## Status
Accepted

## Date
2026-09-13

## Context
Web is a first-class target (ADR-0006 scope), but Flutter's defaults are not web-appropriate. The
default hash URL strategy produces `example.com/#/products/3`, which breaks copy-paste sharing,
server-side routing, canonical URLs, and crawler indexing. The default `index.html` has no
metadata. Skipping this at scaffold time means retrofitting it after links have been shared.

## Decision
- Use the path URL strategy (`usePathUrlStrategy()` from `flutter_web_plugins`) so routes are real
  URLs. The deployment must serve `index.html` for unknown paths; a `_redirects` file and an nginx
  snippet are committed as examples.
- Fill in `index.html`: title, description, Open Graph and Twitter tags, theme colour, and a real
  `manifest.json` with icons, so the app is installable.
- Add `flutter build web --wasm` to CI alongside the JS build. It is a compile check, not the
  shipped artifact — it catches a dependency with no wasm-compatible path early rather than at
  migration time.
- The drift web worker assets (`sqlite3.wasm`, `drift_worker.js`) are committed under `web/` and
  their presence is asserted by a CI step, since a missing asset fails only at runtime (ADR-0004).

## Alternatives Considered

### Keep the hash strategy
- Pros: works on any static host with no configuration
- Cons: unshareable, unindexable URLs
- Rejected: the hosting configuration is a one-line rewrite rule

### Skip the wasm build
- Pros: a shorter CI run
- Cons: incompatibility is found during the migration instead of at the commit that caused it
- Rejected

## Consequences
- Any host must be configured to rewrite unknown paths to `index.html` or deep links 404. This is
  in the README, not only here.
- The wasm job may fail for reasons outside this repository when a dependency lags. It runs as a
  required check; if it becomes flaky the response is to pin, not to delete the job.
