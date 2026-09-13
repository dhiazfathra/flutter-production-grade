# Scaffold Plan 4 — Batteries Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development
> (recommended) or superpowers:executing-plans to implement this plan task-by-task.
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the production concerns that are expensive to retrofit — crash reporting, analytics,
a version gate, push and deep links, biometric lock, an accessibility gate, and the release
automation — without changing any existing feature's architecture.

**Architecture:** Every platform capability is an interface in `lib/core/platform/` or
`lib/core/observability/` with a no-op or fake default. The vendor implementation is selected by
flavor in `bootstrap`. Nothing above `core/` imports a plugin.

**Tech Stack:** sentry_flutter 9.30.0, package_info_plus 10.2.1, firebase_core 4.14.0,
firebase_messaging 16.6.0, flutter_local_notifications 22.3.1, app_links 7.2.1, local_auth 3.0.2,
patrol 4.9.0, flutter_launcher_icons 0.14.4, flutter_native_splash 2.4.8.

**Spec:** `docs/superpowers/specs/2026-09-13-flutter-production-scaffold-design.md`
(ADRs 0015, 0017, 0018, 0020, 0024, 0025, 0026, 0028, 0029)

**Depends on:** Plans 1, 2, and 3 complete and green.

## Global Constraints

All previous plans' constraints, plus:

- The app must run and pass every test with **no** Firebase configuration files present. Push
  initialisation is skipped when config is absent, and that branch has a test.
- Nothing reaching Sentry may contain a token: `beforeSend` scrubs `Authorization` and the body of
  `/auth/*` requests, and a test asserts it.
- Deep-link and notification payloads are untrusted network input. They are matched against a known
  route table, never passed to the router verbatim (ADR-0020).
- Analytics events are values of a sealed class. No `log(String, Map)` anywhere.
- Biometrics gate an existing session. They never replace the password login (ADR-0024).

---

### Task 1: Error reporter and Sentry

**Files:**

- Create: `lib/core/observability/error_reporter.dart`, `sentry_error_reporter.dart`
- Modify: `lib/bootstrap.dart` — insert startup step 3
- Test: `test/core/observability/error_reporter_test.dart`
- Test: `test/support/recording_error_reporter.dart`

**Interfaces:**

- Consumes: `appConfigProvider`, `Flavor`.
- Produces:
  - `abstract interface class ErrorReporter { Future<void> report(Object error, StackTrace stack, {Map<String, Object?> context}); Future<void> addBreadcrumb(String message); }`
  - `NoopErrorReporter`, `SentryErrorReporter`, `RecordingErrorReporter` (test support).
  - `errorReporterProvider`.
  - `Map<String, dynamic> scrubEvent(Map<String, dynamic> event)` — the `beforeSend` body, extracted
    as a pure function so it is testable without the Sentry SDK.

- [ ] **Step 1: Write the failing scrub test**

```dart
void main() {
  group('scrubEvent', () {
    test('removes the Authorization header', () {
      final scrubbed = scrubEvent({
        'request': {
          'url': 'https://dummyjson.com/products',
          'headers': {'Authorization': 'Bearer secret', 'Accept': 'application/json'},
        },
      });

      final headers = (scrubbed['request'] as Map)['headers'] as Map;
      expect(headers.containsKey('Authorization'), isFalse);
      expect(headers['Accept'], 'application/json');
    });

    test('removes the body of any auth request', () {
      final scrubbed = scrubEvent({
        'request': {
          'url': 'https://dummyjson.com/auth/refresh',
          'data': {'refreshToken': 'secret'},
        },
      });

      expect((scrubbed['request'] as Map).containsKey('data'), isFalse);
    });

    test('leaves a non-auth body alone', () {
      final scrubbed = scrubEvent({
        'request': {'url': 'https://dummyjson.com/products', 'data': {'q': 'phone'}},
      });

      expect(((scrubbed['request'] as Map)['data'] as Map)['q'], 'phone');
    });
  });
}
```

- [ ] **Step 2: Run it and watch it fail**

