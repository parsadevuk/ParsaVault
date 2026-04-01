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
  final bool emailVerified;
  final bool isNewSsoUser;
  final bool isSsoUser;

  const AuthState({
    this.status = AuthStatus.checking,
    this.user,
    this.error,
    this.isLoading = false,
    this.emailVerified = false,
    this.isNewSsoUser = false,
    this.isSsoUser = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? error,
    bool? isLoading,
    bool? emailVerified,
    bool? isNewSsoUser,
    bool? isSsoUser,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      error: clearError ? null : (error ?? this.error),
      isLoading: isLoading ?? this.isLoading,
      emailVerified: emailVerified ?? this.emailVerified,
      isNewSsoUser: isNewSsoUser ?? this.isNewSsoUser,
      isSsoUser: isSsoUser ?? this.isSsoUser,
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
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
          emailVerified: _service.isEmailVerified,
          isSsoUser: _service.currentUserIsSso,
        );
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

  // ── Email + Password ────────────────────────────────────────────────────────

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
      state = AuthState(
        status: AuthStatus.authenticated,
        user: result.user,
        emailVerified: _service.isEmailVerified,
        isSsoUser: false,
      );
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
      state = AuthState(
        status: AuthStatus.authenticated,
        user: result.user,
        emailVerified: false,
        isSsoUser: false,
      );
      return true;
    }
    state = state.copyWith(isLoading: false, error: result.error);
    return false;
  }

  Future<void> logout() async {
    await _service.logout();
    final hasUsers = await _service.anyUsersExist();
    state = AuthState(
      status: hasUsers ? AuthStatus.unauthenticated : AuthStatus.noUsers,
    );
  }

  // ── SSO ─────────────────────────────────────────────────────────────────────

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _service.signInWithGoogle();
    if (result.success) {
      state = AuthState(
        status: AuthStatus.authenticated,
        user: result.user,
        emailVerified: true,
        isNewSsoUser: result.isNewUser,
        isSsoUser: true,
      );
      return true;
    }
    state = state.copyWith(isLoading: false, error: result.error);
    return false;
  }

  Future<bool> signInWithApple() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _service.signInWithApple();
    if (result.success) {
      state = AuthState(
        status: AuthStatus.authenticated,
        user: result.user,
        emailVerified: true,
        isNewSsoUser: result.isNewUser,
        isSsoUser: true,
      );
      return true;
    }
    state = state.copyWith(isLoading: false, error: result.error);
    return false;
  }

  Future<bool> signInWithMicrosoft() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _service.signInWithMicrosoft();
    if (result.success) {
      state = AuthState(
        status: AuthStatus.authenticated,
        user: result.user,
        emailVerified: true,
        isNewSsoUser: result.isNewUser,
        isSsoUser: true,
      );
      return true;
    }
    state = state.copyWith(isLoading: false, error: result.error);
    return false;
  }

  Future<bool> completeProfile({
    required String username,
    String? website,
  }) async {
    final userId = state.user?.id;
    if (userId == null) return false;
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _service.completeProfile(
      userId: userId,
      username: username,
      website: website,
    );
    if (result.success) {
      state = state.copyWith(
        isLoading: false,
        user: result.user,
        isNewSsoUser: false,
      );
      return true;
    }
    state = state.copyWith(isLoading: false, error: result.error);
    return false;
  }

  // ── Email Verification ──────────────────────────────────────────────────────

  Future<void> sendVerificationEmail() async {
    await _service.sendVerificationEmail();
  }

  Future<void> refreshEmailVerified() async {
    final verified = await _service.refreshEmailVerified();
    state = state.copyWith(emailVerified: verified);
  }

  // ── Profile ─────────────────────────────────────────────────────────────────

  Future<void> refreshUser() async {
    if (state.user == null) return;
    final user = await _service.refreshUser(state.user!.id);
    state = state.copyWith(user: user);
  }

  Future<void> updateProfilePicture(String? base64Image) async {
    final userId = state.user?.id;
    if (userId == null) return;
    await _service.updateProfilePicture(userId, base64Image);
    if (base64Image != null) {
      state = state.copyWith(
          user: state.user!.copyWith(profilePicture: base64Image));
    } else {
      state = state.copyWith(
          user: state.user!.copyWith(clearProfilePicture: true));
    }
  }

  Future<void> updateWebsite(String? website) async {
    final userId = state.user?.id;
    if (userId == null) return;
    await _service.updateWebsite(userId, website);
    state = state.copyWith(
      user: state.user!.copyWith(
        website: (website?.trim().isNotEmpty == true) ? website!.trim() : null,
        clearWebsite: (website == null || website.trim().isEmpty),
      ),
    );
  }

  Future<void> updateFullName(String fullName) async {
    final userId = state.user?.id;
    if (userId == null) return;
    await _service.updateFullName(userId, fullName.trim());
    state =
        state.copyWith(user: state.user!.copyWith(fullName: fullName.trim()));
  }

  /// Returns error string if username taken, null on success.
  Future<String?> updateUsername(String newUsername) async {
    final userId = state.user?.id;
    if (userId == null) return 'Not logged in.';
    final error = await _service.updateUsername(userId, newUsername);
    if (error == null) {
      state = state.copyWith(
          user: state.user!
              .copyWith(username: newUsername.trim().toLowerCase()));
    }
    return error;
  }

  Future<void> updateLocation(String city, String country) async {
    final userId = state.user?.id;
    if (userId == null) return;
    await _service.updateLocation(userId, city, country);
    state = state.copyWith(
      user: state.user!.copyWith(city: city.trim(), country: country.trim()),
    );
  }

  /// Deletes all user data (Firestore + Firebase Auth). Returns error or null.
  Future<String?> deleteAccount() async {
    final userId = state.user?.id;
    if (userId == null) return 'Not logged in.';
    final error = await _service.deleteAccount(userId);
    if (error == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
    return error;
  }

  void clearError() => state = state.copyWith(clearError: true);
}

// ── Provider ───────────────────────────────────────────────────────────────────
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
