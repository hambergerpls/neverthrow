import 'package:neverthrow/_internals/error.dart';
import 'package:neverthrow/_internals/utils.dart';
import 'package:neverthrow/result_async.dart';

Ok<T, E> ok<T, E>(T value) => Ok<T, E>(value);
Err<T, E> err<T, E>(E error) => Err<T, E>(error);

abstract interface class Result<T, E> {
  static Result<List<T>, E> combine<T, E>(List<Result<T, E>> resultList) =>
      combineResultList(resultList);

  /// TODO: Need to figure out how to wrap the function instead
  static Result<T, E> fromThrowable<T, E>(T Function() fn,
      {E Function(Object?)? errorFn}) {
    try {
      return ok(fn());
    } catch (e) {
      return err(errorFn != null ? errorFn(e) : e as E);
    }
  }

  /// Used to check if a `Result` is an `OK`
  ///
  /// Returns `true` if the result is an `OK` variant of Result
  bool isOk() => throw UnimplementedError();

  /// Used to check if a `Result` is an `Err`
  ///
  /// Returns `true` if the result is an `Err` variant of Result
  bool isErr() => throw UnimplementedError();

  /// Maps a `Result<T, E>` to `Result<U, E>`
  /// by applying a function to a contained `Ok` value, leaving an `Err` value
  /// untouched.
  ///
  /// @param `f` The function to apply an `OK` value
  ///
  /// @returns the result of applying `f` or an `Err` untouched
  Result<A, E> map<A>(A Function(T t) f) => throw UnimplementedError();

  /// Maps a `Result<T, E>` to `Result<T, F>` by applying a function to a
  /// contained `Err` value, leaving an `Ok` value untouched.
  ///
  /// This function can be used to pass through a successful result while
  /// handling an error.
  ///
  /// @param `f` a function to apply to the error `Err` value
  Result<T, U> mapErr<U>(U Function(E error) f) => throw UnimplementedError();

  /// Similar to `map` Except you must return a new `Result`.
  ///
  /// This is useful for when you need to do a subsequent computation using the
  /// inner `T` value, but that computation might fail.
  /// Additionally, `andThen` is really useful as a tool to flatten a
  /// `Result<Result<A, E2>, E1>` into a `Result<A, E2>` (see example below).
  ///
  /// @param `f` The function to apply to the current value
  Result<U, F> andThen<U, F>(Result<U, F> Function(T t) f) =>
      throw UnimplementedError();

  /// Takes an `Err` value and maps it to a `Result<T, SomeNewType>`.
  ///
  /// This is useful for error recovery.
  ///
  ///
  /// @param `f`  A function to apply to an `Err` value, leaving `Ok` values
  /// untouched.
  Result<T, A> orElse<A>(Result<T, A> Function(E error) f) =>
      throw UnimplementedError();

  /// Similar to `map` Except you must return a new `Result`.
  ///
  /// This is useful for when you need to do a subsequent async computation using
  /// the inner `T` value, but that computation might fail. Must return a ResultAsync
  ///
  /// @param `f` The function that returns a `ResultAsync` to apply to the current
  /// value
  ResultAsync<U, F> asyncAndThen<U, F>(ResultAsync<U, F> Function(T t) f) =>
      throw UnimplementedError();

  /// Maps a `Result<T, E>` to `ResultAsync<U, E>`
  /// by applying an async function to a contained `Ok` value, leaving an `Err`
  /// value untouched.
  ///
  /// @param `f` An async function to apply an `OK` value
  ResultAsync<U, E> asyncMap<U>(Future<U> Function(T t) f) =>
      throw UnimplementedError();

  /// Unwrap the `Ok` value, or return the default if there is an `Err`
  ///
  /// @param `v` the default value to return if there is an `Err`
  T unwrapOr(T v) => throw UnimplementedError();

  ///
  /// Given 2 functions (one for the `Ok` variant and one for the `Err` variant)
  /// execute the function that matches the `Result` variant.
  ///
  /// Match callbacks do not necessitate to return a `Result`, however you can
  /// return a `Result` if you want to.
  ///
  /// `match` is like chaining `map` and `mapErr`, with the distinction that
  /// with `match` both functions must have the same return type.
  ///
  /// @param `ok`
  /// @param `err`
  A match<A>(A Function(T t) ok, A Function(E e) err) =>
      throw UnimplementedError();

  /// Emulates Rust's `?` operator in `safeTry`'s body. See also `safeTry`.
  Stream<T> safeUnwrap() => throw UnimplementedError();

