# ADR-0014: Store tokens in the platform keystore, not in shared preferences

## Status

Accepted

## Date

2026-09-13

## Context

The refresh token is the long-lived credential in this app: whoever holds it can mint access
tokens until it is revoked. `shared_preferences` writes plaintext to a file that any process
running as the app user — and any backup extraction on a rooted or jailbroken device — can read.
Drift would be no better; SQLite files are not encrypted by default.

## Decision

Store the access and refresh tokens in `flutter_secure_storage` 11.1.1, behind a
`SecureTokenStorage` interface in `core/data/services/storage/`. Native uses Keychain (iOS) and
EncryptedSharedPreferences over the Android Keystore. Non-secret user settings (the resolved theme
mode, the chosen locale) stay in `shared_preferences`, where plaintext is fine.

Web is out of scope for this bearer-token design. `flutter_secure_storage`'s WebCrypto layer over
`localStorage` is readable by any script running in the page origin, so an XSS payload can replay
the token. Production web deployments must move to an httpOnly, Secure, SameSite cookie-backed
session instead of reusing this bearer-token scheme, or must not ship web in the authenticated
scope at all.

## Alternatives Considered

### shared_preferences for everything

- Pros: one dependency, no platform channels, trivially testable
- Cons: plaintext refresh token
- Rejected: the whole point of the refresh design in ADR-0005 is that the refresh token is
  valuable, and this contradicts it

### An encrypted drift database (SQLCipher)

- Pros: one storage engine for cache and credentials
- Cons: needs a key, and the key needs the keystore anyway — so it is the keystore plus a layer
- Rejected: solves the same problem with more moving parts

### httpOnly cookies (web only)

- Pros: the correct answer for a browser; the token never reaches JavaScript
- Cons: requires a backend that sets them; DummyJSON returns tokens in the response body
- Rejected for the scaffold, recommended for real deployments — see Consequences

## Consequences

- On web, `flutter_secure_storage` encrypts with WebCrypto over `localStorage`. That defends
  against casual inspection, not against XSS. This scaffold does not ship web with this
  bearer-token design as a production authentication target: a real web deployment must move
  to httpOnly, Secure, SameSite cookies before going live.
- Secure storage is asynchronous and platform-backed, so tests substitute a fake implementation
  through the interface rather than mocking the plugin channel.
- Logout must clear secure storage and the drift cache together, or the next user of the device
  sees the previous user's cached products.
