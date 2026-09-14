# Scaffold Plan 2 — Networking and Authentication Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development
> (recommended) or superpowers:executing-plans to implement this plan task-by-task.
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Sign in against DummyJSON, keep the session in the platform keystore, refresh expired
tokens exactly once under concurrent 401s, and guard every route behind auth state.

**Architecture:** dio with three interceptors in a fixed order (auth, refresh, error), retrofit
for the typed API surface, a repository that maps API models to domain models and returns
`Result<T>`, and a Riverpod notifier holding auth state that the router's `redirect` watches.

**Tech Stack:** dio 5.11.1, retrofit 4.10.0, retrofit_generator 10.2.11,
flutter_secure_storage 11.1.1, alice 1.2.0, pretty_dio_logger 1.4.0, mockito 5.8.1.

**Spec:** `docs/superpowers/specs/2026-09-13-flutter-production-scaffold-design.md`
(ADRs 0005, 0006, 0007, 0008, 0012, 0014, 0023)

**Depends on:** Plan 1 complete and green.

## Global Constraints

All of Plan 1's constraints, plus:

- Backend is `https://dummyjson.com`. Demo credentials `emilys` / `emilyspass` are public sample
  credentials, not secrets; they may appear in the login screen and in tests.
- No code above the data layer catches `DioException`. Ever.
- Tokens never touch `shared_preferences`, never appear in a log line, and are scrubbed from
  anything the error reporter sends.
- alice and pretty_dio_logger are registered only under `kDebugMode` (ADR-0012).
- Every repository method returns `Future<Result<T>>`.
- Refresh happens in exactly one place: `RefreshInterceptor`.

---

### Task 1: API models and the retrofit client

**Files:**

- Create: `lib/features/auth/data/models/login_request_api_model.dart`,
  `auth_response_api_model.dart`, `refresh_request_api_model.dart`
- Create: `lib/features/auth/data/services/auth_api_service.dart`
- Test: `test/features/auth/data/models/auth_response_api_model_test.dart`

**Interfaces:**

- Consumes: nothing from other tasks.
- Produces:
  - `AuthResponseApiModel` with `id`, `username`, `email`, `firstName`, `lastName`, `image`,
    `accessToken`, `refreshToken`, and `fromJson` / `toJson`.
  - `AuthApiService` (retrofit) with
    `Future<AuthResponseApiModel> login(LoginRequestApiModel body)` on `POST /auth/login`,
    `Future<AuthResponseApiModel> refresh(RefreshRequestApiModel body)` on `POST /auth/refresh`,
    and `Future<AuthResponseApiModel> me()` on `GET /auth/me`.

- [ ] **Step 1: Write the failing serialization test**

```dart
import 'dart:convert';

import 'package:flutter_production_grade/features/auth/data/models/auth_response_api_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses the DummyJSON login response shape', () {
    const raw = '''
{"id":1,"username":"emilys","email":"emily@x.com","firstName":"Emily",
 "lastName":"Johnson","image":"https://img","accessToken":"at","refreshToken":"rt"}''';

    final model = AuthResponseApiModel.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );

    expect(model.id, 1);
    expect(model.username, 'emilys');
    expect(model.accessToken, 'at');
    expect(model.refreshToken, 'rt');
  });
}
```

- [ ] **Step 2: Run it and watch it fail**

Run: `fvm flutter test test/features/auth/data/models`
Expected: FAIL — missing URI.

- [ ] **Step 3: Write the API models**

```dart
import 'package:json_annotation/json_annotation.dart';

part 'auth_response_api_model.g.dart';

@JsonSerializable()
class AuthResponseApiModel {
  const AuthResponseApiModel({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.image,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthResponseApiModel.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseApiModelFromJson(json);

  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String image;
  final String accessToken;
  final String refreshToken;

  Map<String, dynamic> toJson() => _$AuthResponseApiModelToJson(this);
}
```

API models are `json_serializable`, not freezed — they are wire shapes, not domain values
(ADR-0007). `toString` must never be overridden to include the tokens.

- [ ] **Step 4: Write the retrofit service**

```dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/auth_response_api_model.dart';
import '../models/login_request_api_model.dart';
import '../models/refresh_request_api_model.dart';

part 'auth_api_service.g.dart';

@RestApi()
abstract class AuthApiService {
  factory AuthApiService(Dio dio, {String baseUrl}) = _AuthApiService;

  @POST('/auth/login')
  Future<AuthResponseApiModel> login(@Body() LoginRequestApiModel body);

  @POST('/auth/refresh')
  Future<AuthResponseApiModel> refresh(@Body() RefreshRequestApiModel body);

  @GET('/auth/me')
  Future<AuthResponseApiModel> me();
}
```

- [ ] **Step 5: Generate and run**

Run: `make gen && fvm flutter test test/features/auth`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat(auth): add api models and retrofit client"
```

---

### Task 2: Secure token storage

**Files:**

- Create: `lib/core/data/services/storage/secure_token_storage.dart`
- Test: `test/core/data/services/storage/secure_token_storage_test.dart`
- Test: `test/support/fake_token_storage.dart`

**Interfaces:**

- Consumes: nothing.
- Produces:
  - `class AuthTokens { final String accessToken; final String refreshToken; }`
  - `abstract interface class TokenStorage` with `Future<AuthTokens?> read()`,
    `Future<void> write(AuthTokens tokens)`, `Future<void> clear()`.
  - `SecureTokenStorage implements TokenStorage` over `FlutterSecureStorage`.
  - `FakeTokenStorage` in `test/support/`, used by every later test that needs a session.
  - `tokenStorageProvider`.

- [ ] **Step 1: Write the failing test**

Use `FlutterSecureStorage.setMockInitialValues({})`. Assert: `read()` returns null when empty;
a written pair round-trips; `clear()` empties both keys; and a partially-written state (access
present, refresh absent) reads as null rather than as a half-session.

- [ ] **Step 2: Run it and watch it fail**

Run: `fvm flutter test test/core/data/services/storage/secure_token_storage_test.dart`
Expected: FAIL — missing URI.

- [ ] **Step 3: Write the implementation**

```dart
class SecureTokenStorage implements TokenStorage {
  const SecureTokenStorage(this._storage);

  static const _accessKey = 'auth.accessToken';
  static const _refreshKey = 'auth.refreshToken';

  final FlutterSecureStorage _storage;

  @override
  Future<AuthTokens?> read() async {
    final access = await _storage.read(key: _accessKey);
    final refresh = await _storage.read(key: _refreshKey);
    // A half-written pair is not a session. Treat it as signed out.
    if (access == null || refresh == null) return null;
    return AuthTokens(accessToken: access, refreshToken: refresh);
  }

