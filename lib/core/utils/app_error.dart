import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_error.freezed.dart';

@freezed
sealed class AppError with _$AppError {
  const factory AppError.network() = NetworkError;
  const factory AppError.unauthorized() = UnauthorizedError;
  const factory AppError.notFound() = NotFoundError;
  const factory AppError.server(int statusCode) = ServerError;
  const factory AppError.unknown(Object cause) = UnknownError;
}
