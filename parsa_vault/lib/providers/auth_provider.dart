import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../data/services/auth_service.dart';

// ── State ──────────────────────────────────────────────────────────────────────
enum AuthStatus { checking, authenticated, unauthenticated, noUsers }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;
  final bool isLoading;

  const AuthState({
    this.status = AuthStatus.checking,
    this.user,
    this.error,
    this.isLoading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? error,
    bool? isLoading,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      error: clearError ? null : (error ?? this.error),
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

// ── Notifier ───────────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _service = AuthService();

  AuthNotifier() : super(const AuthState()) {
    checkSession();
  }

  Future<void> checkSession() async {
    state = state.copyWith(status: AuthStatus.checking, isLoading: true);
    try {
      final user = await _service.getSessionUser();
      if (user != null) {
        state = AuthState(status: AuthStatus.authenticated, user: user);
        return;
      }
      final hasUsers = await _service.anyUsersExist();
      state = AuthState(
        status: hasUsers ? AuthStatus.unauthenticated : AuthStatus.noUsers,
      );
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login({
    required String emailOrUsername,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _service.login(
      emailOrUsername: emailOrUsername,
      password: password,
    );
    if (result.success) {
      state = AuthState(status: AuthStatus.authenticated, user: result.user);
      return true;
    }
    state = state.copyWith(isLoading: false, error: result.error);
    return false;
  }

  Future<bool> register({
    required String fullName,
    required String username,
    required String email,
    String? website,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _service.register(
      fullName: fullName,
      username: username,
      email: email,
      website: website,
      password: password,
    );
    if (result.success) {
      state = AuthState(status: AuthStatus.authenticated, user: result.user);
      return true;
    }
    state = state.copyWith(isLoading: false, error: result.error);
    return false;
  }

  Future<void> logout() async {
    await _service.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> refreshUser() async {
    if (state.user == null) return;
    final user = await _service.refreshUser(state.user!.id);
    state = state.copyWith(user: user);
  }

  void clearError() => state = state.copyWith(clearError: true);
}

// ── Provider ───────────────────────────────────────────────────────────────────
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
