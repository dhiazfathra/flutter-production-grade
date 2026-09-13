# ADR-0025: An accessibility baseline enforced in tests

## Status

Accepted

## Date

2026-09-13

## Context

Accessibility added late is a rewrite: it changes widget structure, contrast tokens, and layout
constraints at once. A scaffold that ships without it teaches every feature built on top to ship
without it too.

Flutter provides `meetsGuideline` matchers, so the baseline can be a test rather than a review
convention that decays.

## Decision

Every design-system widget and every screen carries semantics labels, sourced from the
localization files rather than hardcoded. A shared test helper asserts
`androidTapTargetGuideline`, `iOSTapTargetGuideline`, `labeledTapTargetGuideline`, and
`textContrastGuideline` for each screen in light and dark.

Text scale is honoured up to 2.0 and clamped above it; each screen has a golden at 2.0 that must
not overflow. Icon-only buttons require a tooltip or a semantics label — enforced by the same
helper, which fails on an unlabeled tappable.

## Alternatives Considered

### Manual review / a screen-reader pass before release

- Pros: catches things automation cannot, like label quality
- Cons: unrepeatable, and it never happens under deadline
- Rejected as the only mechanism; still valuable as a supplement

### Unbounded text scaling

- Pros: maximally accommodating
- Cons: layouts break past roughly 2.0 and the result is unusable rather than accessible
- Rejected in favour of clamping with a tested ceiling

## Consequences

- Contrast guidelines constrain the seed colour: a seed that generates a failing colour scheme is
  caught by the test, not by a user.
- The guideline matchers check mechanics, not meaning. A label reading "Button" passes and is
  still useless; label quality stays a review item.
- Text-scale goldens double the golden count for screens.
