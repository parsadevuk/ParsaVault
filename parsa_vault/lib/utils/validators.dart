class AppValidators {
  AppValidators._();

  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Full name is required.';
    if (value.trim().length < 2) return 'Name is too short.';
    if (value.trim().length > 60) return 'Name is too long.';
    return null;
  }

  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) return 'Username is required.';
    final cleaned = value.trim().toLowerCase();
    if (cleaned.length < 3) return 'Username must be at least 3 characters.';
    if (cleaned.length > 20) return 'Username must be under 20 characters.';
    final validChars = RegExp(r'^[a-z0-9_]+$');
    if (!validChars.hasMatch(cleaned)) {
      return 'Only letters, numbers and underscores.';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required.';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return "That doesn't look like a valid email.";
    }
    return null;
  }

  static String? website(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final urlRegex = RegExp(
      r'^(https?://)?([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}(/.*)?$',
    );
    if (!urlRegex.hasMatch(value.trim())) return 'Enter a valid website URL.';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    if (value.length < 8) return 'Password must be at least 8 characters.';
    return null;
  }

  static String? confirmPassword(String? value, String? original) {
    if (value == null || value.isEmpty) return 'Please confirm your password.';
    if (value != original) return "Passwords don't match. Try again.";
    return null;
  }

  static String? loginField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email or username is required.';
    }
    return null;
  }

  static String? amount(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter an amount.';
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return 'Enter a valid number.';
    if (parsed <= 0) return 'Amount must be more than zero.';
    return null;
  }

  static String? shares(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter how many shares you want.';
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return 'Enter a valid number.';
    if (parsed <= 0) return 'Amount must be more than zero.';
    return null;
  }
}
