import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/validators.dart';
import '../../widgets/buttons/gold_button.dart';
import '../../widgets/inputs/gold_input_field.dart';
import '../main/main_navigation.dart';

class SsoCompleteProfileScreen extends ConsumerStatefulWidget {
  const SsoCompleteProfileScreen({super.key});

  @override
  ConsumerState<SsoCompleteProfileScreen> createState() =>
      _SsoCompleteProfileScreenState();
}

class _SsoCompleteProfileScreenState
    extends ConsumerState<SsoCompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameCtrl;
  final _websiteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final autoUsername =
        ref.read(authProvider).user?.username ?? '';
    _usernameCtrl = TextEditingController(text: autoUsername);
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final success = await ref.read(authProvider.notifier).completeProfile(
          username: _usernameCtrl.text,
          website: _websiteCtrl.text.trim().isEmpty
              ? null
              : _websiteCtrl.text.trim(),
        );
    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
        (_) => false,
      );
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
                  const SizedBox(height: 64),

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
                    child: Text('Almost There!',
                        style: AppTextStyles.screenTitle),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Choose your username to complete setup.',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.mediumGrey),
                      textAlign: TextAlign.center,
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
                            color:
                                AppColors.dangerRed.withValues(alpha: 0.3)),
                      ),
                      child: Text(authState.error!,
                          style: AppTextStyles.errorText),
                    ),
                    const SizedBox(height: 16),
                  ],

                  GoldInputField(
                    label: 'Username',
                    hint: 'e.g. tradingwolf',
                    controller: _usernameCtrl,
                    validator: AppValidators.username,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  GoldInputField(
                    label: 'Website',
                    hint: 'https://yoursite.com',
                    controller: _websiteCtrl,
                    validator: AppValidators.website,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.done,
                    onEditingComplete: _submit,
                    optional: true,
                  ),
                  const SizedBox(height: 32),

                  GoldButton(
                    label: 'Get Started',
                    onPressed: _submit,
                    isLoading: authState.isLoading,
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
