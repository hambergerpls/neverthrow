import 'package:neverthrow/_internals/utils.dart';

import 'result.dart';

import 'dart:async';

ResultAsync<T, E> okAsync<T, E>(T value) {
  return ResultAsync(Ok<T, E>(value));
}

ResultAsync<T, E> errAsync<T, E>(E error) {
  return ResultAsync(Err<T, E>(error));
}

class ResultAsync<T, E> implements Future<Result<T, E>> {
  late Future<Result<T, E>> _future;

  ResultAsync(FutureOr<Result<T, E>> res) {
    this._future = res is Future<Result<T, E>> ? res : Future.value(res);
  }

  static ResultAsync<List<T>, E> combine<T, E>(
          Iterable<ResultAsync<T, E>> asyncResultList) =>
      combineResultAsyncList(asyncResultList);

  static ResultAsync<List<T>, List<E>> combineWithAllErrors<T, E>(
          Iterable<ResultAsync<T, E>> asyncResultList) =>
      combineResultAsyncListWIthAllErrors(asyncResultList);

  static ResultAsync<T, E> fromSafeFuture<T, E>(Future<T> future) {
    final newFuture = future.then((value) => Ok<T, E>(value));

    return ResultAsync(newFuture);
  }

  static ResultAsync<T, E> fromFuture<T, E>(
      Future<T> future, E Function(Object e) errorFn) {
    final newFuture = future
        .then<Result<T, E>>((value) => Ok<T, E>(value))
        .catchError((e) => Err<T, E>(errorFn(e)));

    return ResultAsync(newFuture);
  }

  ResultAsync<A, E> map<A>(FutureOr<A> Function(T t) f) {
    return ResultAsync(this._future.then((res) async {
      if (res.isErr()) {
        return Err<A, E>(res.asErr.error);
      }
      return Ok<A, E>(await f(res.asOk.value));
    }));
  }

  ResultAsync<T, U> mapErr<U>(FutureOr<U> Function(E error) f) {
    return ResultAsync(this._future.then((res) async {
      if (res.isOk()) {
        return Ok<T, U>(res.asOk.value);
      }

      return Err<T, U>(await f(res.asErr.error));
    }));
  }

  ResultAsync<U, F> andThen<U, F>(FutureOr<Result<U, F>> Function(T value) f) {
    return ResultAsync(this._future.then((res) {
      if (res.isErr()) {
        return Err<U, F>(res.asErr.error as F);
      }

      return f(res.asOk.value);
    }));
  }

  ResultAsync<T, A> orElse<A>(FutureOr<Result<T, A>> Function(E error) f) {
    return ResultAsync(this._future.then((res) {
      if (res.isErr()) {
        return f(res.asErr.error);
      }

      return Ok<T, A>(res.asOk.value);
    }));
  }

  Future<A> match<A>(A Function(T value) ok, A Function(E error) err) =>
      _future.then((res) => res.match(ok, err));

  Future<T> unwrapOr(T t) => _future.then((res) => res.unwrapOr(t));

  @override
  Future<R> then<R>(FutureOr<R> Function(Result<T, E> value) onValue,
          {Function? onError}) =>
      _future.then(onValue, onError: onError);

  @override
  Stream<Result<T, E>> asStream() => _future.asStream();

  @override
  Future<Result<T, E>> catchError(Function onError,
          {bool Function(Object error)? test}) =>
      _future.catchError(onError, test: test);

  @override
  Future<Result<T, E>> timeout(Duration timeLimit,
          {FutureOr<Result<T, E>> Function()? onTimeout}) =>
      _future.timeout(timeLimit, onTimeout: onTimeout);

  @override
  Future<Result<T, E>> whenComplete(FutureOr<void> Function() action) =>
      _future.whenComplete(action);
}

final fromFuture = ResultAsync.fromFuture;
final fromSafeFuture = ResultAsync.fromSafeFuture;