  @override
  Future<void> write(AuthTokens tokens) async {
    await _storage.write(key: _accessKey, value: tokens.accessToken);
    await _storage.write(key: _refreshKey, value: tokens.refreshToken);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
```

- [ ] **Step 4: Write `FakeTokenStorage`**

An in-memory `TokenStorage` with a public `AuthTokens? tokens` field and a `int clearCount`, so
later tests can assert that a failed refresh cleared the session exactly once.

- [ ] **Step 5: Run**

Run: `fvm flutter test test/core`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat(core): store tokens in the platform keystore"
```

---

### Task 3: Error interceptor and the dio provider

**Files:**

- Create: `lib/core/data/services/api/interceptors/error_interceptor.dart`
- Create: `lib/core/data/services/api/interceptors/auth_interceptor.dart`
- Create: `lib/core/data/services/api/dio_provider.dart`
- Test: `test/core/data/services/api/interceptors/error_interceptor_test.dart`
- Test: `test/core/data/services/api/interceptors/auth_interceptor_test.dart`

**Interfaces:**

- Consumes: `AppError` (Plan 1 Task 2), `TokenStorage` (Task 2), `appConfigProvider` (Plan 1).
- Produces:
  - `class AppException implements Exception { final AppError error; }` — the single exception
    type that escapes the dio layer.
  - `ErrorInterceptor`, which converts every `DioException` into an `AppException`.
  - `AuthInterceptor`, which attaches `Authorization: Bearer <access>` when a session exists and
    skips `/auth/login` and `/auth/refresh`.
  - `@riverpod Dio dio(Ref ref)`.

- [ ] **Step 1: Write the failing mapping test**

```dart
import 'package:dio/dio.dart';
import 'package:flutter_production_grade/core/utils/app_error.dart';
import 'package:flutter_production_grade/core/data/services/api/interceptors/error_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ErrorInterceptor', () {
    AppError mapOf(DioException exception) {
      late AppError captured;
      ErrorInterceptor().onError(
        exception,
        ErrorInterceptorHandler()
          ..let((h) {}), // see Step 3 for the real handler usage
      );
      return captured;
    }

    test('maps status codes to AppError variants', () {
      expect(ErrorInterceptor.toAppError(_response(401)),
          const AppError.unauthorized());
      expect(ErrorInterceptor.toAppError(_response(404)),
          const AppError.notFound());
      expect(ErrorInterceptor.toAppError(_response(503)),
          const AppError.server(503));
    });

    test('maps timeouts and socket failures to network', () {
      expect(
        ErrorInterceptor.toAppError(
          DioException(
            requestOptions: RequestOptions(),
            type: DioExceptionType.connectionTimeout,
          ),
        ),
        const AppError.network(),
      );
    });

    test('maps anything else to unknown', () {
      final error = DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.unknown,
        error: 'boom',
      );
      expect(ErrorInterceptor.toAppError(error), isA<UnknownError>());
    });
  });
}

DioException _response(int status) => DioException(
      requestOptions: RequestOptions(),
      type: DioExceptionType.badResponse,
      response: Response<void>(requestOptions: RequestOptions(), statusCode: status),
    );
```

Drop the unused `mapOf` helper when writing the file — the static `toAppError` is the unit under
test, which is exactly why the mapping lives in a static method rather than inline in `onError`.

- [ ] **Step 2: Run it and watch it fail**

Run: `fvm flutter test test/core/data/services/api`
Expected: FAIL — missing URI.

- [ ] **Step 3: Write `error_interceptor.dart`**

```dart
class AppException implements Exception {
  const AppException(this.error);
  final AppError error;
}

class ErrorInterceptor extends Interceptor {
  static AppError toAppError(DioException e) => switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.connectionError =>
          const AppError.network(),
        DioExceptionType.badResponse => switch (e.response?.statusCode) {
            401 => const AppError.unauthorized(),
            404 => const AppError.notFound(),
            final int code when code >= 500 => AppError.server(code),
            final int code => AppError.server(code),
            null => const AppError.network(),
          },
        _ => AppError.unknown(e.error ?? e),
      };

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: AppException(toAppError(err)),
        response: err.response,
        type: err.type,
      ),
    );
  }
}
```

- [ ] **Step 4: Write `auth_interceptor.dart`**

Skips paths in `{'/auth/login', '/auth/refresh'}`; otherwise reads `TokenStorage` and sets the
header. It never refreshes — that is Task 4's single responsibility.

- [ ] **Step 5: Write `dio_provider.dart`**

```dart
@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final config = ref.watch(appConfigProvider);
  final storage = ref.watch(tokenStorageProvider);

  final client = Dio(
    BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  client.interceptors.addAll([
    AuthInterceptor(storage),
    RefreshInterceptor(storage: storage, baseUrl: config.baseUrl),
    ErrorInterceptor(),
    // Debug only: both retain request bodies including tokens (ADR-0012).
    if (kDebugMode) ...[
      PrettyDioLogger(requestBody: true, requestHeader: true),
      ref.watch(aliceProvider).getDioInterceptor(),
    ],
  ]);

  return client;
}
```

Order matters and is asserted by a test: auth attaches the header, refresh reacts to the 401 the
server returns for it, and error maps whatever is left. `ErrorInterceptor` must be last or the
refresh interceptor sees an `AppException` instead of a `DioException`.

- [ ] **Step 6: Write the order test**

Assert `dio.interceptors.map((i) => i.runtimeType)` starts with
`[AuthInterceptor, RefreshInterceptor, ErrorInterceptor]` in release mode.

- [ ] **Step 7: Run and commit**

```bash
make gen && fvm flutter test test/core
git add -A
git commit -m "feat(core): add dio client with auth and error interceptors"
```

---

### Task 4: Refresh interceptor with a single-flight lock

**Files:**

- Create: `lib/core/data/services/api/interceptors/refresh_interceptor.dart`
- Test: `test/core/data/services/api/interceptors/refresh_interceptor_test.dart`

**Interfaces:**

- Consumes: `TokenStorage` (Task 2), `AuthApiService` (Task 1).
- Produces: `RefreshInterceptor`, and `Stream<void> get onSessionCleared` which
  `AuthStateNotifier` (Task 6) listens to.

This is the one piece of concurrency in the scaffold, and the concurrent case is the whole point
(ADR-0005). Write the concurrency test first and do not let it be the last test.

- [ ] **Step 1: Write the failing concurrency test**

```dart
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RefreshInterceptor', () {
    late int refreshCalls;
    late Dio dio;
    late DioAdapter adapter; // http_mock_adapter

    setUp(() {
      refreshCalls = 0;
      // Adapter: /products 401 once per token, /auth/refresh increments
      // refreshCalls and returns a new token pair.
    });

    test('three concurrent 401s trigger exactly one refresh', () async {
      final responses = await Future.wait([
        dio.get<void>('/products?skip=0'),
        dio.get<void>('/products?skip=20'),
        dio.get<void>('/products?skip=40'),
      ]);

      expect(refreshCalls, 1);
      expect(responses.every((r) => r.statusCode == 200), isTrue);
    });

    test('a failed refresh clears the session exactly once', () async {
      // adapter: /auth/refresh returns 401
      await expectLater(
        dio.get<void>('/products'),
        throwsA(isA<DioException>()),
      );
      expect(storage.clearCount, 1);
      expect(await storage.read(), isNull);
    });

    test('replayed requests carry the new token, not the old one', () async {
      await dio.get<void>('/products');
      expect(adapter.lastRequestHeaders['Authorization'], 'Bearer new-access');
    });
  });
}
```

Add `http_mock_adapter` to `dev_dependencies` for this task.

- [ ] **Step 2: Run it and watch it fail**

Run: `fvm flutter test test/core/data/services/api/interceptors/refresh_interceptor_test.dart`
Expected: FAIL — missing URI.

- [ ] **Step 3: Write the interceptor**

```dart
class RefreshInterceptor extends Interceptor {
  RefreshInterceptor({required this.storage, required this.baseUrl});

  final TokenStorage storage;
  final String baseUrl;

  /// Non-null while a refresh is in flight. Every concurrent 401 awaits this
  /// same future, so exactly one refresh call reaches the server.
  Future<AuthTokens?>? _inFlight;

  final _sessionCleared = StreamController<void>.broadcast();
  Stream<void> get onSessionCleared => _sessionCleared.stream;

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final isRefreshCall = err.requestOptions.path == '/auth/refresh';
    if (!isUnauthorized || isRefreshCall) {
      return handler.next(err);
    }

    final tokens = await (_inFlight ??= _refresh());
    if (tokens == null) {
      return handler.next(err);
    }

    try {
      final retry = await _replay(err.requestOptions, tokens.accessToken);
      handler.resolve(retry);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<AuthTokens?> _refresh() async {
    try {
      final current = await storage.read();
      if (current == null) return null;
      final refreshed = await _bareClient().post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': current.refreshToken},
      );
      final tokens = AuthTokens(
        accessToken: refreshed.data!['accessToken'] as String,
        refreshToken: refreshed.data!['refreshToken'] as String,
      );
      await storage.write(tokens);
      return tokens;
    } on DioException {
      await storage.clear();
      _sessionCleared.add(null);
      return null;
    } finally {
      _inFlight = null;
    }
  }
}
```

`_bareClient()` is a fresh `Dio` with no interceptors — refreshing through the instrumented client
would recurse into this interceptor on a 401.

- [ ] **Step 4: Run the tests**

Run: `fvm flutter test test/core/data/services/api/interceptors/refresh_interceptor_test.dart`
Expected: PASS, 3 tests. If `refreshCalls` is 3, `_inFlight` is being assigned after the await
rather than at it — the `??=` must happen in the same synchronous turn as the read.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat(core): refresh tokens once under concurrent 401s"
```

---

### Task 5: Domain models and the auth repository

**Files:**

- Create: `lib/features/auth/domain/models/user.dart`, `auth_session.dart`
- Create: `lib/features/auth/data/repositories/auth_repository.dart`,
  `auth_repository_remote.dart`
- Test: `test/features/auth/data/repositories/auth_repository_remote_test.dart`
- Create: `test/support/mocks.dart` with `@GenerateMocks([AuthApiService])`

**Interfaces:**

- Consumes: `AuthApiService`, `TokenStorage`, `AppException`, `Result`.
- Produces:
  - `@freezed class User` with `id`, `username`, `email`, `fullName`, `imageUrl`.
  - `abstract interface class AuthRepository` with
    `Future<Result<User>> login({required String username, required String password})`,
    `Future<Result<User?>> restoreSession()`, `Future<void> logout()`.
  - `authRepositoryProvider`.

- [ ] **Step 1: Write the failing repository test**

```dart
@GenerateMocks([AuthApiService])
import 'auth_repository_remote_test.mocks.dart';

void main() {
  late MockAuthApiService api;
  late FakeTokenStorage storage;
  late AuthRepositoryRemote repository;

  setUp(() {
    api = MockAuthApiService();
    storage = FakeTokenStorage();
    repository = AuthRepositoryRemote(api: api, storage: storage);
  });

  group('login', () {
    test('persists the tokens and returns the domain user', () async {
      when(api.login(any)).thenAnswer((_) async => _response);

      final result = await repository.login(
        username: 'emilys',
        password: 'emilyspass',
      );

      expect(result.valueOrNull?.username, 'emilys');
      expect(result.valueOrNull?.fullName, 'Emily Johnson');
      expect(storage.tokens?.accessToken, 'at');
    });

    test('returns Err and stores nothing on bad credentials', () async {
      when(api.login(any)).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          error: const AppException(AppError.unauthorized()),
        ),
      );

      final result = await repository.login(username: 'x', password: 'y');

      expect(result.errorOrNull, const AppError.unauthorized());
      expect(storage.tokens, isNull);
    });
  });