Run: `fvm flutter test test/core/observability`
Expected: FAIL — missing URI.

- [ ] **Step 3: Write the interface and implementations**

- [ ] **Step 4: Write the failing handler-installation test**

```dart
testWidgets('a widget build error reaches the reporter', (tester) async {
  final reporter = RecordingErrorReporter();
  installErrorHandlers(reporter);

  await tester.pumpWidget(Builder(builder: (_) => throw StateError('boom')));

  expect(reporter.reported, hasLength(1));
  expect(reporter.reported.single.error, isA<StateError>());
});
```

- [ ] **Step 5: Write `installErrorHandlers`**

```dart
void installErrorHandlers(ErrorReporter reporter) {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    reporter.report(details.exception, details.stack ?? StackTrace.empty);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    reporter.report(error, stack);
    return true;
  };
}
```

`runZonedGuarded` wraps the `runApp` call in `bootstrap` and is the third handler. All three are
needed: framework errors, uncaught async errors, and zone errors arrive by different paths, and
installing two of the three loses a category silently.

- [ ] **Step 6: Insert startup step 3 into `bootstrap`**

The `ProviderScope` gains `errorReporterProvider.overrideWithValue(reporter)`, where `reporter` is
`NoopErrorReporter()` in dev and `SentryErrorReporter()` otherwise.

- [ ] **Step 7: Run and commit**

```bash
make gen && make lint && make test
git add -A
git commit -m "feat(observability): report errors through a scrubbed sentry sink"
```

---

### Task 2: Analytics

**Files:**

- Create: `lib/core/observability/analytics_event.dart`, `analytics_service.dart`,
  `analytics_observer.dart`
- Modify: the login and products view models to emit events
- Test: `test/core/observability/analytics_observer_test.dart`
- Test: `test/support/recording_analytics.dart`

**Interfaces:**

- Produces:
  - `sealed class AnalyticsEvent` — `ScreenViewed(String routeName)`, `LoginSucceeded()`,
    `LoginFailed(AppError error)`, `ProductOpened(int id)`, `ThemeChanged(ThemeMode mode)`.
  - `abstract interface class AnalyticsService { Future<void> track(AnalyticsEvent event); }`
  - `AnalyticsObserver extends NavigatorObserver`.

- [ ] **Step 1: Write the failing observer test**

```dart
test('emits ScreenViewed on push with the route name', () {
  final analytics = RecordingAnalytics();
  AnalyticsObserver(analytics).didPush(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: '/products/3'),
      builder: (_) => const SizedBox(),
    ),
    null,
  );

  expect(analytics.events.single, const ScreenViewed('/products/3'));
});

test('ignores routes with no name rather than emitting an empty event', () { ... });
```

- [ ] **Step 2–4: Implement, run, wire the observer into `routerProvider`'s `observers`**

- [ ] **Step 5: Add the view-model emission test**

```dart
test('a failed login reports the mapped error', () async {
  when(repository.login(...)).thenAnswer((_) async => const Result.err(AppError.unauthorized()));

  await viewModel.submit(username: 'x', password: 'y');

  expect(analytics.events, contains(const LoginFailed(AppError.unauthorized())));
});
```

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat(observability): add a sealed analytics event set"
```

---

### Task 3: Version gate

**Files:**

- Create: `lib/core/utils/semantic_version.dart`
- Create: `lib/core/data/services/remote_config/version_gate_repository.dart`
- Create: `lib/features/update/ui/views/force_update_screen.dart`
- Modify: `lib/routing/router.dart` — the redirect gains the gate
- Modify: `lib/bootstrap.dart` — startup step 5
- Test: `test/core/utils/semantic_version_test.dart`
- Test: `test/routing/update_gate_test.dart`

**Interfaces:**

- Produces:
  - `class SemanticVersion implements Comparable<SemanticVersion>` with
    `factory SemanticVersion.parse(String)`.
  - `abstract interface class VersionGateRepository { Future<String> minimumSupportedVersion(); }`
  - `updateRequiredProvider` — a `bool` the router redirect reads first.
  - `ForceUpdateRoute`, key `update_now_button`.

- [ ] **Step 1: Write the failing comparison test**

```dart
test('compares numerically, not lexicographically', () {
  expect(SemanticVersion.parse('1.10.0').compareTo(SemanticVersion.parse('1.9.0')), greaterThan(0));
});

