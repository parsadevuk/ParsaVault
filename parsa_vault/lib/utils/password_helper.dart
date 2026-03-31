class PasswordHelper {
  PasswordHelper._();

  static PasswordStrength strength(String password) {
    if (password.length < 6) return PasswordStrength.weak;
    if (password.length < 8) return PasswordStrength.fair;
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;
    if (score <= 1) return PasswordStrength.fair;
    if (score == 2) return PasswordStrength.good;
    return PasswordStrength.strong;
  }
}

enum PasswordStrength { weak, fair, good, strong }
