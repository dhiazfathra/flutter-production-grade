# Scaffold Plan 3 — Products and Offline Cache Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development
> (recommended) or superpowers:executing-plans to implement this plan task-by-task.
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A paginated, searchable products feature that renders from a local database on the first
frame, revalidates from the network, and degrades honestly when the network is gone.

**Architecture:** Drift is the single source of truth for reads. The repository writes through to
drift and the UI watches a drift stream, so a cache write updates the screen without a second
fetch. Freshness is a `fetchedAt` column compared against a TTL, not a flag someone has to remember
to set.

**Tech Stack:** drift 2.35.0, drift_flutter 0.3.1, drift_dev 2.35.0, connectivity_plus 7.3.1,
sqlite3_flutter_libs, retrofit 4.10.0, skeletonizer 3.0.0.

**Spec:** `docs/superpowers/specs/2026-09-13-flutter-production-scaffold-design.md`
(ADRs 0004, 0006, 0007, 0016, 0019, 0021, 0022)

**Depends on:** Plans 1 and 2 complete and green.

## Global Constraints

All of Plan 1 and Plan 2's constraints, plus:

- Reads go through drift. A repository read method never returns network data directly.
- `fetchedAt` is stored in UTC.
- `schemaVersion` starts at 1 and every bump ships a dump in `drift_schemas/` plus a generated
  migration test (ADR-0021).
- Connectivity drives presentation only. No request is ever skipped because the device reports
  offline (ADR-0016).
- Search bypasses the cache — results are transient and must not evict the paginated cache.

---

### Task 1: Drift database with a conditional connection

**Files:**

- Create: `lib/core/data/services/local/app_database.dart`
- Create: `lib/core/data/services/local/connection/native.dart`, `web.dart`, `connection.dart`
- Create: `lib/features/products/data/services/local/tables.dart`
- Create: `drift_schemas/drift_schema_v1.json`
- Test: `test/core/data/services/local/app_database_test.dart`
- Test: `test/support/test_database.dart`

**Interfaces:**

- Consumes: nothing.
- Produces:
  - `class AppDatabase extends _$AppDatabase` with `schemaVersion => 1` and
    `AppDatabase.forTesting(DatabaseConnection)`.
  - `ProductRows` table: `id` (int, primary key), `title`, `description`, `brand` (nullable),
    `category`, `price` (real), `thumbnail`, `page` (int), `fetchedAt` (DateTime).
  - `openConnection()` — `driftDatabase(name:)` on native, `WasmDatabase` on web.
  - `testDatabase()` in `test/support/`, an in-memory `AppDatabase` every later test uses.

- [ ] **Step 1: Write the failing database test**

```dart
import 'package:flutter_production_grade/core/data/services/local/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = testDatabase());
  tearDown(() => db.close());

  test('starts empty', () async {
    expect(await db.select(db.productRows).get(), isEmpty);
  });

  test('upsert replaces a row with the same id', () async {
    await db.into(db.productRows).insertOnConflictUpdate(_row(id: 1, title: 'A'));
    await db.into(db.productRows).insertOnConflictUpdate(_row(id: 1, title: 'B'));

    final rows = await db.select(db.productRows).get();
    expect(rows, hasLength(1));
    expect(rows.single.title, 'B');
  });

  test('schemaVersion is 1', () {
    expect(db.schemaVersion, 1);
  });
}
```

- [ ] **Step 2: Run it and watch it fail**

Run: `fvm flutter test test/core/data/services/local`
Expected: FAIL — missing URI.

- [ ] **Step 3: Write the table and database**

```dart
class ProductRows extends Table {
  IntColumn get id => integer()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  TextColumn get brand => text().nullable()();
  TextColumn get category => text()();
  RealColumn get price => real()();
  TextColumn get thumbnail => text()();
  IntColumn get page => integer()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [ProductRows])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());
  AppDatabase.forTesting(super.connection);

  @override
  int get schemaVersion => 1;
}
```

- [ ] **Step 4: Write the conditional connection**

`connection.dart`:

