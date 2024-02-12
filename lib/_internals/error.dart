import 'package:neverthrow/result.dart';

interface class ErrorConfig {
  const ErrorConfig({this.withStackTrace = false});
  final bool withStackTrace;
}

interface class NeverThrowError<T, E> {
  late ({String type, T? value, E? error}) data;
  late String message;
  StackTrace? stack;
}

final defaultErrorConfig = const ErrorConfig();

createNeverThrowError<T, E>(String message, Result<T, E> result,
    {ErrorConfig? config}) {
  config ??= defaultErrorConfig;
  final data = result.isOk()
      ? (type: 'Ok', value: result.asOk.value, error: null)
      : (type: 'Err', value: null, error: result.asErr.error);

  final maybeStack = config.withStackTrace ? Error().stackTrace : null;
  return NeverThrowError<T, E>()
    ..data = data
    ..message = message
    ..stack = maybeStack;
}
