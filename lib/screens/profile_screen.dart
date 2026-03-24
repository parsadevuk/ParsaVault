import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/database_service.dart';
import '../services/xp_service.dart';
import '../models/user_model.dart';

import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _isLoading = true;
  double _netWorth = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) return;

    final user = await DatabaseService.instance.getUserById(userId);
    final holdings = await DatabaseService.instance.getHoldings(userId);

    double holdingsValue = 0;
    for (final h in holdings) {
      final isCrypto = ApiService.popularCryptos.any(
        (c) => c['symbol'] == h.symbol,
      );
      double? price;
      if (isCrypto) {
        price = await ApiService.instance.fetchCryptoPrice(h.symbol);
      } else {
        price = await ApiService.instance.fetchStockPrice(h.symbol);
      }
      holdingsValue += h.shares * (price ?? h.averageBuyPrice);
    }

    if (!mounted) return;
    setState(() {
      _user = user;
      _netWorth = (user?.cashBalance ?? 0) + holdingsValue;
      _isLoading = false;
    });
  }

  String get _initials {
    if (_user == null) return '?';
    final parts = _user!.fullName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length > 2 ? 2 : parts[0].length).toUpperCase();
  }

  Future<void> _resetPortfolio() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reset Portfolio',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),
        content: Text(
          'This will reset your cash to \$10,000, clear all holdings, transaction history, and reset your XP and level to zero. This cannot be undone.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.secondaryText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.secondaryText),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Reset',
              style: GoogleFonts.inter(
                color: AppColors.dangerRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || _user == null) return;

    await DatabaseService.instance.resetPortfolio(_user!.id!);
    _loadProfile();
  }

  Future<void> _depositCash() async {
    final amount = await _showAmountDialog('Deposit Cash');
    if (amount == null || amount <= 0 || _user == null) return;

    await DatabaseService.instance.updateUserBalance(
      _user!.id!,
      _user!.cashBalance + amount,
    );
    _loadProfile();
  }

  Future<void> _withdrawCash() async {
    final amount = await _showAmountDialog('Withdraw Cash');
    if (amount == null || amount <= 0 || _user == null) return;

    if (amount > _user!.cashBalance) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient balance.'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
      return;
    }

    await DatabaseService.instance.updateUserBalance(
      _user!.id!,
      _user!.cashBalance - amount,
    );
    _loadProfile();
  }

  Future<void> _changePassword() async {
    final newPassword = await _showPasswordDialog();
    if (newPassword == null || newPassword.isEmpty || _user == null) return;

    await DatabaseService.instance.updateUserPassword(_user!.id!, newPassword);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password updated successfully.'),
        backgroundColor: AppColors.successGreen,
      ),
    );
  }

  Future<double?> _showAmountDialog(String title) async {
    final controller = TextEditingController();
    return showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: 'Amount (\$)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.secondaryText)),
          ),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              Navigator.pop(context, amount);
            },
            child: Text('Confirm', style: GoogleFonts.inter(color: AppColors.goldAccent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<String?> _showPasswordDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Password', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'New password (min 8 characters)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.secondaryText)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.length >= 8) {
                Navigator.pop(context, controller.text);
              }
            },
            child: Text('Update', style: GoogleFonts.inter(color: AppColors.goldAccent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.goldAccent),
        ),
      );
    }

    final xpService = XpService.instance;
    final userLevel = _user?.level ?? 1;
    final userXp = _user?.xp ?? 0;
    final nextLevelXp = xpService.getXpForNextLevel(userLevel);
    final xpProgress = xpService.getProgressToNextLevel(userXp, userLevel);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Avatar
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.goldAccent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _initials,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _user?.username ?? '',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _user?.email ?? '',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.secondaryText,
                ),
              ),
              if (_user?.website != null && _user!.website!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  _user!.website!,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.goldAccent,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              // Level badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.goldAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.goldAccent),
                ),
                child: Text(
                  'Level $userLevel',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.goldAccent,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$userXp / $nextLevelXp XP',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: xpProgress,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.goldAccent,
                  ),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 24),
              // Stat cards
              Row(
                children: [
                  Expanded(
                    child: _ProfileStatCard(
                      label: 'Cash Balance',
                      value: '\$${(_user?.cashBalance ?? 0).toStringAsFixed(2)}',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ProfileStatCard(
                      label: 'Net Worth',
                      value: '\$${_netWorth.toStringAsFixed(2)}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Account section
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Account',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _ActionButton(label: 'Deposit Cash', onTap: _depositCash),
              const SizedBox(height: 12),
              _ActionButton(label: 'Withdraw Cash', onTap: _withdrawCash),
              const SizedBox(height: 12),
              _ActionButton(label: 'Change Password', onTap: _changePassword),
              const SizedBox(height: 12),
              _ActionButton(
                label: 'Reset Portfolio',
                onTap: _resetPortfolio,
                isDanger: true,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _logout,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Log Out',
                    style: GoogleFonts.inter(
                      color: AppColors.secondaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileStatCard extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileStatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDanger;

  const _ActionButton({
    required this.label,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? AppColors.dangerRed : AppColors.primaryText;
    final borderColor = isDanger ? AppColors.dangerRed : AppColors.border;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: borderColor),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ),
    );
  }
}
