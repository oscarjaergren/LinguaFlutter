/// Composable loading/error state for [ChangeNotifier] providers.
///
/// Eliminates the repeated `_setLoading`, `_setError`, and `_clearError`
/// boilerplate. Pass [notifyListeners] from the owning provider so state
/// changes automatically propagate to listeners.
///
/// Example:
/// ```dart
/// class MyProvider extends ChangeNotifier {
///   late final _state = ProviderState(notifyListeners);
///
///   bool get isLoading => _state.isLoading;
///   String? get errorMessage => _state.errorMessage;
/// }
/// ```
class ProviderState {
  ProviderState(this._notify);

  final void Function() _notify;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setLoading(bool loading) {
    if (_isLoading == loading) return;
    _isLoading = loading;
    _notify();
  }

  void setError(String error) {
    if (_errorMessage == error) return;
    _errorMessage = error;
    _notify();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    _notify();
  }
}