test('treats a missing patch as zero', () {
  expect(SemanticVersion.parse('2.1'), SemanticVersion.parse('2.1.0'));
});

test('ignores build metadata from package_info', () {
  expect(SemanticVersion.parse('1.2.3+45'), SemanticVersion.parse('1.2.3'));
});

test('throws FormatException on garbage rather than silently passing the gate', () {
  expect(() => SemanticVersion.parse('banana'), throwsFormatException);
});
```

`1.10.0 > 1.9.0` is the case that a string comparison gets wrong, and it is the case that ships a
broken gate.

- [ ] **Step 2: Write the failing gate-order test**

```dart
test('the update gate wins over the auth redirect', () {
  expect(
    redirectFor(const AuthSignedOut(), '/products', updateRequired: true),
    const ForceUpdateRoute().location,
  );
});

test('a remote lookup failure fails open', () async {
  when(repository.minimumSupportedVersion()).thenThrow(const AppError.network());
  expect(await isUpdateRequired(repository, current: '1.0.0'), isFalse);
});
```

Fail open is deliberate (ADR-0017): a gate that fails closed turns a config outage into an app-wide
outage.

- [ ] **Step 3–5: Implement, run, commit**

```bash
git add -A
git commit -m "feat(update): gate startup on a minimum supported version"
```

---

### Task 4: Deep links

**Files:**

- Create: `lib/core/platform/deep_link_service.dart`
- Create: `lib/routing/deep_link_mapper.dart`
- Modify: `lib/routing/router.dart` — consume `pendingDeepLinkProvider` in the redirect
- Test: `test/routing/deep_link_mapper_test.dart`

**Interfaces:**

- Produces:
  - `String? routeForLink(Uri uri)` — pure, table-driven, the security boundary.
  - `abstract interface class DeepLinkService { Stream<Uri> get links; Future<Uri?> initialLink(); }`
  - `pendingDeepLinkProvider` — `String?`, set when a link arrives while signed out, cleared when
    consumed.

- [ ] **Step 1: Write the failing mapper test — the hostile cases first**

```dart
group('routeForLink', () {
  test('maps a known product link', () {
    expect(routeForLink(Uri.parse('https://fpg.app/products/3')), '/products/3');
  });

  test('rejects an unknown path', () {
    expect(routeForLink(Uri.parse('https://fpg.app/admin/delete-everything')), isNull);
  });

  test('rejects a traversal attempt', () {
    expect(routeForLink(Uri.parse('https://fpg.app/products/../admin')), isNull);
  });

  test('rejects a non-numeric product id', () {
    expect(routeForLink(Uri.parse('https://fpg.app/products/abc')), isNull);
  });

  test('rejects a foreign host', () {
    expect(routeForLink(Uri.parse('https://evil.example/products/3')), isNull);
  });
});
```

The mapper allows a known shape and rejects everything else. It is not a sanitiser that strips bad
input — a rejection list is a guessing game, an allow list is not.

- [ ] **Step 2: Write the failing held-link test**

```dart
test('a link arriving while signed out is replayed after login', () async {
  container.read(pendingDeepLinkProvider.notifier).set('/products/3');

  expect(redirectFor(const AuthSignedOut(), '/products/3'), '/login');

  await signIn();

  expect(redirectFor(const AuthSignedIn(user: _user), '/login'), '/products/3');
  expect(container.read(pendingDeepLinkProvider), isNull); // consumed exactly once
});
```

- [ ] **Step 3–5: Implement, run, commit**

```bash
git add -A
git commit -m "feat(routing): resolve deep links through the router guard"
```

---

### Task 5: Push notifications

**Files:**

- Create: `lib/core/platform/push_service.dart`, `firebase_push_service.dart`,
  `noop_push_service.dart`
- Create: `firebase_options_example.dart`, `android/app/google-services.example.json`
- Modify: `lib/bootstrap.dart` — startup step 6
- Modify: `.gitignore`
- Test: `test/core/platform/push_service_test.dart`

**Interfaces:**

- Consumes: `routeForLink` / a payload variant `routeForPayload(Map<String, dynamic>)` (Task 4).
- Produces:
  - `abstract interface class PushService { Future<void> initialise(); Stream<String> get taps; Future<bool> requestPermission(); }`
  - `NoopPushService` — used when Firebase config is absent and in every test.

- [ ] **Step 1: Write the failing absent-config test**

```dart
test('initialisation is skipped and the app still starts with no firebase config', () async {
  final service = resolvePushService(hasFirebaseConfig: false);

  expect(service, isA<NoopPushService>());
  await service.initialise(); // must not throw
  expect(await service.taps.isEmpty, isTrue);
});
```

This is the test that keeps a fresh clone runnable. If it ever goes red, `make run-dev` fails for
anyone without the private config files.

- [ ] **Step 2: Write the failing payload test**

```dart
test('a payload route is matched against the route table, not pushed verbatim', () {
  expect(routeForPayload({'route': '/products/3'}), '/products/3');
  expect(routeForPayload({'route': '/admin'}), isNull);
  expect(routeForPayload({}), isNull);
  expect(routeForPayload({'route': 42}), isNull);
});
```

- [ ] **Step 3–5: Implement, gitignore the real config files, commit examples**

```gitignore
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
lib/firebase_options.dart
```

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat(push): add optional firebase messaging behind an interface"
```

