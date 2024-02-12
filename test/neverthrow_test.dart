import 'package:neverthrow/_internals/error.dart';
import 'package:neverthrow/neverthrow.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

abstract class MapFn<R> {
  R call(t);
}

class MockMapFn<R> extends Mock implements MapFn<R> {}

void main() {
  group('Result.Ok', () {
    test('Creates an Ok value', () {
      final okVal = ok(1);

      expect(okVal.isOk(), equals(true));
      expect(okVal.isErr(), equals(false));
      expect(okVal, isA<Ok>());
    });

    test('Creates an Ok value with null', () {
      final okVal = ok(null);

      expect(okVal.isOk(), equals(true));
      expect(okVal.isErr(), equals(false));
      expect(okVal.unsafeUnwrap(), null);
    });

    test('Is comparable', () {
      expect(ok(42), equals(ok(42)));
      expect(ok(42), isNot(equals(ok(43))));
    });

    test('Maps over an OK value', () {
      final okVal = ok(42);
      final mapFn = MockMapFn();
      when(mapFn.call(any)).thenReturn('42');

      final mapped = okVal.map(mapFn);

      expect(mapped.isOk(), equals(true));
      expect(mapped.unsafeUnwrap(), '42');
      verify(mapFn(any)).called(1);
    });

    test('Skips `mapErr`', () {
      final mapErrorFn = MockMapFn();
      when(mapErrorFn.call(any)).thenReturn('mapped error value');

      final notMapped = ok(12).mapErr(mapErrorFn);

      expect(notMapped.isOk(), equals(true));
      verifyNever(mapErrorFn(any));
    });

    group('andThen', () {
      test('Maps to an Ok', () {
        final okVal = ok(42);
        final flattened = okVal.andThen((number) {
          return ok({'data': 'why not'});
        });
        expect(flattened.isOk(), equals(true));
        expect(flattened.unsafeUnwrap(), equals({'data': 'why not'}));
      });

      test('Maps to an Err', () {
        final okVal = ok(42);
        final flattened = okVal.andThen((number) {
          return err('whoopsies');
        });
        expect(flattened.isOk(), equals(false));

        final nextFn = MockMapFn<Result?>();
        when(nextFn.call(any)).thenReturn(ok('noop'));

        flattened.andThen((t) => nextFn(any)!);

        verifyNever(nextFn(any));
      });
    });

    group('orElse', () {
      test('Skips orElse on an Ok value', () {
        final okVal = ok(42);
        final errorCallback = MockMapFn<Result<Never, String>?>();
        when(errorCallback.call(any)).thenReturn(err('it is now a string'));

        expect(okVal.orElse((error) => errorCallback(any)!), equals(ok(42)));
        verifyNever(errorCallback(any));
      });
    });

    test('unwrapOr and return the Ok value', () {
      final okVal = ok(42);
      expect(okVal.unwrapOr(1), equals(42));
    });

    test('Maps to a ResultAsync', () async {
      final okVal = ok(42);
      final flattened = okVal.asyncAndThen((number) {
        return okAsync({'data': 'why not'});
      });

      expect(flattened, isA<ResultAsync>());

      final newResult = await flattened;

      expect(newResult.isOk(), equals(true));
      expect(newResult.unsafeUnwrap(), equals({'data': 'why not'}));
    });

    test('Maps to a Future', () async {
      final asyncMapper = MockMapFn();
      when(asyncMapper.call(any)).thenAnswer((_) => Future.value('nice'));

      final okVal = ok(42);

      final future = okVal.asyncMap((t) => asyncMapper(Never));

      expect(future, isA<ResultAsync>());

      final newResult = await future;

      expect(newResult.isOk(), equals(true));
      verify(asyncMapper(any)).called(1);
      expect(newResult.unsafeUnwrap(), equals('nice'));
    });

    test('Matches on an Ok', () {
      final okMapper = MockMapFn();
      when(okMapper.call(any)).thenReturn('weeeee');
      final errMapper = MockMapFn();
      when(errMapper.call(any)).thenReturn('booooo');

      final matched =
          ok(12).match((t) => okMapper(Never), (e) => errMapper(Never));

      expect(matched, equals('weeeee'));
      verify(okMapper(any)).called(1);
      verifyNever(errMapper(any));
    });

    test('Unwraps without issue', () {
      final okVal = ok(42);
      expect(okVal.unsafeUnwrap(), equals(42));
    });

    test('Can read the value after narrowing', () {
      Result<String, num> fallible() => ok('safe to read');
      final val = fallible();

      /// Dart doesn't seem to be able to narrow type here
      if (val.isErr()) return;

      expect(val.asOk.value, equals('safe to read'));
    });
  });

  group('Result.Err', () {
    test('Creates an Err value', () {
      final errVal = err('nope');

      expect(errVal.isErr(), equals(true));
      expect(errVal.isOk(), equals(false));
      expect(errVal, isA<Err>());
    });

    test('Is comparable', () {
      expect(err(42), equals(err(42)));
      expect(err(42), isNot(equals(err(43))));
    });

    test('Skips `map`', () {
      final errVal = err('nope');

      final mapFn = MockMapFn();
      when(mapFn.call(any)).thenReturn('mapped value');

      final notMapped = errVal.map(mapFn);

      expect(notMapped.isErr(), equals(true));
      expect(errVal.unsafeUnwrapErr(), equals(notMapped.unsafeUnwrapErr()));
      verifyNever(mapFn(any));
    });

    test('Maps over an Err', () {
      final errVal = err('no no no no');

      final mapErrorFn = MockMapFn<String Function(String)?>();
      when(mapErrorFn.call(any))
          .thenReturn((String error) => error.replaceAll('no', 'yes'));

      final mapped = errVal.mapErr((val) => mapErrorFn(Never)!(val));

      expect(mapped.isErr(), equals(true));
      expect(mapped.unsafeUnwrapErr(), equals('yes yes yes yes'));
      verify(mapErrorFn(any)).called(1);
    });

    test('unwrapOr and return the default value', () {
      final okVal = err<num, String>('Uh oh');

      expect(okVal.unwrapOr(1), equals(1));
    });

    test('Skips over andThen', () {
      final errVal = err('nope');

      final nextFn = MockMapFn<Result?>();
      when(nextFn.call(any)).thenReturn(ok('noop'));

      final notFlattened = errVal.andThen((t) => nextFn(t)!);

      expect(notFlattened.isErr(), equals(true));
      expect(notFlattened.unsafeUnwrapErr(), equals('nope'));
      verifyNever(nextFn(any));
    });

    test('Transforms error into ResultAsync within `asyncAndThen`', () async {
      final errVal = err('nope');

      final nextFn = MockMapFn<ResultAsync?>();
      when(nextFn.call(any)).thenAnswer((_) => okAsync('noop'));

      final notFlattened = errVal.asyncAndThen((t) => nextFn(t)!);

      expect(notFlattened, isA<ResultAsync>());
      verifyNever(nextFn(any));

      final syncResult = await notFlattened;
      expect(syncResult.unsafeUnwrapErr(), equals('nope'));
    });

    test('Does not invoke callback within `asyncMap`', () async {
      final asyncMapper = MockMapFn();
      when(asyncMapper.call(any)).thenAnswer((_) => Future.value('nice'));

      final errVal = err('nope');

      final future = errVal.asyncMap((t) => asyncMapper(Never));

      expect(future, isA<ResultAsync>());

      final sameResult = await future;

      expect(sameResult.isErr(), equals(true));
      verifyNever(asyncMapper(any));
      expect(sameResult.unsafeUnwrapErr(), equals('nope'));
    });

    test('Matches on an Err', () {
      final okMapper = MockMapFn();
      when(okMapper.call(any)).thenReturn('weeeee');
      final errMapper = MockMapFn();
      when(errMapper.call(any)).thenReturn('booooo');

      final matched = err('uh oh').match(okMapper, errMapper);

      expect(matched, equals('booooo'));
      verify(errMapper(any)).called(1);
      verifyNever(okMapper(any));
    });

    test('Throws when you unwrap an Err', () {
      final errVal = err('nope');

      expect(() => errVal.unsafeUnwrap(), throwsA(isA<NeverThrowError>()));
    });

    test('Unwraps without issue', () {
      final errVal = err('nope');
      expect(errVal.unsafeUnwrapErr(), equals('nope'));
    });

    group('orElse', () {
      test('invokes the orElse callback on an Err value', () {
        final errVal = err('nope');
        final errorCallback = MockMapFn<Result<Never, bool>?>();
        when(errorCallback.call(any)).thenReturn(err(true));

        final result = errVal.orElse((error) => errorCallback(error)!);

        expect(result.isErr(), equals(true));
        verify(errorCallback(any)).called(1);
      });
    });
  });

  group('Result.fromThrowable', () {
    test(
        'Creates a function that returns an OK result when the inner function does not throw',
        () {
      hello() => 'hello';

      final result = hello();
      final safeResult = Result.fromThrowable(() => hello());

      expect(safeResult, isA<Ok>());
      expect(result, safeResult.unsafeUnwrap());
    });

    test('Accepts an inner function which takes arguments', () {
      hello(String name) => 'Hello, $name';
      final result = hello('hambergerpls');
      final safeResult = Result.fromThrowable(() => hello('hambergerpls'));

      expect(safeResult, isA<Ok>());
      expect(result, safeResult.unsafeUnwrap());
    });

    test(
        'Creates a function that returns an err when the inner function throws',
        () {
      throwError() => throw Exception('nope');

      final safeResult = Result.fromThrowable(() => throwError());

      expect(safeResult, isA<Err>());
      expect(safeResult.unsafeUnwrapErr(), isA<Exception>());
    });

    test('Accepts an error handler as a second argument', () {
      throwError() => throw 'nope';

      final safeResult =
          Result.fromThrowable(() => throwError(), errorFn: (e) => 'Oops: $e');

      expect(safeResult, isA<Err>());
      expect(safeResult.unsafeUnwrapErr(), isA<String>());
      expect(safeResult.unsafeUnwrapErr().toString(), equals('Oops: nope'));
    });

    test('has a top level function', () {
      expect(fromThrowable, equals(Result.fromThrowable));
    });
  });

  group('Utils', () {
    group('`Result.combine`', () {
      group('Synchronous `combine`', () {
        test('Combines a list of results into an Ok value', () {
          final resultList = [ok(1), ok(2), ok(3)];

          final result = Result.combine(resultList);

          expect(result.isOk(), equals(true));
          expect(result.unsafeUnwrap(), equals([1, 2, 3]));
        });

        test('Combines a list of results into an Err value', () {
          final resultList = <Result<dynamic, dynamic>>[
            ok(1),
            err('nope'),
            ok(3)
          ];

          final result = Result.combine(resultList);

          expect(result.isErr(), equals(true));
          expect(result.unsafeUnwrapErr(), equals('nope'));
        });

        test('Combines heterogeneous lists', () {
          final heterogenousList = <Result<dynamic, Never>>[
            ok('yoooo'),
            ok(123),
            ok(true)
          ];

          final result = Result.combine(heterogenousList);

          expect(result.unsafeUnwrap(), equals(['yoooo', 123, true]));
        });

        test('Does not destructure / concatenate arrays', () {
          final homogeneousList = <Result<dynamic, Never>>[
            ok(['hello', 'world']),
            ok([1, 2, 3])
          ];

          final result = Result.combine(homogeneousList);

          expect(
              result.unsafeUnwrap(),
              equals([
                ['hello', 'world'],
                [1, 2, 3]
              ]));
        });
      });
    });

    group('`ResultAsync.combine`', () {
      group('Asynchronous `combine`', () {
        test('Combines a list of async results into an Ok value', () async {
          final asyncResultList = [
            okAsync(1),
            okAsync(2),
            okAsync(3),
          ];

          final resultAsync = await ResultAsync.combine(asyncResultList);

          expect(resultAsync.isOk(), equals(true));
          expect(resultAsync.unsafeUnwrap(), equals([1, 2, 3]));
        });

        test('Combines a list of async results into an Err value', () async {
          final resultAsync = [
            okAsync(1),
            errAsync('nope'),
            okAsync(3),
          ];

          final result = await ResultAsync.combine(resultAsync);

          expect(result.isErr(), equals(true));
          expect(result.unsafeUnwrapErr(), equals('nope'));
        });

        test('Combines heterogeneous lists', () async {
          final heterogenousList = <ResultAsync<dynamic, Never>>[
            okAsync('yoooo'),
            okAsync(123),
            okAsync(true)
          ];

          final result = await ResultAsync.combine(heterogenousList);

          expect(result.unsafeUnwrap(), equals(['yoooo', 123, true]));
        });

        test('Does not destructure / concatenate arrays', () async {
          final homogeneousList = <ResultAsync<dynamic, Never>>[
            okAsync(['hello', 'world']),
            okAsync([1, 2, 3])
          ];

          final result = await ResultAsync.combine(homogeneousList);

          expect(
              result.unsafeUnwrap(),
              equals([
                ['hello', 'world'],
                [1, 2, 3]
              ]));
        });
      });

      group('`ResultAsync.combineWithAllErrors`', () {
        test('Combines a list of async results into an Ok value', () async {
          final asyncResultList = [
            okAsync(1),
            okAsync(2),
            okAsync(3),
          ];

          final resultAsync =
              await ResultAsync.combineWithAllErrors(asyncResultList);

          expect(resultAsync.isOk(), equals(true));
          expect(resultAsync.unsafeUnwrap(), equals([1, 2, 3]));
        });

        test('Combines a list of results into an Err value', () async {
          final resultAsync = [
            okAsync(1),
            errAsync('nope'),
            okAsync(3),
            errAsync('whut')
          ];

          final result = await ResultAsync.combineWithAllErrors(resultAsync);

          expect(result.isErr(), equals(true));
          expect(result.unsafeUnwrapErr(), equals(['nope', 'whut']));
        });

        test('Combines heterogeneous lists', () async {
          final heterogenousList = <ResultAsync<dynamic, Never>>[
            okAsync('yoooo'),
            okAsync(123),
            okAsync(true)
          ];

          final result =
              await ResultAsync.combineWithAllErrors(heterogenousList);

          expect(result.unsafeUnwrap(), equals(['yoooo', 123, true]));
        });
      });
    });
  });
  group('ResultAsync', () {
    test('Is awaitable to a Result', () async {
      final asyncVal = okAsync(12);
      expect(asyncVal, isA<ResultAsync>());

      final val = await asyncVal;

      expect(val, isA<Ok>());
      expect(val.unsafeUnwrap(), equals(12));

      final asyncErr = errAsync('Wrong format');
      expect(asyncErr, isA<ResultAsync>());

      final err = await asyncErr;
      expect(err, isA<Err>());
      expect(err.unsafeUnwrapErr(), equals('Wrong format'));
    });

    group('Acting as a Future<Result>', () {
      test('Is chainable like any Future', () async {
        final asyncValChained = okAsync(12).then((res) {
          if (res.isOk()) {
            return res.asOk.value + 2;
          }
        });

        expect(asyncValChained, isA<Future>());
        final val = await asyncValChained;
        expect(val, equals(14));

        final asyncErrChained = errAsync('Whoops').then((res) {
          if (res.isErr()) {
            return '${res.asErr.error}!';
          }
        });

        expect(asyncErrChained, isA<Future>());
        final err = await asyncErrChained;
        expect(err, equals('Whoops!'));
      });

      test('Can be used with Future.wait', () async {
        final allResult = await Future.wait([okAsync('1')]);

        expect(allResult, hasLength(1));
        expect(allResult.first, isA<Ok>());
        if (allResult.first is! Ok) return;
        expect(allResult.first.isOk(), equals(true));
        expect(allResult.first.unsafeUnwrap(), equals('1'));
      });

      test('Rejects if the underlying Future is rejected', () {
        final asyncResult = ResultAsync(Future.error('Whoops'));
        expect(asyncResult, throwsA('Whoops'));
      });
    });

    group('map', () {
      test('Maps a value using synchronous function', () async {
        final asyncVal = okAsync(12);

        final mapSyncFn = MockMapFn();
        when(mapSyncFn.call(any)).thenReturn('12');

        final mapped = asyncVal.map(mapSyncFn);

        expect(mapped, isA<ResultAsync>());

        final newVal = await mapped;

        expect(newVal.isOk(), equals(true));
        expect(newVal.unsafeUnwrap(), equals('12'));
        verify(mapSyncFn(any)).called(1);
      });

      test('Maps a value using asynchronous function', () async {
        final asyncVal = okAsync(12);

        final mapAsyncFn = MockMapFn();
        when(mapAsyncFn.call(any)).thenAnswer((_) => Future.value('12'));

        final mapped = asyncVal.map(mapAsyncFn);

        expect(mapped, isA<ResultAsync>());

        final newVal = await mapped;

        expect(newVal.isOk(), equals(true));
        expect(newVal.unsafeUnwrap(), equals('12'));
        verify(mapAsyncFn(any)).called(1);
      });

      test('Skips an error', () async {
        final asyncErr = errAsync('Wrong format');

        final mapSyncFn = MockMapFn();
        when(mapSyncFn.call(any)).thenReturn('12');

        final notMapped = asyncErr.map(mapSyncFn);

        expect(notMapped, isA<ResultAsync>());

        final newVal = await notMapped;

        expect(newVal.isErr(), equals(true));
        expect(newVal.unsafeUnwrapErr(), equals('Wrong format'));
        verifyNever(mapSyncFn(any));
      });
    });

    group('mapErr', () {
      test('Maps an error using a synchronous function', () async {
        final asyncErr = errAsync('Wrong format');

        final mapErrSyncFn = MockMapFn();
        when(mapErrSyncFn.call('Wrong format'))
            .thenReturn('Error: Wrong format');

        final mappedErr = asyncErr.mapErr(mapErrSyncFn);

        expect(mappedErr, isA<ResultAsync>());

        final newVal = await mappedErr;

        expect(newVal.isErr(), equals(true));
        expect(newVal.unsafeUnwrapErr(), equals('Error: Wrong format'));
        verify(mapErrSyncFn('Wrong format')).called(1);
      });

      test('Maps an error using an asynchronous function', () async {
        final asyncErr = errAsync('Wrong format');

        final mapErrAsyncFn = MockMapFn();
        when(mapErrAsyncFn.call('Wrong format'))
            .thenAnswer((_) => Future.value('Error: Wrong format'));

        final mappedErr = asyncErr.mapErr(mapErrAsyncFn);

        expect(mappedErr, isA<ResultAsync>());

        final newVal = await mappedErr;

        expect(newVal.isErr(), equals(true));
        expect(newVal.unsafeUnwrapErr(), equals('Error: Wrong format'));
        verify(mapErrAsyncFn('Wrong format')).called(1);
      });

      test('Skips a value', () async {
        final asyncVal = okAsync(12);

        final mapErrSyncFn = MockMapFn();
        when(mapErrSyncFn.call(any)).thenReturn('Error: Wrong format');

        final notMapped = asyncVal.mapErr(mapErrSyncFn);

        expect(notMapped, isA<ResultAsync>());

        final newVal = await notMapped;

        expect(newVal.isOk(), equals(true));
        expect(newVal.unsafeUnwrap(), equals(12));
        verifyNever(mapErrSyncFn(any));
      });
    });

    group('andThen', () {
      test('Maps a value using a function returning a ResultAsync', () async {
        final asyncVal = okAsync(12);

        final andThenResultAsyncFn = MockMapFn<ResultAsync?>();
        when(andThenResultAsyncFn.call(any)).thenAnswer((_) => okAsync('good'));

        final mapped = asyncVal.andThen((val) => andThenResultAsyncFn(Never)!);

        expect(mapped, isA<ResultAsync>());

        final newVal = await mapped;

        expect(newVal.isOk(), equals(true));
        expect(newVal.unsafeUnwrap(), equals('good'));
        verify(andThenResultAsyncFn(any)).called(1);
      });

      test('Maps a value using a function returning a Result', () async {
        final asyncVal = okAsync(12);

        final andThenResultFn = MockMapFn<Result?>();
        when(andThenResultFn.call(any)).thenReturn(ok('good'));

        final mapped =
            asyncVal.andThen((val) => ResultAsync(andThenResultFn(Never)!));

        expect(mapped, isA<ResultAsync>());

        final newVal = await mapped;

        expect(newVal.isOk(), equals(true));
        expect(newVal.unsafeUnwrap(), equals('good'));
        verify(andThenResultFn(any)).called(1);
      });

      test('Skips an Error', () async {
        final asyncVal = errAsync('Wrong format');

        final andThenResultFn = MockMapFn<Result?>();
        when(andThenResultFn.call(any)).thenReturn(ok('good'));

        final notMapped =
            asyncVal.andThen((val) => ResultAsync(andThenResultFn(Never)!));

        expect(notMapped, isA<ResultAsync>());

        final newVal = await notMapped;

        expect(newVal.isErr(), equals(true));
        expect(newVal.unsafeUnwrapErr(), equals('Wrong format'));
        verifyNever(andThenResultFn(any));
      });
    });

    group('orElse', () {
      test('Skips orElse on an Ok value', () async {
        final okVal = okAsync(12);

        final errorCallback = MockMapFn<ResultAsync<Never, String>?>();
        when(errorCallback.call(any))
            .thenAnswer((_) => errAsync('it is now a string'));

        final result = await okVal.orElse((error) => errorCallback(Never)!);

        expect(result.isOk(), equals(true));
        verifyNever(errorCallback(any));
      });

      test('Invokes the orElse callback on an Err value', () async {
        final myResult = errAsync('uh oh!');

        final errorCallback = MockMapFn<ResultAsync<Never, bool>?>();
        when(errorCallback.call(any)).thenAnswer((_) => errAsync(true));

        final result = await myResult.orElse((_) => errorCallback(Never)!);

        expect(result.isErr(), equals(true));
        expect(result.unsafeUnwrapErr(), equals(true));
        verify(errorCallback(any)).called(1);
      });

      test('Accepts a regular result in the callback', () async {
        final myResult = errAsync('uh oh!');

        final errorCallback = MockMapFn<Result<Never, bool>?>();
        when(errorCallback.call(any)).thenReturn(err(true));

        final result = await myResult.orElse((_) => errorCallback(Never)!);

        expect(result.isErr(), equals(true));
        expect(result.unsafeUnwrapErr(), equals(true));
        verify(errorCallback(any)).called(1);
      });
    });

    group('match', () {
      test('Matches on an Ok', () async {
        final okMapper = MockMapFn();
        when(okMapper.call(any)).thenReturn('weeeee');

        final errMapper = MockMapFn();
        when(errMapper.call(any)).thenReturn('booooo');

        final matched = await okAsync(12).match(
          okMapper,
          errMapper,
        );

        expect(matched, equals('weeeee'));
        verify(okMapper(any)).called(1);
        verifyNever(errMapper(any));
      });

      test('Matches on an Err', () async {
        final okMapper = MockMapFn();
        when(okMapper.call(any)).thenReturn('weeeee');

        final errMapper = MockMapFn();
        when(errMapper.call(any)).thenReturn('booooo');

        final matched = await errAsync('uh oh').match(
          okMapper,
          errMapper,
        );

        expect(matched, equals('booooo'));
        verify(errMapper(any)).called(1);
        verifyNever(okMapper(any));
      });
    });

    group('unwrapOr', () {
      test('returns a promise to the result value of an Ok', () {
        final okVal = okAsync(12);
        expect(okVal.unwrapOr(1), completion(equals(12)));
      });

      test('returns a promise to the default value of an Error', () {
        final errVal = errAsync<int, int>(12);
        expect(errVal.unwrapOr(1), completion(equals(1)));
      });
    });

    group('fromSafeFuture', () {
      test('Creates a ResultAsync from a Future', () async {
        final val = ResultAsync.fromSafeFuture(Future.value(12));

        expect(val, isA<ResultAsync>());

        final res = await val;

        expect(res.isOk(), equals(true));
        expect(res.unsafeUnwrap(), equals(12));
      });

      test('has a top level function', () async {
        expect(fromSafeFuture, equals(ResultAsync.fromSafeFuture));
      });
    });

    group('fromFuture', () {
      test('Accepts an error handler as a second argument', () async {
        final val = ResultAsync.fromFuture(
            Future.error('No!'), (e) => Exception('Oops: $e'));

        expect(val, isA<ResultAsync>());

        final res = await val;

        expect(res.isErr(), equals(true));

        /// Had to use toString() because Exception is not comparable
        /// The alternative would be to extend Exception
        /// and implement == and hashCode
        expect(res.unsafeUnwrapErr().toString(),
            equals(Exception('Oops: No!').toString()));
      });

      test('has a top level function', () async {
        expect(fromFuture, equals(ResultAsync.fromFuture));
      });
    });

    group('okAsync', () {
      test('Creates a ResultAsync that resolves to an Ok', () async {
        final val = okAsync(12);

        expect(val, isA<ResultAsync>());

        final res = await val;

        expect(res.isOk(), equals(true));
        expect(res.unsafeUnwrap(), equals(12));
      });
    });

    group('errAsync', () {
      test('Creates a ResultAsync that resolves to an Err', () async {
        final err = errAsync('No!');

        expect(err, isA<ResultAsync>());

        final res = await err;

        expect(res.isErr(), equals(true));
        expect(res.unsafeUnwrapErr(), equals('No!'));
      });
    });
  });
}
