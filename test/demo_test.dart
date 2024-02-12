import 'package:neverthrow/neverthrow.dart';

void main() {
  // Create an Ok result
  final okValue = ok(10);
  print(okValue.isOk()); // true
  print(okValue.value); // 10

  // Create an Err result
  final errValue = err('error');
  print(errValue.isErr()); // true
  print(errValue.error); // error

  // Map over an Ok result
  final mappedOk = ok(10).map((value) => value * 2); // Result<int, dynamic>
  print(mappedOk.isOk()); // true
  print(mappedOk.asOk.value); // 20

  // Map over an Err result
  final mappedErr = err('error')
      .mapErr((error) => 'There is an $error'); // Result<dynamic, String>
  print(mappedErr.isErr()); // true
  print(mappedErr.asErr.error); // There is an error

  // Chain multiple operations
  final chainedResult = ok(10)
      .andThen((value) => ok(value * 2))
      .andThen((value) => err<int, String>('error'));
  print(chainedResult.isErr()); // true
  print(chainedResult.asErr.error); // error

  // Use orElse to handle errors
  final orElseResult = err('error').orElse((error) => ok(10));
  print(orElseResult.isOk()); // true
  print(orElseResult.asOk.value); // 10

  // Use match to handle both cases
  final matchResult = ok(10).match((value) => value * 2, (error) => 0);
  print(matchResult); // 20

  // Use unwrapOr to handle both cases
  final unwrapOrResult = err('error').unwrapOr(10);
  print(unwrapOrResult); // 10

  // Use fromFuture to handle Future results
  final futureResult =
      ResultAsync.fromFuture(Future.value(10), (error) => 'There is an $error');
  futureResult.match((value) => print(value), (error) => print(error)); // 10

  // Use fromSafeFuture to handle Future results
  final safeFutureResult = ResultAsync.fromSafeFuture(Future.value(10));
  safeFutureResult.match(
      (value) => print(value), (error) => print(error)); // 10

  // Map over a Future result
  final mappedFuture =
      ResultAsync.fromSafeFuture(Future.value(10)).map((value) => value * 2);
  mappedFuture.match((value) => print(value), (error) => print(error)); // 20

  // Map over a Future error result
  final mappedFutureError = ResultAsync.fromFuture(
          Future.error('error'), (error) => 'There is an $error')
      .map((value) => value * 2);
  mappedFutureError.match(
      (value) => print(value), (error) => print(error)); // There is an error

  // Chain multiple Future operations
  final chainedFutureResult = ResultAsync.fromSafeFuture(Future.value(10))
      .andThen((value) => ResultAsync.fromSafeFuture(Future.value(value * 2)))
      .andThen((value) => ResultAsync.fromFuture(
          Future.error('error'), (error) => 'There is an $error'));
  chainedFutureResult.match(
      (value) => print(value), (error) => print(error)); // There is an error

  // Use orElse to handle Future errors
  final orElseFutureResult = ResultAsync.fromFuture(
          Future.error('error'), (error) => 'There is an $error')
      .orElse((error) => ResultAsync.fromSafeFuture(Future.value(10)));
  orElseFutureResult.match(
      (value) => print(value), (error) => print(error)); // 10

  // Use unwrapOr to handle Future results
  final unwrapOrFutureResult =
      ResultAsync.fromSafeFuture(Future.value(10)).unwrapOr(0);
  unwrapOrFutureResult.then((value) => print(value)); // 10

  // Use unwrapOr to handle Future errors
  final unwrapOrFutureErrorResult = ResultAsync.fromFuture(
      Future.error('error'), (error) => 'There is an $error').unwrapOr(0);
  unwrapOrFutureErrorResult.then((value) => print(value)); // 0
}
