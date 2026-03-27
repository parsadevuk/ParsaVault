import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/buttons/gold_outline_button.dart';
import '../../widgets/buttons/destructive_button.dart';
import '../../widgets/common/xp_progress_bar.dart';
import '../../widgets/common/level_badge.dart';
import '../../widgets/common/confirmation_dialog.dart';
import '../../widgets/inputs/gold_input_field.dart';
import '../../widgets/buttons/gold_button.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    ref.watch(portfolioProvider);

    if (user == null) return const SizedBox.shrink();

    final totalValue = ref.read(portfolioProvider.notifier).getPortfolioValue();

    // Decode profile picture if present
    ImageProvider? avatarImage;
    if (user.profilePicture != null && user.profilePicture!.isNotEmpty) {
      try {
        avatarImage = MemoryImage(base64Decode(user.profilePicture!));
      } catch (_) {
        avatarImage = null;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const SizedBox(height: 16),
            Text('Profile', style: AppTextStyles.screenTitle),
            const SizedBox(height: 24),

            // Avatar + user info
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _pickProfilePicture(context, ref),
                    child: Stack(
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            shape: BoxShape.circle,
                            image: avatarImage != null
                                ? DecorationImage(
                                    image: avatarImage,
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: avatarImage == null
                              ? Center(
                                  child: Text(
                                    user.initials,
                                    style: AppTextStyles.priceLarge.copyWith(
                                        color: Colors.white, fontSize: 28),
                                  ),
                                )
                              : null,
                        ),
                        // Camera edit badge
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: AppColors.nearBlack,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(user.fullName, style: AppTextStyles.cardTitle),
                  const SizedBox(height: 4),
                  Text('@${user.username}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mediumGrey)),
                  const SizedBox(height: 4),
                  Text(user.email,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mediumGrey)),
                  if (user.website != null && user.website!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(user.website!,
                        style:
                            AppTextStyles.caption.copyWith(color: AppColors.gold)),
                  ],
                  const SizedBox(height: 12),
                  LevelBadge(level: user.level),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // XP bar
            XpProgressBar(xp: user.xp, level: user.level),
            const SizedBox(height: 20),

            // Stats cards
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Cash Balance',
                    value: AppFormatters.currency(user.cashBalance),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Net Worth',
                    value: AppFormatters.currency(totalValue),
                    highlight: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Action buttons
            Text('Account', style: AppTextStyles.sectionHeading),
            const SizedBox(height: 16),
            GoldOutlineButton(
              label: 'Change Photo',
              icon: Icons.photo_camera_outlined,
              onPressed: () => _pickProfilePicture(context, ref),
            ),
            const SizedBox(height: 12),
            GoldOutlineButton(
              label: 'Deposit Cash',
              icon: Icons.add_rounded,
              onPressed: () => _showCashSheet(context, ref, isDeposit: true),
            ),
            const SizedBox(height: 12),
            GoldOutlineButton(
              label: 'Withdraw Cash',
              icon: Icons.remove_rounded,
              onPressed: () => _showCashSheet(context, ref, isDeposit: false),
            ),
            const SizedBox(height: 12),
            GoldOutlineButton(
              label: 'Change Password',
              icon: Icons.lock_outline_rounded,
              onPressed: () => _showChangePasswordSheet(context, ref),
            ),
            const SizedBox(height: 28),

            // Danger zone
            Text('Danger Zone', style: AppTextStyles.sectionHeading),
            const SizedBox(height: 4),
            const Divider(),
            const SizedBox(height: 16),
            DestructiveButton(
              label: 'Reset Portfolio',
              onPressed: () => _resetPortfolio(context, ref),
            ),
            const SizedBox(height: 6),
            Text(
              'Clears your holdings. Keeps your XP.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 12),
            DestructiveButton(
              label: 'Reset All Progress',
              onPressed: () => _resetAll(context, ref),
            ),
            const SizedBox(height: 6),
            Text(
              'Resets everything. XP, level, balance. Fresh start.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 28),

            // Logout
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                onPressed: () => _logout(context, ref),
                child: Text('Log Out',
                    style: AppTextStyles.label
                        .copyWith(color: AppColors.mediumGrey)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _pickProfilePicture(BuildContext context, WidgetRef ref) async {
    final choice = await showModalBottomSheet<_PhotoAction>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.borderGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppColors.nearBlack),
                title: Text('Choose from Library', style: AppTextStyles.label),
                onTap: () =>
                    Navigator.of(sheetCtx).pop(_PhotoAction.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: AppColors.nearBlack),
                title: Text('Take a Photo', style: AppTextStyles.label),
                onTap: () =>
                    Navigator.of(sheetCtx).pop(_PhotoAction.camera),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: AppColors.dangerRed),
                title: Text('Remove Photo',
                    style: AppTextStyles.label
                        .copyWith(color: AppColors.dangerRed)),
                onTap: () =>
                    Navigator.of(sheetCtx).pop(_PhotoAction.remove),
              ),
            ],
          ),
        ),
      ),
    );

    if (choice == null || !context.mounted) return;

    if (choice == _PhotoAction.remove) {
      await ref.read(authProvider.notifier).updateProfilePicture(null);
      return;
    }

    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: choice == _PhotoAction.gallery
            ? ImageSource.gallery
            : ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      final base64Str = base64Encode(bytes);

      await ref.read(authProvider.notifier).updateProfilePicture(base64Str);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not load photo. Please try again.'),
            backgroundColor: AppColors.dangerRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Log out?',
      body: "You'll need to log back in to access your vault.",
      confirmLabel: 'Log Out',
      isDestructive: false,
    );
    if (!confirmed || !context.mounted) return;
    final navigator = Navigator.of(context);
    await ref.read(authProvider.notifier).logout();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _resetPortfolio(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Reset your portfolio?',
      body:
          'This clears all your holdings and sets your cash back to \$10,000. Your XP and level stay.',
      confirmLabel: 'Reset Portfolio',
    );
    if (!confirmed || !context.mounted) return;
    await ref.read(portfolioProvider.notifier).resetPortfolio();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Portfolio reset. Starting fresh with \$10,000.'),
          backgroundColor: AppColors.nearBlack,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _resetAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Reset everything?',
      body:
          'This wipes your XP, level, holdings, and cash. You\'ll start from zero. This can\'t be undone.',
      confirmLabel: 'Reset Everything',
    );
    if (!confirmed || !context.mounted) return;
    await ref.read(portfolioProvider.notifier).resetAll();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('All progress reset. Back to zero.'),
          backgroundColor: AppColors.nearBlack,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showCashSheet(BuildContext context, WidgetRef ref,
      {required bool isDeposit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CashSheet(isDeposit: isDeposit, ref: ref),
    );
  }

  void _showChangePasswordSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ChangePasswordSheet(ref: ref),
    );
  }
}