---

### Task 6: Biometric lock

**Files:**

- Create: `lib/core/platform/biometric_service.dart`
- Create: `lib/core/ui/widgets/app_lock_overlay.dart`
- Create: `lib/features/settings/ui/view_models/biometric_settings_view_model.dart`
- Test: `test/core/ui/widgets/app_lock_overlay_test.dart`

**Interfaces:**

- Produces:
  - `abstract interface class BiometricService { Future<bool> isAvailable(); Future<bool> authenticate(String reason); }`
  - `AppLockOverlay` above the router, key `app_lock_overlay`.
  - Settings toggle, key `biometric_toggle`.

- [ ] **Step 1: Write the failing lock tests**

```dart
testWidgets('locks after the background timeout and unlocks on success', ...);
testWidgets('does not lock when the setting is off', ...);
testWidgets('a failed authentication signs out rather than falling through', ...);
testWidgets('the toggle is hidden when biometrics are unavailable', ...);
testWidgets('the toggle is hidden on web', ...);
```

The third is the one that matters: a failure must not leave the app unlocked behind the overlay.

- [ ] **Step 2–4: Implement, run, commit**

```bash
git add -A
git commit -m "feat(auth): add opt-in biometric session lock"
```

---

### Task 7: Accessibility gate

**Files:**

- Create: `test/support/a11y.dart`
- Modify: every screen test to call the helper
- Modify: `lib/l10n/*.arb` — add semantics labels

**Interfaces:**

- Produces: `Future<void> expectAccessible(WidgetTester tester)` asserting all four guidelines.

- [ ] **Step 1: Write the helper**

```dart
Future<void> expectAccessible(WidgetTester tester) async {
  final handle = tester.ensureSemantics();
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
  handle.dispose();
}
```

- [ ] **Step 2: Run it against every existing screen and expect failures**

Run: `fvm flutter test`
Expected: FAIL on at least the icon-only buttons and any tap target under 48dp. Fix the widgets,
not the helper. Note in the commit which widgets needed changing — that list is the honest measure
of how much this was worth.

- [ ] **Step 3: Add the textScale 2.0 goldens**