  /// **This method is unsafe, and should only be used in a test environments**
  ///
  /// Takes a `Result<T, E>` and returns a `T` when the result is an `Ok`, otherwise it throws a custom object.
  ///
  /// @param `config`
  T unsafeUnwrap({ErrorConfig? config}) => throw UnimplementedError();

  /// **This method is unsafe, and should only be used in a test environments**
  ///
  /// takes a `Result<T, E>` and returns a `E` when the result is an `Err`,
  /// otherwise it throws a custom object.
  ///
  /// @param `config`
  E unsafeUnwrapErr({ErrorConfig? config}) => throw UnimplementedError();

  Ok<T, E> get asOk => throw UnimplementedError();

  Err<T, E> get asErr => throw UnimplementedError();
}

class Ok<T, E> implements Result<T, E> {
  final T value;

  Ok(this.value);

  @override
  T unsafeUnwrap({ErrorConfig? config}) => this.value;

  @override
  E unsafeUnwrapErr({ErrorConfig? config}) =>
      throw createNeverThrowError('Called `_unsafeUnwrapErr` on an Ok', this,
          config: config);

  @override
  Result<U, F> andThen<U, F>(Result<U, F> Function(T t) f) => f(this.value);

  @override
  ResultAsync<U, F> asyncAndThen<U, F>(ResultAsync<U, F> Function(T t) f) =>
      f(this.value);

  @override
  ResultAsync<U, E> asyncMap<U>(Future<U> Function(T t) f) =>
      ResultAsync.fromSafeFuture(f(this.value));

  @override
  bool isErr() => this is Err<T, E>;

  @override
  // ignore: unnecessary_type_check
  bool isOk() => this is Ok<T, E>;

  @override
  Result<A, E> map<A>(A Function(T t) f) => ok(f(this.value));

  @override
  Result<T, U> mapErr<U>(U Function(E error) f) => ok(this.value);

  @override
  A match<A>(A Function(T t) ok, A Function(E e) err) => ok(this.value);

  @override
  Result<T, A> orElse<A>(Result<T, A> Function(E error) f) => ok(this.value);

  @override
  Stream<T> safeUnwrap() {
    // TODO: implement safeUnwrap
    throw UnimplementedError();
  }

  @override
  T unwrapOr(T v) => this.value;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Ok<T, E> &&
        other.isOk() == this.isOk() &&
        other.isErr() == this.isErr() &&
        other.value == this.value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  Err<T, E> get asErr =>
      throw createNeverThrowError('Called `asErr` on an Ok', this);

  @override
  Ok<T, E> get asOk => this;
}

class Err<T, E> implements Result<T, E> {
  final E error;

  Err(this.error);

  @override
  T unsafeUnwrap({ErrorConfig? config}) =>
      throw createNeverThrowError('Called `unsafeUnwrap` on an Err', this,
          config: config);

  @override
  E unsafeUnwrapErr({ErrorConfig? config}) => this.error;

  @override
  Result<U, F> andThen<U, F>(Result<U, F> Function(T t) f) =>
      err<U, F>(this.error as F);

  @override
  ResultAsync<U, F> asyncAndThen<U, F>(ResultAsync<U?, F?> Function(T t) f) =>
      errAsync(this.error as F);

  @override
  ResultAsync<U, E> asyncMap<U>(Future<U> Function(T t) f) =>
      errAsync(this.error);

  @override
  // ignore: unnecessary_type_check
  bool isErr() => this is Err<T, E>;

  @override
  bool isOk() => this is Ok<T, E>;

  @override
  Result<A, E> map<A>(A Function(T t) f) => err(this.error);

  @override
  Result<T, U> mapErr<U>(U Function(E error) f) => err(f(this.error));

  @override
  A match<A>(A Function(T t) ok, A Function(E e) err) => err(this.error);

  @override
  Result<T, A> orElse<A>(Result<T, A> Function(E error) f) => f(this.error);

  @override
  Stream<T> safeUnwrap() {
    // TODO: implement safeUnwrap
    throw UnimplementedError();
  }

  @override
  T unwrapOr(T v) => v;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Err<T, E> &&
        other.isOk() == this.isOk() &&
        other.isErr() == this.isErr() &&
        other.error == this.error;
  }

  @override
  int get hashCode => error.hashCode;

  @override
  Err<T, E> get asErr => this;

  @override
  Ok<T, E> get asOk =>
      throw createNeverThrowError('Called `asOk` on an Err', this);
}

final fromThrowable = Result.fromThrowable;
