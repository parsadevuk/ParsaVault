import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/buttons/gold_button.dart';
import '../../widgets/inputs/gold_input_field.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _countryCtrl;
  late final TextEditingController _websiteCtrl;

  bool _loading = false;
  String? _usernameError;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameCtrl = TextEditingController(text: user?.fullName ?? '');
    _usernameCtrl = TextEditingController(text: user?.username ?? '');
    _cityCtrl = TextEditingController(text: user?.city ?? 'London');
    _countryCtrl = TextEditingController(text: user?.country ?? 'UK');
    _websiteCtrl = TextEditingController(text: user?.website ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
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
                    style:
                        AppTextStyles.label.copyWith(color: AppColors.dangerRed)),
                onTap: () =>
                    Navigator.of(sheetCtx).pop(_PhotoAction.remove),
              ),
            ],
          ),
        ),
      ),
    );

    if (choice == null || !mounted) return;

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
      await ref
          .read(authProvider.notifier)
          .updateProfilePicture(base64Encode(bytes));
    } catch (_) {
      if (mounted) {
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

  Future<void> _save() async {
    setState(() => _usernameError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    final notifier = ref.read(authProvider.notifier);
    final user = ref.read(authProvider).user!;

    // Full name
    if (_nameCtrl.text.trim() != user.fullName) {
      await notifier.updateFullName(_nameCtrl.text.trim());
    }

    // Username — check uniqueness
    if (_usernameCtrl.text.trim().toLowerCase() != user.username) {
      final err = await notifier.updateUsername(_usernameCtrl.text.trim());
      if (err != null) {
        if (mounted) setState(() { _usernameError = err; _loading = false; });
        return;
      }
    }

    // Location
    if (_cityCtrl.text.trim() != user.city ||
        _countryCtrl.text.trim() != user.country) {
      await notifier.updateLocation(
          _cityCtrl.text.trim(), _countryCtrl.text.trim());
    }

    // Website
    final website = _websiteCtrl.text.trim().isEmpty
        ? null
        : _websiteCtrl.text.trim();
    if (website != user.website) {
      await notifier.updateWebsite(website);
    }

    if (mounted) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated.'),
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
    final user = ref.watch(authProvider).user;
    if (user == null) return const SizedBox.shrink();

    ImageProvider? avatarImage;
    if (user.profilePicture != null && user.profilePicture!.isNotEmpty) {
      try {
        avatarImage = MemoryImage(base64Decode(user.profilePicture!));
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.nearBlack),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('User Profile', style: AppTextStyles.screenTitle),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
              24, 0, 24, MediaQuery.of(context).padding.bottom + 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Avatar
                GestureDetector(
                  onTap: _pickPhoto,
                  child: Stack(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                          image: avatarImage != null
                              ? DecorationImage(
                                  image: avatarImage, fit: BoxFit.cover)
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
                                child: Text(user.initials,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 30,
                                        fontWeight: FontWeight.w700)),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.nearBlack,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: AppColors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_rounded,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Full Name
                GoldInputField(
                  label: 'Full Name',
                  hint: 'Your full name',
                  controller: _nameCtrl,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter your full name.'
                      : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Username
                GoldInputField(
                  label: 'Username',
                  hint: 'your_username',
                  controller: _usernameCtrl,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter a username.';
                    if (v.trim().length < 3) return 'At least 3 characters.';
                    if (_usernameError != null) return _usernameError;
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Email (read-only display)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.softWhite,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderGrey),
                      ),
                      child: Text(user.email,
                          style: AppTextStyles.inputText.copyWith(
                              color: AppColors.mediumGrey)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // City
                GoldInputField(
                  label: 'City',
                  hint: 'London',
                  controller: _cityCtrl,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter a city.'
                      : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Country
                GoldInputField(
                  label: 'Country',
                  hint: 'UK',
                  controller: _countryCtrl,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter a country.'
                      : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Website
                GoldInputField(
                  label: 'Website (optional)',
                  hint: 'https://yoursite.com',
                  controller: _websiteCtrl,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  onEditingComplete: _save,
                ),
                const SizedBox(height: 28),

                GoldButton(
                  label: 'Save',
                  onPressed: _save,
                  isLoading: _loading,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _PhotoAction { gallery, camera, remove }
