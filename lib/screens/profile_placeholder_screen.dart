import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xillafit_flutter/app_colors.dart';
import 'package:xillafit_flutter/app_spacing.dart';
import 'package:xillafit_flutter/app_text_styles.dart';
import 'package:xillafit_flutter/features/auth/presentation/auth_providers.dart';
import 'package:xillafit_flutter/features/auth/data/bulacan_locations.dart';
import 'package:xillafit_flutter/features/profile/data/profile_model.dart';
import 'package:xillafit_flutter/features/profile/presentation/profile_providers.dart';
import 'package:xillafit_flutter/core/network/connectivity_status.dart';
import 'package:xillafit_flutter/screens/order_history_screen.dart';
import 'package:xillafit_flutter/widgets/common/primary_button.dart';

class ProfilePlaceholderScreen extends ConsumerStatefulWidget {
  const ProfilePlaceholderScreen({super.key});

  @override
  ConsumerState<ProfilePlaceholderScreen> createState() =>
      _ProfilePlaceholderScreenState();
}

class _ProfilePlaceholderScreenState
    extends ConsumerState<ProfilePlaceholderScreen> {
  bool _loading = false;
  bool _editing = false;
  bool _saving = false;
  String? _formError;
  String? _formSuccess;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _streetAddressController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _municipality = '';
  String _barangay = '';
  String _zipCode = '';
  bool _initializedForm = false;
  bool _passwordSaving = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  String? _passwordError;
  String? _passwordSuccess;

  @override
  void initState() {
    super.initState();
    _currentPasswordController.addListener(_handlePasswordInputChanged);
    _newPasswordController.addListener(_handlePasswordInputChanged);
    _confirmPasswordController.addListener(_handlePasswordInputChanged);
  }

  BulacanMunicipality? _municipalityByName(String value) {
    for (final municipality in bulacanMunicipalities) {
      if (municipality.name == value) return municipality;
    }
    return null;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _contactNumberController.dispose();
    _streetAddressController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handlePasswordInputChanged() {
    if (!mounted) return;
    if (_passwordError == null && _passwordSuccess == null) {
      setState(() {});
      return;
    }
    setState(_clearPasswordFeedback);
  }

  Future<bool> _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmLabel,
    bool isDestructive = false,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: isDestructive ? Colors.red.shade600 : AppColors.gold,
                foregroundColor:
                    isDestructive ? Colors.white : AppColors.text,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );

    return confirmed == true;
  }

  Future<void> _signOut() async {
    final confirmed = await _showConfirmationDialog(
      title: 'Sign out?',
      message: 'You will be signed out from this device and will need to log in again to continue.',
      confirmLabel: 'Sign out',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).signOut();
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _syncForm(ProfileModel? profile) {
    if (_initializedForm) return;
    final fullName = (profile?.fullName ?? '').trim();
    final nameParts = fullName.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    final municipality = profile?.municipality ?? '';
    final selectedMunicipality = _municipalityByName(municipality);
    final barangay = profile?.barangay ?? '';
    _firstNameController.text = nameParts.isNotEmpty ? nameParts.first : '';
    _lastNameController.text =
        nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    _contactNumberController.text = profile?.contactNumber ?? '';
    _streetAddressController.text = profile?.streetAddress ?? '';
    _municipality = selectedMunicipality?.name ?? '';
    _barangay = selectedMunicipality?.barangays.contains(barangay) == true ? barangay : '';
    _zipCode = selectedMunicipality?.zipCode ?? (profile?.zipCode ?? '');
    _initializedForm = true;
  }

  void _resetForm(ProfileModel? profile) {
    _initializedForm = false;
    _syncForm(profile);
    _editing = false;
    _formError = null;
    _formSuccess = null;
  }

  Future<void> _saveProfile(ProfileModel? profile) async {
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    final fullName = [first, last].where((part) => part.isNotEmpty).join(' ').trim();
    final contact = _contactNumberController.text.trim();
    final street = _streetAddressController.text.trim();

    if (fullName.isEmpty) {
      setState(() => _formError = 'Please enter your name.');
      return;
    }
    if (contact.isNotEmpty && !RegExp(r'^09\d{9}$').hasMatch(contact)) {
      setState(() => _formError = 'Phone number must start with 09 and be 11 digits.');
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
      _formSuccess = null;
    });

    try {
      await ref.read(profileRepositoryProvider).updateProfile(
            fullName: fullName,
            contactNumber: contact,
            municipality: _municipality,
            barangay: _barangay,
            streetAddress: street,
            zipCode: _zipCode,
            province: 'Bulacan',
          );

      ref.invalidate(currentProfileProvider);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _editing = false;
        _formSuccess = 'Profile saved.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _formError = error.toString();
      });
    }
  }

  String _passwordMode(User? user) {
    if (user == null) return 'none';
    final identities = user.identities;
    if (identities == null || identities.isEmpty) return 'unknown';
    for (final identity in identities) {
      if (identity.provider == 'email') return 'email';
    }
    return 'social';
  }

  void _clearPasswordFeedback() {
    _passwordError = null;
    _passwordSuccess = null;
  }

  String? _passwordValidationMessage(User? user) {
    final mode = _passwordMode(user);
    if (user == null || mode == 'none' || mode == 'unknown') return null;

    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (mode == 'email' && currentPassword.isEmpty) {
      return 'Enter your current password.';
    }
    if (newPassword.isEmpty) {
      return 'Enter a password with at least 8 characters.';
    }
    if (newPassword.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    if (confirmPassword.isEmpty) {
      return 'Confirm your password.';
    }
    if (newPassword != confirmPassword) {
      return 'Password and confirmation do not match.';
    }
    if (mode == 'email' && currentPassword == newPassword) {
      return 'Choose a password different from your current one.';
    }
    return null;
  }

  bool _canSubmitPassword(User? user) {
    if (_passwordSaving) return false;
    final mode = _passwordMode(user);
    if (user == null || mode == 'none' || mode == 'unknown') return false;
    return _passwordValidationMessage(user) == null;
  }

  Future<void> _updatePassword(User? user) async {
    final mode = _passwordMode(user);
    if (user == null || mode == 'none' || mode == 'unknown') {
      setState(() => _passwordError = 'Account sign-in options are still loading.');
      return;
    }

    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    setState(_clearPasswordFeedback);

    if (newPassword.length < 8) {
      setState(() => _passwordError = 'Password must be at least 8 characters.');
      return;
    }
    if (newPassword != confirmPassword) {
      setState(() => _passwordError = 'Password and confirmation do not match.');
      return;
    }
    if (mode == 'email') {
      if (currentPassword.isEmpty) {
        setState(() => _passwordError = 'Enter your current password.');
        return;
      }
      if (currentPassword == newPassword) {
        setState(() => _passwordError = 'Choose a password different from your current one.');
        return;
      }
    }

    final confirmed = await _showConfirmationDialog(
      title: mode == 'social' ? 'Add password?' : 'Update password?',
      message: mode == 'social'
          ? 'This will add an email password to your account so you can sign in with either Google or email.'
          : 'Your account password will be changed. Make sure you remember the new password before continuing.',
      confirmLabel: mode == 'social' ? 'Add password' : 'Update password',
    );
    if (!confirmed || !mounted) return;

    setState(() => _passwordSaving = true);
    try {
      if (mode == 'email') {
        await Supabase.instance.client.auth.signInWithPassword(
          email: user.email ?? '',
          password: currentPassword,
        );
      }

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (!mounted) return;
      setState(() {
        _passwordSaving = false;
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        _passwordSuccess = mode == 'social'
            ? 'Password added. You can sign in with email and password too.'
            : 'Password updated.';
      });
    } on AuthException catch (error) {
      if (!mounted) return;
      final message = error.message.contains('Invalid login credentials')
          ? 'Current password is incorrect.'
          : error.message;
      setState(() {
        _passwordSaving = false;
        _passwordError = message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _passwordSaving = false;
        _passwordError = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider).asData?.value;
    final authUser = session?.user;
    final authEmail = session?.user.email;
    final profileAsync = ref.watch(currentProfileProvider);
    final isOffline = ref.watch(isOfflineProvider).asData?.value ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final horizontalPadding = width < 360 ? 16.0 : 20.0;
        final cardWidth = math.min(width, 560.0);

        return ColoredBox(
          color: AppColors.surface,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              20,
              horizontalPadding,
              28,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: cardWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfileHero(
                      email: authEmail,
                      profileAsync: profileAsync,
                      signingOut: _loading,
                      onSignOut: _loading ? null : _signOut,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0D0F172A),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Account Actions',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Manage your session securely from this device.',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                OrderHistoryScreen.routeName,
                              ),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(46),
                                backgroundColor: AppColors.goldBright,
                                foregroundColor: AppColors.text,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              child: Text(
                                'View Orders',
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    profileAsync.when(
                      loading: () => isOffline
                          ? const _ProfileOfflineCard()
                          : _ProfileLoadingCard(),
                      error: (Object error, StackTrace stack) => _ProfileErrorCard(
                        error: error,
                        onRetry: () => ref.invalidate(currentProfileProvider),
                      ),
                      data: (profile) {
                        _syncForm(profile);
                        return _ProfileDetailsCard(
                          profile: profile,
                          authEmail: authEmail,
                          editing: _editing,
                          saving: _saving,
                          formError: _formError,
                          formSuccess: _formSuccess,
                          firstNameController: _firstNameController,
                          lastNameController: _lastNameController,
                          contactNumberController: _contactNumberController,
                          streetAddressController: _streetAddressController,
                          municipality: _municipality,
                          barangay: _barangay,
                          zipCode: _zipCode,
                          onMunicipalityChanged: (value) {
                            final selected = bulacanMunicipalities.firstWhere(
                              (item) => item.name == value,
                              orElse: () => const BulacanMunicipality(
                                name: '',
                                zipCode: '',
                                barangays: [],
                              ),
                            );
                            setState(() {
                              _municipality = value;
                              _barangay = '';
                              _zipCode = selected.zipCode;
                            });
                          },
                          onBarangayChanged: (value) {
                            setState(() => _barangay = value);
                          },
                          onEditToggle: () {
                            setState(() {
                              _editing = true;
                              _formError = null;
                              _formSuccess = null;
                            });
                          },
                          onCancel: () => setState(() => _resetForm(profile)),
                          onSave: () => _saveProfile(profile),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SecurityCard(
                      user: authUser,
                      passwordSaving: _passwordSaving,
                      passwordError: _passwordError,
                      passwordSuccess: _passwordSuccess,
                      passwordValidationMessage:
                          _passwordValidationMessage(authUser),
                      canSubmit: _canSubmitPassword(authUser),
                      currentPasswordController: _currentPasswordController,
                      newPasswordController: _newPasswordController,
                      confirmPasswordController: _confirmPasswordController,
                      showCurrentPassword: _showCurrentPassword,
                      showNewPassword: _showNewPassword,
                      showConfirmPassword: _showConfirmPassword,
                      onToggleCurrentPassword: () {
                        setState(() => _showCurrentPassword = !_showCurrentPassword);
                      },
                      onToggleNewPassword: () {
                        setState(() => _showNewPassword = !_showNewPassword);
                      },
                      onToggleConfirmPassword: () {
                        setState(() => _showConfirmPassword = !_showConfirmPassword);
                      },
                      onSubmit: () => _updatePassword(authUser),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.email,
    required this.profileAsync,
    required this.signingOut,
    required this.onSignOut,
  });

  final String? email;
  final AsyncValue<ProfileModel?> profileAsync;
  final bool signingOut;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final profile = profileAsync.asData?.value;
    final displayName = profile?.hasFullName == true
        ? profile!.fullName!
        : 'Your Account';
    final subtitle = profile?.hasRole == true
        ? profile!.role!
        : 'Profile overview';
    final detail = profile?.hasEmail == true ? profile!.email! : (email ?? '-');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFBEB), Colors.white],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF8D58D)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 26,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.goldBright, AppColors.goldDark],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33F59E0B),
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFF8D58D)),
                ),
                child: IconButton(
                  tooltip: 'Sign out',
                  onPressed: onSignOut,
                  icon: signingOut
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.text,
                          ),
                        )
                      : const Icon(
                          Icons.logout_rounded,
                          color: AppColors.text,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'PROFILE',
            style: AppTextStyles.sectionTitle.copyWith(
              fontSize: 26,
              letterSpacing: 1.1,
              height: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            displayName,
            style: AppTextStyles.body.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$subtitle - $detail',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileDetailsCard extends StatelessWidget {
  const _ProfileDetailsCard({
    required this.profile,
    required this.authEmail,
    required this.editing,
    required this.saving,
    required this.formError,
    required this.formSuccess,
    required this.firstNameController,
    required this.lastNameController,
    required this.contactNumberController,
    required this.streetAddressController,
    required this.municipality,
    required this.barangay,
    required this.zipCode,
    required this.onMunicipalityChanged,
    required this.onBarangayChanged,
    required this.onEditToggle,
    required this.onCancel,
    required this.onSave,
  });

  final ProfileModel? profile;
  final String? authEmail;
  final bool editing;
  final bool saving;
  final String? formError;
  final String? formSuccess;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController contactNumberController;
  final TextEditingController streetAddressController;
  final String municipality;
  final String barangay;
  final String zipCode;
  final ValueChanged<String> onMunicipalityChanged;
  final ValueChanged<String> onBarangayChanged;
  final VoidCallback onEditToggle;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final email = profile?.hasEmail == true ? profile!.email! : (authEmail ?? '-');
    final role = profile?.hasRole == true ? profile!.role! : '-';
    BulacanMunicipality? selectedMunicipality;
    for (final item in bulacanMunicipalities) {
      if (item.name == municipality) {
        selectedMunicipality = item;
        break;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.badge_outlined,
                  color: AppColors.goldDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Information',
                      style: AppTextStyles.body.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your profile details and account identity.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (!editing)
                TextButton(
                  onPressed: onEditToggle,
                  child: const Text('Edit'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (formError != null) ...[
            Text(
              formError!,
              style: AppTextStyles.caption.copyWith(color: Colors.red.shade700),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (formSuccess != null) ...[
            Text(
              formSuccess!,
              style: AppTextStyles.caption.copyWith(color: Colors.green.shade700),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          _FieldGroup(
            label: 'Email',
            child: _ReadOnlyField(value: email),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _FieldGroup(
                  label: 'First Name',
                  child: _EditableField(
                    controller: firstNameController,
                    enabled: editing,
                    hintText: 'First name',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _FieldGroup(
                  label: 'Last Name',
                  child: _EditableField(
                    controller: lastNameController,
                    enabled: editing,
                    hintText: 'Last name',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _FieldGroup(
            label: 'Phone Number',
            child: _EditableField(
              controller: contactNumberController,
              enabled: editing,
              hintText: '09XXXXXXXXX',
              keyboardType: TextInputType.phone,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _FieldGroup(
            label: 'Street Address',
            child: _EditableField(
              controller: streetAddressController,
              enabled: editing,
              hintText: 'Street / House Number',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _FieldGroup(
            label: 'Municipality',
            child: editing
                ? _SelectField(
                    value: municipality.isEmpty ? null : municipality,
                    hint: 'Select municipality',
                    items: [
                      for (final item in bulacanMunicipalities)
                        DropdownMenuItem(
                          value: item.name,
                          child: Text(item.name),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) onMunicipalityChanged(value);
                    },
                  )
                : _ReadOnlyField(value: municipality.isEmpty ? '-' : municipality),
          ),
          const SizedBox(height: AppSpacing.sm),
          _FieldGroup(
            label: 'Barangay',
            child: editing
                ? _SelectField(
                    value: barangay.isEmpty ? null : barangay,
                    hint: selectedMunicipality == null
                        ? 'Select municipality first'
                        : 'Select barangay',
                    items: [
                      for (final item in selectedMunicipality?.barangays ?? const <String>[])
                        DropdownMenuItem(
                          value: item,
                          child: Text(item),
                        ),
                    ],
                    onChanged: selectedMunicipality == null
                        ? null
                        : (value) {
                            if (value != null) onBarangayChanged(value);
                          },
                  )
                : _ReadOnlyField(value: barangay.isEmpty ? '-' : barangay),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Expanded(
                child: _FieldGroup(
                  label: 'Province',
                  child: _ReadOnlyField(value: 'Bulacan'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _FieldGroup(
                  label: 'ZIP Code',
                  child: _ReadOnlyField(value: zipCode.isEmpty ? '-' : zipCode),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _FieldGroup(
            label: 'Role',
            child: _ReadOnlyField(value: role),
          ),
          if (editing) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: saving ? null : onCancel,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: PrimaryButton(
                    text: saving ? 'Saving...' : 'Save',
                    isLoading: saving,
                    onPressed: saving ? null : onSave,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileLoadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Loading profile...',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Fetching your latest account information.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _ProfileErrorCard extends StatelessWidget {
  const _ProfileErrorCard({
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Could not load profile',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            error.toString(),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileOfflineCard extends StatelessWidget {
  const _ProfileOfflineCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  color: AppColors.goldDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Offline mode',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Reconnect to load profile details.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.muted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityCard extends StatelessWidget {
  const _SecurityCard({
    required this.user,
    required this.passwordSaving,
    required this.passwordError,
    required this.passwordSuccess,
    required this.passwordValidationMessage,
    required this.canSubmit,
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.showCurrentPassword,
    required this.showNewPassword,
    required this.showConfirmPassword,
    required this.onToggleCurrentPassword,
    required this.onToggleNewPassword,
    required this.onToggleConfirmPassword,
    required this.onSubmit,
  });

  final User? user;
  final bool passwordSaving;
  final String? passwordError;
  final String? passwordSuccess;
  final String? passwordValidationMessage;
  final bool canSubmit;
  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final bool showCurrentPassword;
  final bool showNewPassword;
  final bool showConfirmPassword;
  final VoidCallback onToggleCurrentPassword;
  final VoidCallback onToggleNewPassword;
  final VoidCallback onToggleConfirmPassword;
  final VoidCallback onSubmit;

  String get _mode {
    if (user == null) return 'none';
    final identities = user!.identities;
    if (identities == null || identities.isEmpty) return 'unknown';
    for (final identity in identities) {
      if (identity.provider == 'email') return 'email';
    }
    return 'social';
  }

  @override
  Widget build(BuildContext context) {
    final mode = _mode;
    final email = user?.email ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.goldDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Security',
                      style: AppTextStyles.body.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mode == 'social'
                          ? 'Add a password alongside your social login.'
                          : 'Manage the password for your account.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (mode == 'unknown') ...[
            Text(
              'Loading your sign-in options...',
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
            ),
          ] else if (mode == 'none') ...[
            Text(
              'Sign in to manage password settings.',
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
            ),
          ] else ...[
            if (passwordError != null) ...[
              Text(
                passwordError!,
                style: AppTextStyles.caption.copyWith(color: Colors.red.shade700),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (passwordSuccess != null) ...[
              Text(
                passwordSuccess!,
                style: AppTextStyles.caption.copyWith(color: Colors.green.shade700),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (passwordError == null &&
                passwordSuccess == null &&
                passwordValidationMessage != null) ...[
              Text(
                passwordValidationMessage!,
                style: AppTextStyles.caption.copyWith(color: Colors.red.shade700),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (mode == 'social') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Text(
                  'Signed in with Google? Add a password for $email so you can also use email sign-in.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (mode == 'email') ...[
              _FieldGroup(
                label: 'Current Password',
                child: _PasswordField(
                  controller: currentPasswordController,
                  hintText: 'Enter current password',
                  obscureText: !showCurrentPassword,
                  onToggleVisibility: onToggleCurrentPassword,
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Row(
              children: [
                Expanded(
                  child: _FieldGroup(
                    label: mode == 'social' ? 'Password' : 'New Password',
                    child: _PasswordField(
                      controller: newPasswordController,
                      hintText: 'At least 8 characters',
                      obscureText: !showNewPassword,
                      onToggleVisibility: onToggleNewPassword,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _FieldGroup(
                    label: 'Confirm Password',
                    child: _PasswordField(
                      controller: confirmPasswordController,
                      hintText: 'Re-enter password',
                      obscureText: !showConfirmPassword,
                      onToggleVisibility: onToggleConfirmPassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        if (canSubmit) onSubmit();
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 190,
                child: PrimaryButton(
                  text: passwordSaving
                      ? 'Saving...'
                      : (mode == 'social' ? 'Add Password' : 'Update Password'),
                  isLoading: passwordSaving,
                  onPressed: canSubmit ? onSubmit : null,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FieldGroup extends StatelessWidget {
  const _FieldGroup({
    required this.label,
    required this.child,
  });
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.value,
  });

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EEF5)),
      ),
      child: Text(
        value,
        style: AppTextStyles.body.copyWith(
          color: AppColors.text,
          fontWeight: FontWeight.w600,
          fontSize: 14,
          height: 1.35,
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.hintText,
    required this.obscureText,
    required this.onToggleVisibility,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final VoidCallback onToggleVisibility;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFE8EEF5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFE8EEF5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.gold),
        ),
        suffixIcon: IconButton(
          onPressed: onToggleVisibility,
          icon: Icon(
            obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: AppColors.muted,
            size: 20,
          ),
        ),
      ),
      style: AppTextStyles.body.copyWith(
        color: AppColors.text,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _EditableField extends StatelessWidget {
  const _EditableField({
    required this.controller,
    required this.enabled,
    required this.hintText,
    this.keyboardType,
  });

  final TextEditingController controller;
  final bool enabled;
  final String hintText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: enabled ? Colors.white : const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFE8EEF5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFE8EEF5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.gold),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFE8EEF5)),
        ),
      ),
      style: AppTextStyles.body.copyWith(
        color: AppColors.text,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SelectField extends StatelessWidget {
  const _SelectField({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  final String? value;
  final String hint;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final validValue = items.any((item) => item.value == value) ? value : null;

    return DropdownButtonFormField<String>(
      initialValue: validValue,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: onChanged == null ? const Color(0xFFF8FAFC) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFE8EEF5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFE8EEF5)),
        ),
      ),
    );
  }
}