  group('restoreSession', () {
    test('returns Ok(null) when there is no stored session', () async {
      expect((await repository.restoreSession()).valueOrNull, isNull);
      verifyNever(api.me());
    });
  });

  test('logout clears storage even when the api call fails', () async {
    storage.tokens = const AuthTokens(accessToken: 'a', refreshToken: 'r');
    await repository.logout();
    expect(storage.tokens, isNull);
  });
}
```

- [ ] **Step 2: Run it and watch it fail**

Run: `make gen && fvm flutter test test/features/auth/data/repositories`
Expected: FAIL — missing URI.

- [ ] **Step 3: Write `user.dart`**

```dart
@freezed
abstract class User with _$User {
  const factory User({
    required int id,
    required String username,
    required String email,
    required String fullName,
    required String imageUrl,
  }) = _User;
}
```

Pure Dart — no `json_serializable` on the domain model, no `fromJson`. Mapping lives in the
repository (ADR-0007).

- [ ] **Step 4: Write the repository**

`login` calls the API inside a `try`, writes tokens, maps the API model to `User`, and returns
`Result.ok`. The `catch` clause catches `DioException` and unwraps `AppException`, defaulting to
`AppError.unknown` — and this is the last place in the codebase that catches a dio type.

- [ ] **Step 5: Run**

Run: `fvm flutter test test/features/auth`
Expected: PASS, 5 tests.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat(auth): add domain user and auth repository"
```