```dart
export 'native.dart' if (dart.library.js_interop) 'web.dart';
```

`native.dart` returns `driftDatabase(name: 'app')`. `web.dart` returns a `DriftWebOptions`-based
`WasmDatabase.open(databaseName: 'app', sqlite3Uri: Uri.parse('sqlite3.wasm'),
driftWorkerUri: Uri.parse('drift_worker.js'))`.

- [ ] **Step 5: Fetch the web assets**

```bash
curl -L -o web/sqlite3.wasm \
  https://github.com/simolus3/sqlite3.dart/releases/latest/download/sqlite3.wasm
fvm dart run drift_dev make-default-worker
mv drift_worker.js web/drift_worker.js
```

Commit both. A missing asset fails only at runtime on web (ADR-0004), which is why CI asserts their
presence rather than trusting the build.

- [ ] **Step 6: Dump the v1 schema**

```bash
fvm dart run drift_dev schema dump \
  lib/core/data/services/local/app_database.dart drift_schemas/
```

This dump cannot be produced retroactively once v2 exists, which is the entire reason ADR-0021
requires it now.

- [ ] **Step 7: Run and commit**

```bash
make gen && fvm flutter test test/core/data/services/local
git add -A
git commit -m "feat(core): add drift database with a v1 schema dump"
```

---

### Task 2: Products DAO

**Files:**

- Create: `lib/features/products/data/services/local/products_dao.dart`
- Test: `test/features/products/data/services/local/products_dao_test.dart`

**Interfaces:**

- Consumes: `AppDatabase` (Task 1).
- Produces:
  - `Stream<List<ProductRow>> watchPage(int page)`
  - `Future<DateTime?> lastFetchedAt(int page)`
  - `Future<void> upsertPage(int page, List<ProductRow> rows)`
  - `Future<void> clear()` — called on logout.

- [ ] **Step 1: Write the failing DAO test**

Assert: `watchPage(0)` emits `[]` then the inserted rows after an upsert (use
`expectLater(dao.watchPage(0), emitsInOrder([isEmpty, hasLength(2)]))`); `upsertPage` replaces the
page's rows rather than appending duplicates; `lastFetchedAt` returns the newest timestamp for the
page and null for an unfetched page; `clear()` empties every page.

- [ ] **Step 2: Run it and watch it fail**

Run: `fvm flutter test test/features/products/data/services/local`
Expected: FAIL — missing URI.

- [ ] **Step 3: Write the DAO**

`upsertPage` runs inside `transaction()` and uses `insertOnConflictUpdate` per row, so a partial
failure leaves no half-written page.

- [ ] **Step 4: Run and commit**

```bash
make gen && fvm flutter test test/features/products
git add -A
git commit -m "feat(products): add drift dao with reactive page reads"
```

---

### Task 3: Products API and domain models

**Files:**

- Create: `lib/features/products/data/models/product_api_model.dart`,
  `products_page_api_model.dart`
- Create: `lib/features/products/data/services/products_api_service.dart`
- Create: `lib/features/products/domain/models/product.dart`, `paginated.dart`
- Test: `test/features/products/data/models/products_page_api_model_test.dart`

**Interfaces:**

- Consumes: nothing.
- Produces:
  - `ProductsPageApiModel` with `products`, `total`, `skip`, `limit`.
  - `ProductsApiService` with `getPage({int limit, int skip})` on `GET /products` and
    `search({String q})` on `GET /products/search`.
  - `@freezed class Product` with `id`, `title`, `description`, `brand`, `category`, `price`,
    `thumbnail`.
  - `@freezed class Paginated<T>` with `items`, `page`, `total`, and `bool get hasMore`.

- [ ] **Step 1: Write the failing test**

Parse a real DummyJSON `/products?limit=2&skip=0` body (paste an actual response), assert `total`,
`skip`, `limit`, and that `products.first.brand` is null-safe — DummyJSON omits `brand` on some
items, and that omission is exactly the kind of thing that only shows up in production.

- [ ] **Step 2–4: Write the models and service, generate, run**

