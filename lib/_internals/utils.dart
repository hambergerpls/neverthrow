import 'dart:async';

import '../result.dart';
import '../result_async.dart';

Result<List<T>, E> combineResultList<T, E>(List<Result<T, E>> resultList) {
  if (resultList.isEmpty) {
    resultList = [ok([])] as List<Result<T, E>>;
  }
  return resultList.fold<Result<List<T>, E>>(
      ok<List<T>, E>([]),
      (acc, result) => acc.isOk()
          ? result.isErr()
              ? err(result.asErr.error)
              : acc.map((list) => list..add(result.asOk.value))
          : acc);
}

ResultAsync<List<T>, E> combineResultAsyncList<T, E>(
        Iterable<ResultAsync<T, E>> asyncResultList) =>
    ResultAsync.fromSafeFuture(Future.wait(asyncResultList))
        .andThen((list) => ResultAsync(combineResultList(list)));

Result<List<T>, List<E>> combineResultListWithAllErrors<T, E>(
    List<Result<T, E>> resultList) {
  if (resultList.isEmpty) {
    resultList = [ok([])] as List<Result<T, E>>;
  }
  return resultList.fold<Result<List<T>, List<E>>>(
      ok<List<T>, List<E>>([]),
      (acc, result) => result.isErr()
          ? acc.isErr()
              ? acc.mapErr((list) => list..add(result.asErr.error))
              : err([result.asErr.error])
          : acc.isErr()
              ? acc
              : acc.map((list) => list..add(result.asOk.value)));
}

ResultAsync<List<T>, List<E>> combineResultAsyncListWIthAllErrors<T, E>(
        Iterable<ResultAsync<T, E>> asyncResultList) =>
    ResultAsync.fromSafeFuture(Future.wait(asyncResultList))
        .andThen((list) => ResultAsync(combineResultListWithAllErrors(list)));
