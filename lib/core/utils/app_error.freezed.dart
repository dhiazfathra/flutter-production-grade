// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_error.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppError {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AppError);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AppError()';
}


}

/// @nodoc
class $AppErrorCopyWith<$Res>  {
$AppErrorCopyWith(AppError _, $Res Function(AppError) __);
}


/// Adds pattern-matching-related methods to [AppError].
extension AppErrorPatterns on AppError {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( NetworkError value)?  network,TResult Function( UnauthorizedError value)?  unauthorized,TResult Function( NotFoundError value)?  notFound,TResult Function( ServerError value)?  server,TResult Function( UnknownError value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case NetworkError() when network != null:
return network(_that);case UnauthorizedError() when unauthorized != null:
return unauthorized(_that);case NotFoundError() when notFound != null:
return notFound(_that);case ServerError() when server != null:
return server(_that);case UnknownError() when unknown != null:
return unknown(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( NetworkError value)  network,required TResult Function( UnauthorizedError value)  unauthorized,required TResult Function( NotFoundError value)  notFound,required TResult Function( ServerError value)  server,required TResult Function( UnknownError value)  unknown,}){
final _that = this;
switch (_that) {
case NetworkError():
return network(_that);case UnauthorizedError():
return unauthorized(_that);case NotFoundError():
return notFound(_that);case ServerError():
return server(_that);case UnknownError():
return unknown(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( NetworkError value)?  network,TResult? Function( UnauthorizedError value)?  unauthorized,TResult? Function( NotFoundError value)?  notFound,TResult? Function( ServerError value)?  server,TResult? Function( UnknownError value)?  unknown,}){
final _that = this;
switch (_that) {
case NetworkError() when network != null:
return network(_that);case UnauthorizedError() when unauthorized != null:
return unauthorized(_that);case NotFoundError() when notFound != null:
return notFound(_that);case ServerError() when server != null:
return server(_that);case UnknownError() when unknown != null:
return unknown(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  network,TResult Function()?  unauthorized,TResult Function()?  notFound,TResult Function( int statusCode)?  server,TResult Function( Object cause)?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case NetworkError() when network != null:
return network();case UnauthorizedError() when unauthorized != null:
return unauthorized();case NotFoundError() when notFound != null:
return notFound();case ServerError() when server != null:
return server(_that.statusCode);case UnknownError() when unknown != null:
return unknown(_that.cause);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  network,required TResult Function()  unauthorized,required TResult Function()  notFound,required TResult Function( int statusCode)  server,required TResult Function( Object cause)  unknown,}) {final _that = this;
switch (_that) {
case NetworkError():
return network();case UnauthorizedError():
return unauthorized();case NotFoundError():
return notFound();case ServerError():
return server(_that.statusCode);case UnknownError():
return unknown(_that.cause);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  network,TResult? Function()?  unauthorized,TResult? Function()?  notFound,TResult? Function( int statusCode)?  server,TResult? Function( Object cause)?  unknown,}) {final _that = this;
switch (_that) {
case NetworkError() when network != null:
return network();case UnauthorizedError() when unauthorized != null:
return unauthorized();case NotFoundError() when notFound != null:
return notFound();case ServerError() when server != null:
return server(_that.statusCode);case UnknownError() when unknown != null:
return unknown(_that.cause);case _:
  return null;

}
}

}

/// @nodoc


class NetworkError implements AppError {
  const NetworkError();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is NetworkError);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AppError.network()';
}


}




/// @nodoc


class UnauthorizedError implements AppError {
  const UnauthorizedError();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is UnauthorizedError);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AppError.unauthorized()';
}


}




/// @nodoc


class NotFoundError implements AppError {
  const NotFoundError();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is NotFoundError);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AppError.notFound()';
}


}




/// @nodoc


class ServerError implements AppError {
  const ServerError(this.statusCode);
  

 final  int statusCode;

/// Create a copy of AppError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServerErrorCopyWith<ServerError> get copyWith => _$ServerErrorCopyWithImpl<ServerError>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ServerError&&(identical(other.statusCode, statusCode) || other.statusCode == statusCode));
}


@override
int get hashCode {
    return Object.hash(runtimeType,statusCode);
}

@override
String toString() {
    return 'AppError.server(statusCode: $statusCode)';
}


}

/// @nodoc
abstract mixin class $ServerErrorCopyWith<$Res> implements $AppErrorCopyWith<$Res> {
  factory $ServerErrorCopyWith(ServerError value, $Res Function(ServerError) _then) = _$ServerErrorCopyWithImpl;
@useResult
$Res call({
 int statusCode
});




}
/// @nodoc
class _$ServerErrorCopyWithImpl<$Res>
    implements $ServerErrorCopyWith<$Res> {
  _$ServerErrorCopyWithImpl(this._self, this._then);

  final ServerError _self;
  final $Res Function(ServerError) _then;

/// Create a copy of AppError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? statusCode = null,}) {
  return _then(ServerError(
null == statusCode ? _self.statusCode : statusCode // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class UnknownError implements AppError {
  const UnknownError(this.cause);
  

 final  Object cause;

/// Create a copy of AppError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnknownErrorCopyWith<UnknownError> get copyWith => _$UnknownErrorCopyWithImpl<UnknownError>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is UnknownError&&const DeepCollectionEquality().equals(other.cause, cause));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(cause));
}

@override
String toString() {
    return 'AppError.unknown(cause: $cause)';
}


}

/// @nodoc
abstract mixin class $UnknownErrorCopyWith<$Res> implements $AppErrorCopyWith<$Res> {
  factory $UnknownErrorCopyWith(UnknownError value, $Res Function(UnknownError) _then) = _$UnknownErrorCopyWithImpl;
@useResult
$Res call({
 Object cause
});




}
/// @nodoc
class _$UnknownErrorCopyWithImpl<$Res>
    implements $UnknownErrorCopyWith<$Res> {
  _$UnknownErrorCopyWithImpl(this._self, this._then);

  final UnknownError _self;
  final $Res Function(UnknownError) _then;

/// Create a copy of AppError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? cause = null,}) {
  return _then(UnknownError(
null == cause ? _self.cause : cause ,
  ));
}


}

// dart format on
