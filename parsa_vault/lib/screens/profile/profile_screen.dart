import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/common/xp_progress_bar.dart';
import '../../widgets/common/level_badge.dart';
import '../../widgets/common/confirmation_dialog.dart';
import '../../widgets/inputs/gold_input_field.dart';
import '../../widgets/buttons/gold_button.dart';
import '../auth/welcome_screen.dart';
import 'account_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isSsoUser = authState.isSsoUser;
    ref.watch(portfolioProvider);
    if (user == null) return const SizedBox.shrink();

    final totalValue =
        ref.read(portfolioProvider.notifier).getPortfolioValue();

    // Decode profile picture
    ImageProvider? avatarImage;
    if (user.profilePicture != null && user.profilePicture!.isNotEmpty) {
      try {
        avatarImage = MemoryImage(base64Decode(user.profilePicture!));
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: AppColors.softWhite,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ── Top header card ───────────────────────────────────────────────
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                      image: avatarImage != null
                          ? DecorationImage(
                              image: avatarImage, fit: BoxFit.cover)
                          : null,
                    ),
                    child: avatarImage == null
                        ? Center(
                            child: Text(user.initials,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700)),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.mediumGrey)),
                        const SizedBox(height: 2),
                        Text(user.fullName,
                            style: AppTextStyles.cardTitle),
                        const SizedBox(height: 2),
                        Text('@${user.username}',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.mediumGrey)),
                      ],
                    ),
                  ),
                  // Logout icon
                  GestureDetector(
                    onTap: () => _logout(context, ref),
                    child: const Icon(Icons.logout_rounded,
                        size: 22, color: AppColors.mediumGrey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── XP + stats ────────────────────────────────────────────────────
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Column(
                children: [
                  XpProgressBar(xp: user.xp, level: user.level),
                  const SizedBox(height: 14),
                  // Stats row — same style as home page header
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.softWhite,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _StatCol(
                          label: 'Cash',
                          value: AppFormatters.currency(user.cashBalance),
                        ),
                        _StatDivider(),
                        _StatCol(
                          label: 'Net Worth',
                          value: AppFormatters.currency(totalValue),
                        ),
                        _StatDivider(),
                        _StatCol(
                          label: 'Level',
                          value: LevelBadge.labelForLevel(user.level),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Cash actions ──────────────────────────────────────────────────
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Wallet', style: AppTextStyles.sectionHeading),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _FilledPillButton(
                          label: 'Deposit',
                          color: AppColors.dangerRed,
                          icon: Icons.add_rounded,
                          onPressed: () =>
                              _showCashSheet(context, ref, isDeposit: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FilledPillButton(
                          label: 'Withdraw',
                          color: AppColors.successGreen,
                          icon: Icons.arrow_upward_rounded,
                          onPressed: () =>
                              _showCashSheet(context, ref, isDeposit: false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text('−10 XP penalty',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.dangerRed, fontSize: 11)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('+10 XP reward',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.successGreen, fontSize: 11)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Settings list ─────────────────────────────────────────────────
            Container(
              color: AppColors.white,
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.person_outline_rounded,
                    label: 'User Profile',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const AccountScreen()),
                    ),
                  ),
                  const _TileDivider(),
                  _SettingsTile(
                    icon: Icons.lock_outline_rounded,
                    label: 'Change Password',
                    onTap: () {
                      if (isSsoUser) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                                'Password change is not available for social sign-in accounts (Google, Apple, Microsoft).'),
                            backgroundColor: AppColors.nearBlack,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                        return;
                      }
                      _showChangePasswordSheet(context, ref);
                    },
                  ),
                  const _TileDivider(),
                  _SettingsTile(
                    icon: Icons.help_outline_rounded,
                    label: 'FAQs',
                    onTap: () => _showComingSoon(context, 'FAQs'),
                  ),
                  const _TileDivider(),
                  _SettingsTile(
                    icon: Icons.notifications_none_rounded,
                    label: 'Push Notifications',
                    trailing: Switch(
                      value: false,
                      onChanged: (_) => _showComingSoon(context, 'Push Notifications'),
                      activeColor: AppColors.gold,
                    ),
                    onTap: () => _showComingSoon(context, 'Push Notifications'),
                    showChevron: false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Danger zone ───────────────────────────────────────────────────
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Danger Zone', style: AppTextStyles.sectionHeading),
                  const SizedBox(height: 4),
                  Text('This cannot be undone.',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mediumGrey)),
                  const SizedBox(height: 16),
                  _FilledPillButton(
                    label: 'Reset All Progress',
                    color: AppColors.dangerRed,
                    icon: Icons.refresh_rounded,
                    onPressed: () => _resetAll(context, ref),
                  ),
                  const SizedBox(height: 12),
                  _FilledPillButton(
                    label: 'Delete Account',
                    color: const Color(0xFF7B1E1E),
                    icon: Icons.delete_forever_rounded,
                    onPressed: () => _deleteAccount(context, ref),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────────────

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming in a future update.'),
        backgroundColor: AppColors.nearBlack,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const WelcomeScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (_) => false,
    );
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Delete account?',
      body:
          'This permanently deletes your profile, holdings, history and XP. This cannot be undone.',
      confirmLabel: 'Delete Account',
    );
    if (!confirmed || !context.mounted) return;

    final navigator = Navigator.of(context);
    final error = await ref.read(authProvider.notifier).deleteAccount();

    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.dangerRed,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    navigator.pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const WelcomeScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (_) => false,
    );
  }

  Future<void> _resetAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Reset everything?',
      body:
          'Wipes your XP, level, holdings, and cash. Starts from zero. Cannot be undone.',
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
}

