# ADR-0026: Patrol only for flows that cross into native UI

## Status
Accepted

## Date
2026-09-13

## Context
`integration_test` (ADR-0010) drives the Flutter tree and cannot touch anything outside it. Three
flows in this scaffold now do exactly that: the notification permission prompt (ADR-0020), the
biometric prompt (ADR-0024), and any system dialog raised by a plugin. Those prompts are OS
windows, so a normal integration test sees the app frozen behind a dialog it cannot dismiss.

## Decision
Keep `integration_test` as the default for everything in-app. Add `patrol` 4.9.0 for the specific
tests that must dismiss or accept native dialogs, in `integration_test/patrol/`, run by a separate
`make patrol` target and a separate CI job on Android only.

## Alternatives Considered

### Patrol for all integration tests
- Pros: one tool
- Cons: a custom test runner and native build changes for every test, including the many that need
  none; no web support, and web is a target
- Rejected: paying that cost on the whole suite to serve three tests

### Never test the permission paths
- Pros: no tooling
- Cons: permission-denied is the branch that breaks in production and is never exercised
- Rejected

### Pre-grant permissions and skip the prompt
- Pros: works with plain `integration_test`
- Cons: only tests the happy branch, which is the one that already works
- Rejected

## Consequences
- Patrol tests do not run on web or in the main test job; they are a separate, slower, Android-only
  signal and are allowed to be.
- Patrol requires its own native test harness setup in the Android project; that is committed and
  documented rather than left to be rediscovered.
- If the Android emulator job proves flaky, the response is to quarantine that job, not to delete
  the tests.
