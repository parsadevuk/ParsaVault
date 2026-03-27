import 'package:uuid/uuid.dart';
import '../../models/user.dart';
import '../../utils/constants.dart';
import '../../utils/password_helper.dart';
import '../../utils/xp_calculator.dart';
import '../repositories/user_repository.dart';
import '../repositories/session_repository.dart';

const _uuid = Uuid();

class AuthResult {
  final bool success;
  final String? error;
  final User? user;

  const AuthResult({required this.success, this.error, this.user});
}

class AuthService {
  final _userRepo = UserRepository();
  final _sessionRepo = SessionRepository();

  /// Check if there is an active session and return the user.
  Future<User?> getSessionUser() async {
    final userId = await _sessionRepo.getActiveUserId();
    if (userId == null) return null;
    return _userRepo.findById(userId);
  }

  /// True if any users exist in the database.
  Future<bool> anyUsersExist() => _userRepo.anyUsersExist();

  Future<AuthResult> register({
    required String fullName,
    required String username,
    required String email,
    String? website,
    required String password,
  }) async {
    // Check uniqueness
    if (await _userRepo.emailExists(email)) {
      return const AuthResult(
        success: false,
        error: 'That email is already registered. Log in instead.',
      );
    }
    if (await _userRepo.usernameExists(username)) {
      return const AuthResult(
        success: false,
        error: 'That username is already in use. Try a different one.',
      );
    }

    final now = DateTime.now();
    final user = User(
      id: _uuid.v4(),
      fullName: fullName.trim(),
      username: username.trim().toLowerCase(),
      email: email.trim().toLowerCase(),
      website: website?.trim().isNotEmpty == true ? website!.trim() : null,
      passwordHash: PasswordHelper.hash(password),
      cashBalance: AppConstants.startingCash,
      xp: 0,
      level: 1,
      createdAt: now,
      updatedAt: now,
      lastLoginAt: now,
    );

    await _userRepo.insert(user);
    await _createSession(user.id);

    return AuthResult(success: true, user: user);
  }

  Future<AuthResult> login({required String emailOrUsername, required String password}) async {
    final user = await _userRepo.findByEmailOrUsername(emailOrUsername);
    if (user == null) {
      return const AuthResult(
        success: false,
        error: "We couldn't log you in. Check your details and try again.",
      );
    }

    if (!PasswordHelper.verify(password, user.passwordHash)) {
      return const AuthResult(
        success: false,
        error: "We couldn't log you in. Check your details and try again.",
      );
    }

    // Award daily login XP if eligible
    final updatedUser = await _awardDailyLoginXp(user);
    await _userRepo.updateLastLogin(updatedUser.id);
    await _createSession(updatedUser.id);

    return AuthResult(success: true, user: updatedUser);
  }

  Future<void> logout() async {
    await _sessionRepo.clearAll();
  }

  Future<AuthResult> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = await _userRepo.findById(userId);
    if (user == null) {
      return const AuthResult(success: false, error: 'User not found.');
    }
    if (!PasswordHelper.verify(currentPassword, user.passwordHash)) {
      return const AuthResult(
        success: false,
        error: 'Current password is wrong.',
      );
    }
    await _userRepo.updatePassword(userId, PasswordHelper.hash(newPassword));
    return const AuthResult(success: true);
  }

  Future<User> refreshUser(String userId) async {
    final user = await _userRepo.findById(userId);
    return user!;
  }

  // ── Private ─────────────────────────────────────────────────────────────────
  Future<void> _createSession(String userId) async {
    await _sessionRepo.createSession(
      id: _uuid.v4(),
      userId: userId,
      token: _uuid.v4(),
    );
  }

  Future<User> _awardDailyLoginXp(User user) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastLogin = user.lastLoginAt;

    if (lastLogin == null ||
        DateTime(lastLogin.year, lastLogin.month, lastLogin.day)
            .isBefore(today)) {
      final newXp = user.xp + AppConstants.xpDailyLogin;
      final newLevel = XpCalculator.getLevelFromXp(newXp);
      final updated = user.copyWith(xp: newXp, level: newLevel);
      await _userRepo.update(updated);
      return updated;
    }

    return user;
  }
}