Run: `make gen && fvm flutter test test/features/products/data/models`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat(products): add api models, service, and domain models"
```

---

### Task 4: Products repository — offline-first with TTL

**Files:**

- Create: `lib/features/products/data/repositories/products_repository.dart`,
  `products_repository_remote.dart`
- Test: `test/features/products/data/repositories/products_repository_remote_test.dart`

**Interfaces:**

- Consumes: `ProductsApiService`, `ProductsDao`, `Result`, `AppError`.
- Produces:
  - `Stream<List<Product>> watchPage(int page)`
  - `Future<Result<void>> revalidate(int page)`
  - `Future<Result<List<Product>>> search(String query)`
  - `static const ttl = Duration(minutes: 10);`

This task holds the caching rules. Write every one of them as a test before any of them as code.

- [ ] **Step 1: Write the failing cache-policy tests**

```dart
group('revalidate', () {
  test('fetches when the page has never been fetched', () async {
    when(api.getPage(limit: 20, skip: 0)).thenAnswer((_) async => _page);

    final result = await repository.revalidate(0);

    expect(result.errorOrNull, isNull);
    verify(api.getPage(limit: 20, skip: 0)).called(1);
    expect(await dao.lastFetchedAt(0), isNotNull);
  });

  test('does not fetch when the cache is inside the TTL', () async {
    await dao.upsertPage(0, [_row(fetchedAt: clock.now())]);

    await repository.revalidate(0);

    verifyNever(api.getPage(limit: anyNamed('limit'), skip: anyNamed('skip')));
  });

  test('fetches when the cache is older than the TTL', () async {
    await dao.upsertPage(0, [
      _row(fetchedAt: clock.now().subtract(const Duration(minutes: 11))),
    ]);

    await repository.revalidate(0);

    verify(api.getPage(limit: 20, skip: 0)).called(1);
  });

  test('keeps the cache and returns Err when the network fails', () async {
    await dao.upsertPage(0, [_row(id: 7, fetchedAt: _stale)]);
    when(api.getPage(limit: 20, skip: 0)).thenThrow(_networkException);

    final result = await repository.revalidate(0);

    expect(result.errorOrNull, const AppError.network());
    expect((await repository.watchPage(0).first).single.id, 7);
  });
});

test('watchPage emits cached rows before any network call', () async {
  await dao.upsertPage(0, [_row(id: 1)]);
  expect(await repository.watchPage(0).first, hasLength(1));
  verifyNever(api.getPage(limit: anyNamed('limit'), skip: anyNamed('skip')));
});

test('search bypasses the cache and writes nothing', () async {
  when(api.search(q: 'phone')).thenAnswer((_) async => _page);

  final result = await repository.search('phone');

  expect(result.valueOrNull, hasLength(2));
  expect(await dao.lastFetchedAt(0), isNull);
});
```

Use `package:clock` and `withClock` for the TTL tests. Advancing a fake clock is deterministic;
`Future.delayed` in a test is a flake waiting to happen.

- [ ] **Step 2: Run and watch them fail**

Run: `fvm flutter test test/features/products/data/repositories`
Expected: FAIL — missing URI.

- [ ] **Step 3: Write the repository**

```dart
@override
Future<Result<void>> revalidate(int page) async {
  final fetchedAt = await _dao.lastFetchedAt(page);
  final isFresh = fetchedAt != null && clock.now().difference(fetchedAt) < ttl;
  if (isFresh) return const Result.ok(null);

  try {
    final response = await _api.getPage(limit: pageSize, skip: page * pageSize);
    await _dao.upsertPage(page, response.products.map(_toRow(page)).toList());
    return const Result.ok(null);
  } on DioException catch (e) {
    // The cache is untouched on failure: stale data beats an empty screen.
    return Result.err(_toAppError(e));
  }
}
```

- [ ] **Step 4: Run**

Run: `fvm flutter test test/features/products`
Expected: PASS, 6 tests.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat(products): add offline-first repository with a ttl"
```

---

### Task 5: Connectivity service

**Files:**

