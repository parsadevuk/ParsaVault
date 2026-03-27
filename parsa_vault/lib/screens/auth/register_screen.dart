import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/validators.dart';
import '../../utils/password_helper.dart';
import '../../widgets/buttons/gold_button.dart';
import '../../widgets/buttons/sso_buttons.dart';
import '../../widgets/inputs/gold_input_field.dart';
import '../main/main_navigation.dart';
import 'login_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  PasswordStrength _strength = PasswordStrength.weak;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _websiteCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final success = await ref.read(authProvider.notifier).register(
          fullName: _nameCtrl.text,
          username: _usernameCtrl.text,
          email: _emailCtrl.text,
          website: _websiteCtrl.text.isEmpty ? null : _websiteCtrl.text,
          password: _passCtrl.text,
        );
    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
        (_) => false,
      );
    }
  }

  Color get _strengthColor {
    switch (_strength) {
      case PasswordStrength.weak:
        return AppColors.dangerRed;
      case PasswordStrength.fair:
        return Colors.orange;
      case PasswordStrength.good:
        return Colors.blue;
      case PasswordStrength.strong:
        return AppColors.successGreen;
    }
  }

  String get _strengthLabel {
    switch (_strength) {
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.fair:
        return 'Fair';
      case PasswordStrength.good:
        return 'Good';
      case PasswordStrength.strong:
        return 'Strong';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),

                  // Logo
                  Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.gold, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          'P',
                          style: AppTextStyles.screenTitle.copyWith(
                            color: AppColors.gold,
                            fontSize: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Center(
                    child: Text('Create Account',
                        style: AppTextStyles.screenTitle),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Start your trading path today.',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.mediumGrey),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Error banner
                  if (authState.error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.dangerRed.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color:
                                AppColors.dangerRed.withValues(alpha: 0.3)),
                      ),
                      child: Text(authState.error!,
                          style: AppTextStyles.errorText),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Form fields
                  GoldInputField(
                    label: 'Full Name',
                    hint: 'Your full name',
                    controller: _nameCtrl,
                    validator: AppValidators.fullName,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  GoldInputField(
                    label: 'Username',
                    hint: 'e.g. tradingwolf',
                    controller: _usernameCtrl,
                    validator: AppValidators.username,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  GoldInputField(
                    label: 'Email',
                    hint: 'you@example.com',
                    controller: _emailCtrl,
                    validator: AppValidators.email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  GoldInputField(
                    label: 'Website',
                    hint: 'https://yoursite.com',
                    controller: _websiteCtrl,
                    validator: AppValidators.website,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.next,
                    optional: true,
                  ),
                  const SizedBox(height: 16),
                  GoldInputField(
                    label: 'Password',
                    hint: 'At least 8 characters',
                    controller: _passCtrl,
                    validator: AppValidators.password,
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    onChanged: (v) =>
                        setState(() => _strength = PasswordHelper.strength(v)),
                  ),
                  if (_passCtrl.text.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: (_strength.index + 1) / 4,
                              minHeight: 4,
                              backgroundColor: AppColors.borderGrey,
                              valueColor:
                                  AlwaysStoppedAnimation(_strengthColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _strengthLabel,
                          style: AppTextStyles.caption
                              .copyWith(color: _strengthColor),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  GoldInputField(
                    label: 'Confirm Password',
                    hint: 'Same password again',
                    controller: _confirmCtrl,
                    validator: (v) =>
                        AppValidators.confirmPassword(v, _passCtrl.text),
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onEditingComplete: _submit,
                  ),
                  const SizedBox(height: 32),

                  GoldButton(
                    label: 'Create Account',
                    onPressed: _submit,
                    isLoading: authState.isLoading,
                  ),
                  const SizedBox(height: 16),

                  // Log in link
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (_) => const LoginScreen()),
                      ),
                      child: RichText(
                        text: TextSpan(
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.mediumGrey),
                          children: [
                            const TextSpan(text: 'Already have an account? '),
                            TextSpan(
                              text: 'Log in',
                              style: AppTextStyles.label
                                  .copyWith(color: AppColors.gold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // SSO divider + buttons
                  const SsoDivider(),
                  AppleSignInButton(onPressed: null),
                  const SizedBox(height: 12),
                  GoogleSignInButton(onPressed: null),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
