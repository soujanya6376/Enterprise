import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../data/auth_repository.dart';

class AuthState {
  const AuthState({this.loading = false, this.error, this.role, this.username});
  final bool loading;
  final String? error;
  final String? role;
  final String? username;

  bool get isLoggedIn => role != null;
  bool get isAdmin => role == 'ADMIN';

  AuthState copyWith({bool? loading, String? error, String? role, String? username}) =>
      AuthState(
        loading: loading ?? this.loading,
        error: error,
        role: role ?? this.role,
        username: username ?? this.username,
      );
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(const AuthState()) {
    final user = _ref.read(sessionStoreProvider).user;
    if (user != null) {
      state = state.copyWith(role: user['role'] as String?, username: user['username'] as String?);
    }
  }
  final Ref _ref;

  Future<bool> login(String username, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final user = await _ref.read(authRepositoryProvider).login(username, password);
      state = AuthState(role: user['role'] as String?, username: user['username'] as String?);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: _message(e));
      return false;
    }
  }

  Future<void> logout() async {
    await _ref.read(authRepositoryProvider).logout();
    state = const AuthState();
  }

  String _message(Object e) {
    final s = e.toString();
    return s.contains('401') ? 'Invalid username or password' : 'Login failed. Check your connection.';
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) => AuthController(ref));
