import 'package:freezed_annotation/freezed_annotation.dart';

import 'app_error.dart';

part 'result.freezed.dart';

@freezed
sealed class Result<T> with _$Result<T> {
  const Result._();

  const factory Result.ok(T value) = Ok<T>;
  const factory Result.err(AppError error) = Err<T>;

  T? get valueOrNull => switch (this) {
        Ok<T>(:final value) => value,
        Err<T>() => null,
      };

  AppError? get errorOrNull => switch (this) {
        Ok<T>() => null,
        Err<T>(:final error) => error,
      };

  R fold<R>({
    required R Function(T value) ok,
    required R Function(AppError error) err,
  }) =>
      switch (this) {
        Ok<T>(value: final v) => ok(v),
        Err<T>(error: final e) => err(e),
      };
}
