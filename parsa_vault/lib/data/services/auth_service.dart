import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../models/user.dart';
import '../../utils/constants.dart';
import '../../utils/xp_calculator.dart';
import '../repositories/user_repository.dart';

class AuthResult {
  final bool success;
  final String? error;
  final User? user;

  const AuthResult({required this.success, this.error, this.user});
}

class AuthService {
  final _userRepo = UserRepository();
  final _auth = fb.FirebaseAuth.instance;

  // ── Session ───────────────────────────────────────────────────────────────

  /// Returns the signed-in user's local profile, or null if signed out.
  Future<User?> getSessionUser() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    return _userRepo.findById(fbUser.uid);
  }

  /// True if any user profiles exist in the local database.
  Future<bool> anyUsersExist() => _userRepo.anyUsersExist();

  /// Whether the current Firebase user has verified their email.
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // ── Email + Password ──────────────────────────────────────────────────────

  Future<AuthResult> register({
    required String fullName,
    required String username,
    required String email,
    String? website,
    required String password,
  }) async {
    if (await _userRepo.usernameExists(username.trim().toLowerCase())) {
      return const AuthResult(
        success: false,
        error: 'That username is already taken. Try a different one.',
      );
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final uid = credential.user!.uid;
      final now = DateTime.now().toUtc();

      final user = User(
        id: uid,
        fullName: fullName.trim(),
        username: username.trim().toLowerCase(),
        email: email.trim().toLowerCase(),
        website: website?.trim().isNotEmpty == true ? website!.trim() : null,
        passwordHash: '',
        cashBalance: AppConstants.startingCash,
        xp: 0,
        level: 1,
        createdAt: now,
        updatedAt: now,
        lastLoginAt: null,
      );

      await _userRepo.insert(user);

      // Send verification email (non-blocking — we don't gate login on it)
      try {
        await credential.user!.sendEmailVerification();
      } catch (_) {}

      return AuthResult(success: true, user: user);
    } on fb.FirebaseAuthException catch (e) {
      return AuthResult(success: false, error: _authError(e.code));
    }
  }

  Future<AuthResult> login({
    required String emailOrUsername,
    required String password,
  }) async {
    String email;
    if (emailOrUsername.contains('@')) {
      email = emailOrUsername.trim().toLowerCase();
    } else {
      final profile = await _userRepo
          .findByEmailOrUsername(emailOrUsername.trim().toLowerCase());
      if (profile == null) {
        return const AuthResult(
          success: false,
          error: "We couldn't log you in. Check your details and try again.",
        );
      }
      email = profile.email;
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = await _userRepo.findById(credential.user!.uid);
      if (user == null) {
        await _auth.signOut();
        return const AuthResult(
          success: false,
          error: 'Account data not found. Please register again.',
        );
      }

      final updatedUser = await _awardDailyLoginXp(user);
      await _userRepo.updateLastLogin(updatedUser.id);
      return AuthResult(success: true, user: updatedUser);
    } on fb.FirebaseAuthException catch (e) {
      return AuthResult(success: false, error: _authError(e.code));
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<AuthResult> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) {
      return const AuthResult(success: false, error: 'Not signed in.');
    }

    try {
      final credential = fb.EmailAuthProvider.credential(
        email: fbUser.email!,
        password: currentPassword,
      );
      await fbUser.reauthenticateWithCredential(credential);
      await fbUser.updatePassword(newPassword);
      return const AuthResult(success: true);
    } on fb.FirebaseAuthException catch (e) {
      return AuthResult(success: false, error: _authError(e.code));
    }
  }

  // ── Email Verification ────────────────────────────────────────────────────

  /// Sends a verification email to the current user's address.
  Future<void> sendVerificationEmail() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on fb.FirebaseAuthException catch (_) {}
  }

  /// Re-fetches Firebase user state to get the latest emailVerified flag.
  Future<bool> refreshEmailVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  // ── Google SSO ────────────────────────────────────────────────────────────

  Future<AuthResult> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // User cancelled the picker
        return const AuthResult(success: false, error: null);
      }

      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = await _getOrCreateSsoProfile(userCredential.user!);
      final updatedUser = await _awardDailyLoginXp(user);
      await _userRepo.updateLastLogin(updatedUser.id);

      return AuthResult(success: true, user: updatedUser);
    } on fb.FirebaseAuthException catch (e) {
      return AuthResult(success: false, error: _authError(e.code));
    } catch (_) {
      return const AuthResult(
          success: false, error: 'Google sign-in failed. Please try again.');
    }
  }

  // ── Apple SSO ─────────────────────────────────────────────────────────────

  Future<AuthResult> signInWithApple() async {
    final rawNonce = _generateNonce();
    final hashedNonce = _sha256(rawNonce);

    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final oauthCredential = fb.OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);

      // Apple only provides the name on first sign-in — cache it
      final fbUser = userCredential.user!;
      if (appleCredential.givenName != null) {
        final fullName =
            '${appleCredential.givenName} ${appleCredential.familyName ?? ''}'
                .trim();
        await fbUser.updateDisplayName(fullName);
      }

      final user = await _getOrCreateSsoProfile(fbUser);
      final updatedUser = await _awardDailyLoginXp(user);
      await _userRepo.updateLastLogin(updatedUser.id);

      return AuthResult(success: true, user: updatedUser);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return const AuthResult(success: false, error: null); // user cancelled
      }
      return const AuthResult(
          success: false, error: 'Apple sign-in failed. Please try again.');
    } on fb.FirebaseAuthException catch (e) {
      return AuthResult(success: false, error: _authError(e.code));
    }
  }

  // ── Microsoft SSO ─────────────────────────────────────────────────────────

  Future<AuthResult> signInWithMicrosoft() async {
    try {
      final provider = fb.OAuthProvider('microsoft.com')
        ..addScope('email')
        ..addScope('openid')
        ..addScope('profile');

      final userCredential = await _auth.signInWithProvider(provider);
      final user = await _getOrCreateSsoProfile(userCredential.user!);
      final updatedUser = await _awardDailyLoginXp(user);
      await _userRepo.updateLastLogin(updatedUser.id);

      return AuthResult(success: true, user: updatedUser);
    } on fb.FirebaseAuthException catch (e) {
      return AuthResult(success: false, error: _authError(e.code));
    } catch (_) {
      return const AuthResult(
          success: false,
          error: 'Microsoft sign-in failed. Please try again.');
    }
  }

  // ── Other ─────────────────────────────────────────────────────────────────

  Future<User> refreshUser(String userId) async {
    final user = await _userRepo.findById(userId);
    return user!;
  }

  Future<void> updateProfilePicture(String userId, String? base64Image) async {
    await _userRepo.updateProfilePicture(userId, base64Image);
  }

  Future<void> updateWebsite(String userId, String? website) async {
    await _userRepo.updateWebsite(userId, website);
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Gets an existing local profile or creates a new one for SSO sign-ins.
  Future<User> _getOrCreateSsoProfile(fb.User fbUser) async {
    final existing = await _userRepo.findById(fbUser.uid);
    if (existing != null) return existing;

    final base = _generateUsername(
        fbUser.displayName, fbUser.email ?? fbUser.uid.substring(0, 8));
    final username = await _uniqueUsername(base);
    final now = DateTime.now().toUtc();

    final user = User(
      id: fbUser.uid,
      fullName: fbUser.displayName ?? username,
      username: username,
      email: fbUser.email ?? '',
      website: null,
      passwordHash: '',
      cashBalance: AppConstants.startingCash,
      xp: 0,
      level: 1,
      createdAt: now,
      updatedAt: now,
      lastLoginAt: null,
    );

    await _userRepo.insert(user);
    return user;
  }

  String _generateUsername(String? displayName, String email) {
    String base;
    if (displayName != null && displayName.trim().isNotEmpty) {
      base = displayName
          .toLowerCase()
          .replaceAll(' ', '')
          .replaceAll(RegExp(r'[^a-z0-9]'), '');
    } else {
      base = email
          .split('@')
          .first
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '');
    }
    final trimmed = base.isEmpty ? 'user' : base;
    return trimmed.substring(0, trimmed.length.clamp(0, 20));
  }

  Future<String> _uniqueUsername(String base) async {
    if (!await _userRepo.usernameExists(base)) return base;
    for (int i = 2; i <= 999; i++) {
      final candidate = '$base$i';
      if (!await _userRepo.usernameExists(candidate)) return candidate;
    }
    return '${base}_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Daily login XP — uses UTC/Greenwich time, resets at midnight UTC.
  Future<User> _awardDailyLoginXp(User user) async {
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    final lastLogin = user.lastLoginAt;

    bool shouldAward;
    if (lastLogin == null) {
      shouldAward = true;
    } else {
      final lastDay = DateTime.utc(lastLogin.toUtc().year,
          lastLogin.toUtc().month, lastLogin.toUtc().day);
      shouldAward = lastDay.isBefore(today);
    }

    if (shouldAward) {
      final newXp = user.xp + AppConstants.xpDailyLogin;
      final newLevel = XpCalculator.getLevelFromXp(newXp);
      final updated = user.copyWith(xp: newXp, level: newLevel);
      await _userRepo.update(updated);
      return updated;
    }

    return user;
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
        length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  String _authError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'That email is already registered. Log in instead.';
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-credential':
        return "We couldn't log you in. Check your details and try again.";
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'network-request-failed':
        return 'No internet connection. Check your network and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled yet.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