- Create: `lib/core/platform/connectivity_service.dart`
- Create: `lib/core/ui/widgets/offline_banner.dart`
- Test: `test/core/platform/connectivity_service_test.dart`
- Test: `test/core/ui/widgets/offline_banner_test.dart`

**Interfaces:**

- Consumes: nothing.
- Produces:
  - `abstract interface class ConnectivityService { Stream<bool> get onlineChanges; Future<bool> isOnline(); }`
  - `connectivityServiceProvider`, `onlineProvider` (a `StreamProvider<bool>`).
  - `OfflineBanner` with `ValueKey('offline_banner')`.

- [ ] **Step 1: Write the failing test**

Assert that a `ConnectivityResult.none` event maps to `false`, that any other single result maps to
`true`, and that a list containing both `none` and `wifi` maps to `true` —
`connectivity_plus` emits a list, and treating it as a single value is the usual bug.

- [ ] **Step 2–4: Write the service and banner, run**

The banner is a `ConsumerWidget` that returns `SizedBox.shrink()` when online. Widget-test it by
overriding `onlineProvider` — no plugin channel is involved, which is why the interface exists.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat(core): surface connectivity for presentation only"
```

---

### Task 6: Products list screen

**Files:**

- Create: `lib/features/products/ui/view_models/products_list_view_model.dart`
- Create: `lib/features/products/ui/views/products_list_screen.dart`
- Create: `lib/features/products/ui/widgets/product_tile.dart`
- Test: `test/features/products/ui/view_models/products_list_view_model_test.dart`
- Test: `test/features/products/ui/views/products_list_screen_test.dart`

**Interfaces:**

- Consumes: `ProductsRepository`, `onlineProvider`, design system, `context.l10n`.
- Produces: `ProductsListViewModel` with `Stream<List<Product>> build()`, `Future<void> loadMore()`,
  `Future<void> refresh()`, `void search(String query)`.
  Keys: `products_list`, `product_tile_$id`, `products_search_field`, `products_retry`.

- [ ] **Step 1: Write the failing widget tests — all five states**

```dart
testWidgets('shows skeletons while the first page loads', ...);
testWidgets('shows the tiles once data arrives', ...);
testWidgets('shows the empty state when the repository returns nothing', ...);
testWidgets('shows an error view with retry when the cache is empty and the network fails', ...);
testWidgets('shows cached tiles plus the offline banner when the network fails with a cache', ...);
```

The fifth is the one that justifies the whole offline design, and it is the one most likely to be
skipped. Write it.

- [ ] **Step 2: Write the pagination test**

```dart
testWidgets('loads the next page when the list is scrolled to the end', (tester) async {
  await tester.pumpWidget(_app());
  await tester.pumpAndSettle();

  await tester.scrollUntilVisible(
    find.byKey(const ValueKey('product_tile_19')),
    300,
    scrollable: find.byKey(const ValueKey('products_list')),
  );

  verify(repository.revalidate(1)).called(1);
});
```

- [ ] **Step 3: Run and watch them fail**

Run: `fvm flutter test test/features/products/ui`
Expected: FAIL — missing URI.

- [ ] **Step 4: Write the view model and screen**

The screen watches the view model's stream and renders exactly one of: skeletonized tiles, the
tile list, `AppEmptyState`, or `AppErrorView`. The offline banner is above the list, not instead of
it.

- [ ] **Step 5: Run**

Run: `fvm flutter test test/features/products`
Expected: PASS.

- [ ] **Step 6: Add goldens**

Add the four list states to the golden test group, light and dark, plus `textScaleFactor: 2.0`.
Run `make goldens`, inspect the generated images, then `make test`.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "feat(products): add the list screen with all states and pagination"
```

---

### Task 7: Product detail screen

**Files:**

- Create: `lib/features/products/ui/view_models/product_detail_view_model.dart`
- Create: `lib/features/products/ui/views/product_detail_screen.dart`
- Modify: `lib/routing/routes.dart` — add `ProductDetailRoute` with an `int id` path parameter
- Test: `test/features/products/ui/views/product_detail_screen_test.dart`

