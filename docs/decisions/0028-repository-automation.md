# ADR-0028: Local hooks, dependency bots, and release automation

## Status
Accepted

## Date
2026-09-13

## Context
CI already gates format, analyze, custom_lint, codegen freshness, coverage, and builds (ADR-0010).
Three gaps remain: the feedback loop is a CI round trip for errors a pre-commit hook catches in
seconds; dependency updates depend on somebody remembering; and release notes are written by hand
from commit archaeology.

## Decision
- **`lefthook`** for pre-commit: `dart format` and `flutter analyze` on staged Dart files only.
  It must stay under a few seconds, because a slow hook is a hook people want to bypass — and
  bypassing hooks is not permitted in this repository, so the hook has to earn its place.
- **Renovate** for pub and GitHub Actions, grouped, with a weekly schedule. Chosen over Dependabot
  for grouping and for its handling of the `build_runner` toolchain, which must move together.
- **`release-please`** driven by the conventional commits the contributing guide already requires,
  producing the changelog, the version bump in `pubspec.yaml`, and the tag.
- **Codecov** upload so the coverage number is visible on the pull request rather than only as a
  job exit code.
- **`build_runner` output caching** keyed on `pubspec.lock` plus the annotated sources, since
  codegen otherwise dominates the CI run.
- **`very_good_analysis` 11.0.0** as the lint base, on top of which `custom_lint` and
  `riverpod_lint` run.

## Alternatives Considered

### Husky-style hooks via a shell script in `.git/hooks`
- Pros: no dependency
- Cons: not versioned, not installed for new clones
- Rejected

### Dependabot
- Pros: zero configuration, built into GitHub
- Cons: one pull request per package; splitting `build_runner` and its generators across separate
  pull requests produces a broken intermediate state
- Rejected for grouping alone

### Manual changelog
- Pros: prose is better than generated bullets
- Cons: it stops happening by the third release
- Rejected; a curated summary can still be added on top of the generated file

## Consequences
- The pre-commit hook must never be bypassed. If it blocks, the fix is the reported problem.
- Renovate will open pull requests that fail CI when a dependency genuinely breaks; that is the
  system working, and those pull requests are not auto-merged.
- `release-please` makes commit message quality load-bearing, which the contributing guide already
  demanded but nothing enforced.
