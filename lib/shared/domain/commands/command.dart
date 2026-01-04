/// Base interface for all commands in the application
/// Commands encapsulate user actions and provide standardized error handling
abstract class Command<T> {
  /// Execute the command and return a result
  Future<Result<T>> execute();
}

/// Result wrapper for command execution
class Result<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  const Result._({this.data, this.error, required this.isSuccess});

  /// Create a successful result
  factory Result.success(T data) {
    return Result._(data: data, isSuccess: true);
  }

  /// Create a successful result with no data
  factory Result.successEmpty() {
    return const Result._(isSuccess: true);
  }

  /// Create a failure result
  factory Result.failure(String error) {
    return Result._(error: error, isSuccess: false);
  }

  /// Create a failure result from an exception
  factory Result.fromException(Exception exception) {
    return Result._(error: exception.toString(), isSuccess: false);
  }

  /// Whether the command failed
  bool get isFailure => !isSuccess;

  /// Get the data or throw if failed
  T get dataOrThrow {
    if (isFailure) {
      throw Exception(error ?? 'Command failed');
    }
    return data as T;
  }

  /// Get the data or return a default value
  T dataOr(T defaultValue) {
    return isSuccess ? data as T : defaultValue;
  }

  /// Transform the result data if successful
  Result<U> map<U>(U Function(T data) transform) {
    if (isFailure) {
      return Result.failure(error!);
    }
    try {
      return Result.success(transform(data as T));
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  /// Execute a function if the result is successful
  Result<T> onSuccess(void Function(T data) action) {
    if (isSuccess && data != null) {
      action(data as T);
    }
    return this;
  }

  /// Execute a function if the result is a failure
  Result<T> onFailure(void Function(String error) action) {
    if (isFailure && error != null) {
      action(error!);
    }
    return this;
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'Result.success($data)';
    } else {
      return 'Result.failure($error)';
    }
  }
}