enum _PhotoAction { gallery, camera, remove }

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _StatCard({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.softWhite,
        borderRadius: BorderRadius.circular(12),
        border: highlight
            ? const Border(left: BorderSide(color: AppColors.gold, width: 3))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 6),
          Text(value,
              style: AppTextStyles.priceMedium.copyWith(fontSize: 16),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _CashSheet extends StatefulWidget {
  final bool isDeposit;
  final WidgetRef ref;
  const _CashSheet({required this.isDeposit, required this.ref});

  @override
  State<_CashSheet> createState() => _CashSheetState();
}

class _CashSheetState extends State<_CashSheet> {
  final _ctrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final amount = double.parse(_ctrl.text.trim());
    setState(() => _loading = true);

    final notifier = widget.ref.read(portfolioProvider.notifier);
    bool success;
    if (widget.isDeposit) {
      success = await notifier.deposit(amount);
    } else {
      success = await notifier.withdraw(amount);
    }

    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      widget.ref.read(portfolioProvider.notifier).clearMessages();
      Navigator.of(context).pop();
    } else {
      final err = widget.ref.read(portfolioProvider).error ?? 'Error.';
      widget.ref.read(portfolioProvider.notifier).clearMessages();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: AppColors.dangerRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isDeposit ? 'Deposit Cash' : 'Withdraw Cash',
              style: AppTextStyles.sectionHeading,
            ),
            const SizedBox(height: 4),
            Text(
              widget.isDeposit
                  ? 'Add virtual cash to your account.'
                  : 'Move cash out of your portfolio.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.mediumGrey),
            ),
            const SizedBox(height: 20),
            GoldInputField(
              label: 'Amount (USD)',
              hint: '1000',
              controller: _ctrl,
              validator: AppValidators.amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              prefixText: '\$  ',
              textInputAction: TextInputAction.done,
              onEditingComplete: _submit,
            ),
            const SizedBox(height: 20),
            GoldButton(
              label: widget.isDeposit ? 'Deposit' : 'Withdraw',
              onPressed: _submit,
              isLoading: _loading,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  final WidgetRef ref;
  const _ChangePasswordSheet({required this.ref});

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final userId = widget.ref.read(authProvider).user?.id;
    if (userId == null) return;

    setState(() => _loading = false);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password changed.'),
          backgroundColor: AppColors.nearBlack,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Change Password', style: AppTextStyles.sectionHeading),
            const SizedBox(height: 20),
            if (_error != null) ...[
              Text(_error!, style: AppTextStyles.errorText),
              const SizedBox(height: 12),
            ],
            GoldInputField(
              label: 'Current Password',
              hint: 'Your current password',
              controller: _currentCtrl,
              validator: AppValidators.password,
              obscureText: true,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            GoldInputField(
              label: 'New Password',
              hint: 'At least 8 characters',
              controller: _newCtrl,
              validator: AppValidators.password,
              obscureText: true,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            GoldInputField(
              label: 'Confirm New Password',
              hint: 'Same password again',
              controller: _confirmCtrl,
              validator: (v) =>
                  AppValidators.confirmPassword(v, _newCtrl.text),
              obscureText: true,
              textInputAction: TextInputAction.done,
              onEditingComplete: _submit,
            ),
            const SizedBox(height: 20),
            GoldButton(
              label: 'Change Password',
              onPressed: _submit,
              isLoading: _loading,
            ),
          ],
        ),
      ),
    );
  }
}