One per screen. Overflow shows up as a visible golden diff.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "test(a11y): enforce tap target, label, and contrast guidelines"
```

---

### Task 8: Patrol tests for native dialogs

**Files:**

- Create: `integration_test/patrol/permissions_test.dart`, `biometric_test.dart`
- Modify: `android/app/src/androidTest/.../MainActivityTest.java`
- Modify: `Makefile`, `.github/workflows/ci.yaml`

**Interfaces:**

- Consumes: the real `FirebasePushService` and `LocalAuthBiometricService` — this is the only place
  they are exercised.

- [ ] **Step 1: Write the failing permission test**

```dart
patrolTest('granting notification permission enables push', ($) async {
  await $.pumpWidgetAndSettle(const App());
  await $(const ValueKey('enable_push')).tap();
  await $.native.grantPermissionWhenInUse();
  await $(const ValueKey('push_enabled_indicator')).waitUntilVisible();
});

patrolTest('denying permission leaves the app usable', ($) async {
  await $.native.denyPermission();
  await $(const ValueKey('products_list')).waitUntilVisible();
});
```

The denial branch is the one that breaks in production and the one nobody tests.

- [ ] **Step 2: Run on an emulator**

Run: `make patrol`
Expected: PASS.

- [ ] **Step 3: Add the separate CI job and commit**

```bash
git add -A
git commit -m "test: cover native permission dialogs with patrol"
```

---

### Task 9: Icons, splash, and release automation

**Files:**

- Modify: `pubspec.yaml` — `flutter_launcher_icons` and `flutter_native_splash` blocks
- Create: `release-please-config.json`, `.release-please-manifest.json`
- Create: `.github/workflows/release.yaml`
- Modify: `README.md`

- [ ] **Step 1: Generate icons and splash**

```bash
fvm dart run flutter_launcher_icons
fvm dart run flutter_native_splash:create
```

- [ ] **Step 2: Verify on a real launch**

Run `make run-dev` on device and web. The splash must not flash the wrong theme — it reads the
stored mode, which is why it comes after Plan 1.

- [ ] **Step 3: Wire release-please**

Conventional commits already required by the contributing guide now produce the changelog and
version bump.

- [ ] **Step 4: Update the README**

Change the status line from "design phase" to a real quick start, and confirm every command in the
command table actually exists in the `Makefile`. Run each one.

- [ ] **Step 5: Final gate**

```bash
make doctor && make lint && make cov && make integration && make patrol
git add -A
git commit -m "chore: add icons, splash, and release automation"
git push
```

Expected: every CI job green.

- [ ] **Step 6: Update ADR-0029**

Mark the items this plan delivered, leave the genuinely deferred ones (remote flags, experiments,
Fastlane) as `Proposed`, and record the date.

---

## Self-Review

**Spec coverage.** Observability (Tasks 1–2), version gate (Task 3), push and deep links
(Tasks 4–5), biometric lock (Task 6), accessibility (Task 7), Patrol (Task 8), icons/splash and
release automation (Task 9). Startup steps 3, 5, and 6 — left as marked insertions by Plan 1
Task 8 — are filled by Tasks 1, 3, and 5 respectively. Everything in ADR-0029's deferred table stays
deferred, and Task 9 Step 6 records that explicitly rather than leaving the ADR stale.

**Placeholder scan.** Tasks 2, 3, 6, and 9 state assertions and named interfaces with partial code,
because each follows a pattern shown in full in Task 1 (interface + noop + vendor + provider
override) or in earlier plans. No step defers a decision; every "implement" step names the exact
file and the exact interface it satisfies.

**Type consistency.** `ErrorReporter`, `AnalyticsService`, `PushService`, `BiometricService`,
`DeepLinkService`, and `VersionGateRepository` all follow the same shape — interface, noop, vendor,
provider — and each has a test double named `Recording*` or `Noop*`. `routeForLink` (Task 4) and
`routeForPayload` (Task 5) share the same route table, declared once in `deep_link_mapper.dart`.
`redirectFor` gains the `updateRequired` parameter in Task 3 and the pending-link consumption in
Task 4; both are shown against the signature introduced in Plan 2 Task 6.