---

### Task 6: Auth state and the router guard

**Files:**

- Create: `lib/features/auth/ui/view_models/auth_state_notifier.dart`
- Modify: `lib/routing/router.dart` (add the redirect)
- Create: `lib/routing/routes.dart` (add `LoginRoute`)
- Test: `test/routing/auth_redirect_test.dart`

**Interfaces:**

- Consumes: `AuthRepository`, `RefreshInterceptor.onSessionCleared`.
- Produces:
  - `sealed class AuthState` — `AuthUnknown`, `AuthSignedOut`, `AuthSignedIn(User user)`.
  - `@riverpod class AuthStateNotifier extends _$AuthStateNotifier` with `AuthState build()`,
    `Future<void> restore()`, `Future<Result<void>> signIn(...)`, `Future<void> signOut()`.
  - The router's `redirect`, the only auth guard in the app.

- [ ] **Step 1: Write the failing redirect test**

Table-driven, because the interesting part is the matrix, not any single case:

```dart
const cases = <({AuthState state, String from, String? to})>[
  (state: AuthUnknown(), from: '/', to: null),
  (state: AuthSignedOut(), from: '/', to: '/login'),
  (state: AuthSignedOut(), from: '/login', to: null),
  (state: AuthSignedIn(user: _user), from: '/login', to: '/'),
  (state: AuthSignedIn(user: _user), from: '/settings', to: null),
];

for (final c in cases) {
  test('${c.state.runtimeType} at ${c.from} redirects to ${c.to}', () {
    expect(redirectFor(c.state, c.from), c.to);
  });
}
```

