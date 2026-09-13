# ADR-0024: Biometric unlock, opt-in, never the only factor

## Status
Accepted

## Date
2026-09-13

## Context
ADR-0014 puts the refresh token in the platform keystore, which makes a long-lived session
reasonable. A long-lived session on a shared or lost device is also the risk. Biometrics close
that gap, and pairing them with keystore storage is the standard combination.

## Decision
Add `local_auth` 3.0.2 as an opt-in setting, off by default. When on, returning to the foreground
after the app has been backgrounded past a timeout shows a lock screen requiring biometric or
device-credential authentication before the session is used.

Biometrics gate *access to a session that already exists*. They never replace the password login,
and the refresh token is never released on a biometric result alone — the keystore item is read
only after a successful authentication, and a failure signs the user out rather than falling back
to unauthenticated access.

## Alternatives Considered

### Biometric login replacing the password
- Pros: fewer taps
- Cons: the server has authenticated a device, not a person; enrolling a second face or
  fingerprint on the device silently grants account access
- Rejected

### No biometrics
- Pros: one fewer plugin, one fewer platform permission
- Cons: leaves persistent sessions with no local protection
- Rejected: the persistent session is what makes it necessary

## Consequences
- Web has no `local_auth` support; the setting is hidden there, and the code path is
  platform-guarded and tested on both branches.
- Devices with no enrolled biometric fall back to device credentials; devices with neither cannot
  enable the setting, and the UI says why.
- The lock screen sits above the router as an overlay, so it cannot be routed past.
