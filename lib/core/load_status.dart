enum LoadStatus { initial, loading, success, empty, failure }

class AppFailure implements Exception {
  const AppFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

String failureMessage(Object error) => error is AppFailure
    ? error.message
    : 'Something went wrong. Please try again.';
