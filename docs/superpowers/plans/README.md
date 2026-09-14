# Implementation plans

The scaffold is built in four plans. Each one ends with software that runs, tests that pass, and a
green CI pipeline — so the work can stop after any of them and still leave something usable.

| Plan                                                                    | Scope                                                                                                                                                  | Deliverable                                                                                 |
| ----------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------- |
| [01 — Foundation](2026-09-13-scaffold-01-foundation.md)                 | project creation, flavors, config, `Result`/`AppError`, l10n, theme and locale persistence, design system, routing shell, bootstrap, coverage gate, CI | a themed app on iOS, Android, and web with a settings screen and a green pipeline           |
| [02 — Networking and auth](2026-09-13-scaffold-02-auth-networking.md)   | dio, three interceptors, single-flight token refresh, secure token storage, auth repository, login screen, router guard, host driver                   | sign in against DummyJSON with a session that survives restarts and refreshes itself        |
| [03 — Products and offline](2026-09-13-scaffold-03-products-offline.md) | drift with a v1 schema dump, DAO, products API, offline-first repository with a TTL, connectivity, list and detail screens                             | a paginated, searchable feature that renders from cache first and degrades honestly offline |
| [04 — Batteries](2026-09-13-scaffold-04-batteries.md)                   | Sentry, analytics, version gate, deep links, push, biometric lock, accessibility gate, Patrol, icons, splash, release automation                       | the production concerns that are expensive to retrofit                                      |

Plans 2, 3, and 4 each depend on every plan before them.

Read the [spec](../specs/2026-09-13-flutter-production-scaffold-design.md) first — the plans argue
from it and do not restate it. Where a plan departs from the obvious approach, the reason is in
[the ADRs](../../decisions/), referenced inline.

## Executing a plan

Each plan is task-by-task with `- [ ]` steps, TDD throughout: write the failing test, watch it
fail, implement, watch it pass, commit. Two ways to run one:

- **Subagent-driven** (recommended) — `superpowers:subagent-driven-development` dispatches a fresh
  subagent per task with two-stage review.
- **Inline** — `superpowers:executing-plans` runs tasks in the current session with batch
  checkpoints.

The "watch it fail" step is not ceremony. A test that has never been seen to fail has not been
shown to test anything.