// ── Settings tile ─────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showChevron;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.softWhite,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: AppColors.nearBlack),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label, style: AppTextStyles.label),
            ),
            if (trailing != null) trailing!,
            if (showChevron)
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: AppColors.mediumGrey),
          ],
        ),
      ),
    );
  }
}

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 74, endIndent: 24);
  }
}

// ── Stat column + divider (matches home page style) ──────────────────────────

class _StatCol extends StatelessWidget {
  final String label;
  final String value;
  const _StatCol({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.nearBlack,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.mediumGrey,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: AppColors.borderGrey);
  }
}

// ── Mini stat card (kept for reference — replaced by _StatCol) ────────────────

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _MiniStatCard({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.softWhite,
        borderRadius: BorderRadius.circular(10),
        border: highlight
            ? const Border(left: BorderSide(color: AppColors.gold, width: 3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
          const SizedBox(height: 4),
          Text(value,
              style: AppTextStyles.label.copyWith(fontSize: 12),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ── Cash sheet ────────────────────────────────────────────────────────────────

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
    final success = widget.isDeposit
        ? await notifier.deposit(amount)
        : await notifier.withdraw(amount);
    if (!mounted) return;
    setState(() => _loading = false);
    if (success) {
      widget.ref.read(portfolioProvider.notifier).clearMessages();
      Navigator.of(context).pop();
    } else {
      final err = widget.ref.read(portfolioProvider).error ?? 'Error.';
      widget.ref.read(portfolioProvider.notifier).clearMessages();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err),
        backgroundColor: AppColors.dangerRed,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
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
              Text(widget.isDeposit ? 'Deposit Cash' : 'Withdraw Cash',
                  style: AppTextStyles.sectionHeading),
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
      ),
    );
  }
}

// ── Change password sheet ─────────────────────────────────────────────────────

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
    setState(() { _loading = true; _error = null; });
    setState(() => _loading = false);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Password changed.'),
        backgroundColor: AppColors.nearBlack,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
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
      ),
    );
  }
}

// ── Filled pill button ────────────────────────────────────────────────────────

class _FilledPillButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final IconData? icon;

  const _FilledPillButton({
    required this.label,
    required this.color,
    this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final style = ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      disabledBackgroundColor: AppColors.borderGrey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      elevation: 0,
      shadowColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16),
    );
    final labelText =
        Text(label, style: AppTextStyles.buttonText.copyWith(color: Colors.white));

    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: icon != null
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18, color: Colors.white),
              label: labelText,
              style: style,
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: style,
              child: labelText,
            ),
    );
  }
}
