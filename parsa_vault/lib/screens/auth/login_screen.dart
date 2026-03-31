import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/validators.dart';
import '../../widgets/buttons/gold_button.dart';
import '../../widgets/buttons/sso_buttons.dart';
import '../../widgets/inputs/gold_input_field.dart';
import '../main/main_navigation.dart';
import 'register_screen.dart';
import 'sso_complete_profile_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _loginCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final success = await ref.read(authProvider.notifier).login(
          emailOrUsername: _loginCtrl.text,
          password: _passCtrl.text,
        );
    if (success && mounted) _goHome();
  }

  Future<void> _ssoSignIn(Future<bool> Function() ssoCall) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final success = await ssoCall();
    if (!success || !mounted) return;
    if (ref.read(authProvider).isNewSsoUser) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (_) => const SsoCompleteProfileScreen()),
        (_) => false,
      );
    } else {
      _goHome();
    }
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigation()),
      (_) => false,
    );
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
                  const SizedBox(height: 64),

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
                    child:
                        Text('Welcome Back', style: AppTextStyles.screenTitle),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Log in to your vault.',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.mediumGrey),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Error banner
                  if (authState.error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.dangerRed.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.dangerRed.withValues(alpha: 0.3)),
                      ),
                      child: Text(authState.error!,
                          style: AppTextStyles.errorText),
                    ),
                    const SizedBox(height: 16),
                  ],

                  GoldInputField(
                    label: 'Email or Username',
                    hint: 'you@example.com',
                    controller: _loginCtrl,
                    validator: AppValidators.loginField,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  GoldInputField(
                    label: 'Password',
                    hint: 'Your password',
                    controller: _passCtrl,
                    validator: AppValidators.password,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onEditingComplete: _submit,
                  ),
                  const SizedBox(height: 12),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                                'Password reset coming in a future update.'),
                            backgroundColor: AppColors.nearBlack,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                      child: Text(
                        'Forgot password?',
                        style: AppTextStyles.label
                            .copyWith(color: AppColors.gold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  GoldButton(
                    label: 'Log In',
                    onPressed: _submit,
                    isLoading: authState.isLoading,
                  ),
                  const SizedBox(height: 16),

                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen()),
                      ),
                      child: RichText(
                        text: TextSpan(
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.mediumGrey),
                          children: [
                            const TextSpan(text: "Don't have an account? "),
                            TextSpan(
                              text: 'Register',
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
                  SsoIconRow(
                    onApple: () => _ssoSignIn(
                        () => ref.read(authProvider.notifier).signInWithApple()),
                    onGoogle: () => _ssoSignIn(
                        () => ref.read(authProvider.notifier).signInWithGoogle()),
                    onMicrosoft: () => _ssoSignIn(
                        () => ref.read(authProvider.notifier).signInWithMicrosoft()),
                  ),
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