Extract `String? redirectFor(AuthState state, String location)` as a top-level pure function so
this test needs no router, no widget, and no pump.

- [ ] **Step 2: Run it and watch it fail**

Run: `fvm flutter test test/routing/auth_redirect_test.dart`
Expected: FAIL.

- [ ] **Step 3: Write `redirectFor` and wire it into the router**

```dart
String? redirectFor(AuthState state, String location) {
  final isLoginRoute = location == const LoginRoute().location;
  return switch (state) {
    AuthUnknown() => null,
    AuthSignedOut() => isLoginRoute ? null : const LoginRoute().location,
    AuthSignedIn() => isLoginRoute ? const HomeRoute().location : null,
  };
}
```

In `routerProvider`, `redirect: (context, state) => redirectFor(ref.read(authStateNotifierProvider), state.matchedLocation)`,
with `refreshListenable` driven by a `ValueNotifier` the notifier ticks on every state change.

- [ ] **Step 4: Write the notifier**

`build()` returns `const AuthUnknown()` and kicks off `restore()`. It subscribes to
`onSessionCleared` and moves to `AuthSignedOut` when the refresh interceptor gives up — that is
how an expired session becomes a navigation without any screen knowing about tokens.

- [ ] **Step 5: Run**

Run: `make gen && fvm flutter test`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat(auth): add auth state and the router redirect guard"
```

---

### Task 7: Login screen

**Files:**

- Create: `lib/features/auth/ui/view_models/login_view_model.dart`
- Create: `lib/features/auth/ui/views/login_screen.dart`
- Create: `lib/core/utils/validators.dart`
- Test: `test/core/utils/validators_test.dart`
- Test: `test/features/auth/ui/views/login_screen_test.dart`

**Interfaces:**

- Consumes: `AuthStateNotifier`, design system widgets, `context.l10n`.
- Produces: `LoginViewModel` with `AsyncValue<void> build()` and
  `Future<void> submit({required String username, required String password})`.
  Keys: `login_email_field`, `login_password_field`, `login_submit`.

- [ ] **Step 1: Write the failing validator test**

Cases: empty username fails with `required`; a username under three characters fails; a valid one
passes; empty password fails; a password under six characters fails; `combine` returns the first
failure and null when all pass.

- [ ] **Step 2: Write `validators.dart`**

```dart
typedef Validator = String? Function(String? value);

String? Function(String?) required(String messageKey) =>
    (value) => (value == null || value.trim().isEmpty) ? messageKey : null;

String? Function(String?) minLength(int n, String messageKey) =>
    (value) => (value == null || value.length < n) ? messageKey : null;

Validator combine(List<Validator> validators) => (value) {
      for (final validate in validators) {
        final failure = validate(value);
        if (failure != null) return failure;
      }
      return null;
    };
```

Validators return message keys, not sentences — the widget resolves them through `context.l10n`
(ADR-0023).

- [ ] **Step 3: Write the failing widget test**

```dart
testWidgets('shows a field error and does not call the repository', (tester) async {
  await tester.pumpWidget(_app(overrides: [...]));

  await tester.tap(find.byKey(const ValueKey('login_submit')));
  await tester.pump();

  expect(find.text('Username is required'), findsOneWidget);
  verifyNever(repository.login(username: anyNamed('username'), password: anyNamed('password')));
});

testWidgets('shows a spinner while in flight, then navigates', (tester) async {
  final completer = Completer<Result<User>>();
  when(repository.login(username: anyNamed('username'), password: anyNamed('password')))
      .thenAnswer((_) => completer.future);

  await tester.enterText(find.byKey(const ValueKey('login_email_field')), 'emilys');
  await tester.enterText(find.byKey(const ValueKey('login_password_field')), 'emilyspass');
  await tester.tap(find.byKey(const ValueKey('login_submit')));
  await tester.pump(); // one frame: the spinner, not the result

  expect(find.byType(CircularProgressIndicator), findsOneWidget);

  completer.complete(Result.ok(_user));
  await tester.pumpAndSettle(); // now a navigation transition genuinely needs settling

  expect(find.byType(HomeScreen), findsOneWidget);
});

