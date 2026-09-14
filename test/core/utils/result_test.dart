import 'package:flutter_production_grade/core/utils/app_error.dart';
import 'package:flutter_production_grade/core/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    test('Ok exposes its value and no error', () {
      const result = Result<int>.ok(3);
      expect(result.valueOrNull, 3);
      expect(result.errorOrNull, isNull);
    });

    test('Err exposes its error and no value', () {
      const result = Result<int>.err(AppError.unauthorized());
      expect(result.valueOrNull, isNull);
      expect(result.errorOrNull, const AppError.unauthorized());
    });

    test('fold runs exactly one branch', () {
      const ok = Result<int>.ok(1);
      const err = Result<int>.err(AppError.network());
      expect(ok.fold(ok: (v) => 'v$v', err: (_) => 'e'), 'v1');
      expect(err.fold(ok: (v) => 'v$v', err: (_) => 'e'), 'e');
    });

    test('AppError.server carries its status code', () {
      const error = AppError.server(503);
      expect(error, const AppError.server(503));
      expect(error, isNot(const AppError.server(500)));
    });
  });
}