**Interfaces:**

- Consumes: `ProductsRepository.watchById(int id)` (add it to the repository in this task, with its
  own test).
- Produces: `ProductDetailRoute(id)`, typed, so navigation is `ProductDetailRoute(3).go(context)`
  and never a string.

- [ ] **Step 1: Write the failing tests**

Loading, data, and not-found states. The not-found case matters: a deep link to a deleted product
arrives in Plan 4, and this screen is what it lands on.

- [ ] **Step 2–4: Implement, run, commit**

```bash
git add -A
git commit -m "feat(products): add the typed detail route and screen"
```

---

### Task 8: Logout clears the cache

**Files:**

- Modify: `lib/features/auth/ui/view_models/auth_state_notifier.dart`
- Test: `test/features/auth/ui/view_models/auth_state_notifier_test.dart`

**Interfaces:**

- Consumes: `ProductsDao.clear()` (Task 2), `AuthRepository.logout()` (Plan 2).

- [ ] **Step 1: Write the failing test**

```dart
test('signing out clears tokens and the product cache', () async {
  await notifier.signOut();

  expect(storage.tokens, isNull);
  expect(await dao.lastFetchedAt(0), isNull);
});
```

This is a privacy requirement from ADR-0014, not a tidiness one: the next user of a shared device
must not see the previous user's cached data.

- [ ] **Step 2–4: Implement, run, commit**

```bash
git add -A
git commit -m "fix(auth): clear the product cache on sign out"
```

---

### Task 9: Extend the integration test, verify on web

**Files:**

- Modify: `integration_test/app_test.dart`
- Modify: `.github/workflows/ci.yaml` — add the drift web asset assertion

- [ ] **Step 1: Extend the flow**

Sign in, see the list, scroll to page two, open a detail, go back, search, clear the search, toggle
the theme, sign out. Stubbed network throughout.

- [ ] **Step 2: Run on Chrome — the only place drift-on-web is exercised**

```bash
fvm flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart -d chrome \
  --dart-define-from-file=config/dev.json
```

Expected: PASS. A failure here with a passing native run almost always means a missing or
misplaced `sqlite3.wasm` / `drift_worker.js`.

- [ ] **Step 3: Add the CI asset check**

```yaml
- name: Verify drift web assets
  run: |
    test -f web/sqlite3.wasm || { echo "missing web/sqlite3.wasm"; exit 1; }
    test -f web/drift_worker.js || { echo "missing web/drift_worker.js"; exit 1; }
```

- [ ] **Step 4: Run the whole gate and push**

```bash
make lint && make cov && make integration
git add -A
git commit -m "test: cover the full products flow end to end"
git push
```

Expected: CI green.

---

## Self-Review

**Spec coverage.** Persistence (Tasks 1–2), products data flow steps 1–5 (Tasks 3–4, 6),
connectivity and offline presentation (Task 5), design-system loading states (Task 6), schema
versioning (Task 1 Step 6), web delivery asset check (Task 9). The spec's data-flow item 4
("network failure with a populated cache surfaces a non-blocking banner") is Task 6 Step 1's fifth
test, and item 5 ("search bypasses the cache") is Task 4 Step 1's last test.

**Placeholder scan.** Tasks 2, 3, 5, 7, and 8 state assertions in prose with named interfaces
rather than full code, because each is a mechanical application of a pattern shown in full earlier
in the same plan (Task 1 for drift, Task 4 for the repository, Task 6 for widget states). No step
says "add error handling" or "handle edge cases" — every behaviour named has a test.

**Type consistency.** `ProductRow` (drift-generated), `Product` (domain), and `ProductApiModel`
(wire) stay distinct and are never used interchangeably. `ProductsDao.lastFetchedAt` /
`upsertPage` / `watchPage` / `clear` keep the same signatures in Tasks 2, 4, and 8.
`ProductsRepository.ttl` is referenced by the Task 4 tests and defined in Task 4 Step 3.
`ProductDetailRoute(id)` is declared in Task 7 and used by Plan 4's deep-link mapper.