testWidgets('shows the mapped error on bad credentials', (tester) async { ... });
```

The single `pump()` before the completer completes is the only way to observe the loading state;
`pumpAndSettle()` there would run past it and the assertion would never be able to fail.

- [ ] **Step 4: Write the view model and screen**

The screen is a `ConsumerStatefulWidget` owning two controllers and a `GlobalKey<FormState>`; all
business logic is in the view model. The demo credentials are shown in a hint on the screen.

- [ ] **Step 5: Run the full suite and the gate**

Run: `make gen && make lint && make cov`
Expected: PASS, coverage 100% of measured lines.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat(auth): add login screen with validation and async states"
```

---

### Task 8: Integration test and the host driver

**Files:**

- Create: `integration_test/app_test.dart`, `test_driver/integration_test.dart`
- Create: `integration_test/support/stub_dio.dart`

**Interfaces:**

- Consumes: the whole app.
- Produces: the `make integration` target CI runs, and the stub the Plan 3 integration test
  extends.

- [ ] **Step 1: Write `test_driver/integration_test.dart`**

```dart
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
```

Nothing else belongs in this file. `enableFlutterDriverExtension()` is deliberately not called —
it belongs to legacy `flutter_driver` and would place test-only code in the production entry point
(ADR-0010).

- [ ] **Step 2: Write the failing integration test**

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sign in, open settings, toggle theme, sign out', (tester) async {
    await tester.pumpWidget(
      ProviderScope(overrides: stubOverrides(), child: const App()),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('login_email_field')), 'emilys');
    await tester.enterText(find.byKey(const ValueKey('login_password_field')), 'emilyspass');
    await tester.tap(find.byKey(const ValueKey('login_submit')));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('settings_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('theme_toggle')));
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.byKey(const ValueKey('theme_toggle')))).brightness,
      Brightness.dark,
    );

    await tester.tap(find.byKey(const ValueKey('logout_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('login_submit')), findsOneWidget);
  });
}
```

The network is stubbed (`stubOverrides()` supplies a `Dio` backed by `http_mock_adapter`), so this
test is deterministic and does not depend on DummyJSON being up.

- [ ] **Step 3: Run on Chrome**

```bash
fvm flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart -d chrome \
  --dart-define-from-file=config/dev.json
```

Expected: PASS.

- [ ] **Step 4: Run on a device**

Same command with `-d <device-id>`. Expected: PASS. If it passes on Chrome and fails on device,
the difference is almost always secure storage, which has no web equivalent of the keystore.

- [ ] **Step 5: Commit and push**

```bash
git add -A
git commit -m "test: add end-to-end auth flow with a host driver"
git push
```

Expected: CI green, including the integration job.

---

## Self-Review

**Spec coverage.** Networking (Tasks 1, 3, 4), persistence of tokens (Task 2), error handling
(Task 3), data flow for auth (Task 5), routing guard (Task 6), forms (Task 7), testing levels
unit / widget / integration (Tasks 1–8). Debug-only inspectors are wired in Task 3 Step 5.
Not covered here by design: products and drift (Plan 3), observability, version gate, push,
biometrics (Plan 4).

**Placeholder scan.** Task 2 Steps 1 and 4, Task 3 Step 4, Task 5 Step 4, Task 6 Step 4, and
Task 7 Step 4 state assertions and behaviour precisely but leave mechanical code to the
implementer; every interface they use is named in the task's Interfaces block. The concurrency
test in Task 4 carries a `setUp` comment rather than adapter code because the adapter API is
version-specific; the three assertions are exact.

**Type consistency.** `AuthTokens`, `TokenStorage`, `AppException`, `AppError`, `Result`, `User`,
`AuthState` variants, and `redirectFor` keep identical names across every task that references
them. `FakeTokenStorage` is introduced in Task 2 and reused in Tasks 4 and 5.
`RefreshInterceptor.onSessionCleared` is produced in Task 4 and consumed in Task 6.
