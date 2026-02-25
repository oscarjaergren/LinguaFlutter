import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_state.freezed.dart';

@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState({
    User? user,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _AuthState;
}

extension AuthStateExtension on AuthState {
  bool get isAuthenticated => user != null;
  String? get userEmail => user?.email;
  String? get userId => user?.id;
}
