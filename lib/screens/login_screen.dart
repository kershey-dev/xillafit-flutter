import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xillafit_flutter/app_colors.dart';
import 'package:xillafit_flutter/app_spacing.dart';
import 'package:xillafit_flutter/app_text_styles.dart';
import 'package:xillafit_flutter/features/auth/data/bulacan_locations.dart';
import 'package:xillafit_flutter/features/auth/presentation/auth_providers.dart';

enum AuthTab { signIn, register }

class LoginScreen extends ConsumerStatefulWidget {
  static const routeName = '/login';

  final AuthTab initialTab;

  const LoginScreen({super.key, this.initialTab = AuthTab.signIn});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late AuthTab _tab;
  int _registerStep = 1;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _streetAddressController = TextEditingController();

  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _municipalityError;
  String? _barangayError;
  String? _streetAddressError;
  String? _formError;
  bool _loading = false;
  String? _selectedMunicipalityName;
  String? _selectedBarangay;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _confirmPasswordController.dispose();
    _streetAddressController.dispose();
    super.dispose();
  }

  void _clearFieldErrors() {
    _emailError = null;
    _passwordError = null;
    _confirmPasswordError = null;
    _municipalityError = null;
    _barangayError = null;
    _streetAddressError = null;
    _formError = null;
  }

  BulacanMunicipality? get _selectedMunicipality {
    final name = _selectedMunicipalityName;
    if (name == null || name.isEmpty) return null;
    for (final municipality in bulacanMunicipalities) {
      if (municipality.name == name) return municipality;
    }
    return null;
  }

  String get _zipCode => _selectedMunicipality?.zipCode ?? '';

  String? _validateEmail(String v) {
    final t = v.trim();
    if (t.isEmpty) return 'Email is required';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(t)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String v) {
    if (v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _validateConfirmPassword(String v) {
    if (_tab != AuthTab.register) return null;
    if (v.isEmpty) return 'Please confirm your password';
    if (v != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  String? _validateRequiredSelection(String? value, String label) {
    if (_tab != AuthTab.register) return null;
    if ((value ?? '').trim().isEmpty) return '$label is required';
    return null;
  }

  String? _validateStreetAddress(String v) {
    if (_tab != AuthTab.register) return null;
    if (v.trim().isEmpty) return 'Street / House No. is required';
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    _clearFieldErrors();

    final emailErr = _validateEmail(_emailController.text);
    final passErr = _validatePassword(_passwordController.text);
    final confirmPasswordErr =
        _validateConfirmPassword(_confirmPasswordController.text);
    final municipalityErr = _validateRequiredSelection(
      _selectedMunicipalityName,
      'Municipality / City',
    );
    final barangayErr =
        _validateRequiredSelection(_selectedBarangay, 'Barangay');
    final streetAddressErr =
        _validateStreetAddress(_streetAddressController.text);

    if (emailErr != null ||
        passErr != null ||
        confirmPasswordErr != null ||
        municipalityErr != null ||
        barangayErr != null ||
        streetAddressErr != null) {
      setState(() {
        _emailError = emailErr;
        _passwordError = passErr;
        _confirmPasswordError = confirmPasswordErr;
        _municipalityError = municipalityErr;
        _barangayError = barangayErr;
        _streetAddressError = streetAddressErr;
      });
      return;
    }

    setState(() => _loading = true);
    final repo = ref.read(authRepositoryProvider);
    final email = _emailController.text.trim();

    try {
      if (_tab == AuthTab.signIn) {
        await repo.signInWithEmail(
          email: email,
          password: _passwordController.text,
        );
      } else {
        final res = await repo.signUpWithEmail(
          email: email,
          password: _passwordController.text,
          fullName: _usernameController.text.trim(),
          municipality: _selectedMunicipalityName!,
          barangay: _selectedBarangay!,
          streetAddress: _streetAddressController.text,
          zipCode: _zipCode,
        );
        if (!mounted) return;
        if (res.session == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Account created. If email confirmation is enabled, check your inbox to verify, then sign in.',
              ),
            ),
          );
          setState(() {
            _tab = AuthTab.signIn;
            _registerStep = 1;
          });
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _formError = e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _formError = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _switchTab(AuthTab tab) {
    if (_tab == tab) return;
    setState(() {
      _tab = tab;
      _registerStep = 1;
      _clearFieldErrors();
    });
  }

  void _goToRegisterStepTwo() {
    FocusScope.of(context).unfocus();
    _clearFieldErrors();
    final emailErr = _validateEmail(_emailController.text);
    if (emailErr != null) {
      setState(() {
        _emailError = emailErr;
      });
      return;
    }
    setState(() => _registerStep = 2);
  }

  void _goToRegisterStepOne() {
    FocusScope.of(context).unfocus();
    setState(() => _registerStep = 1);
  }

  @override
  Widget build(BuildContext context) {
    final isRegister = _tab == AuthTab.register;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.surfaceWarm,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final cardPadding = width < 360 ? 18.0 : 22.0;

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.only(bottom: 24 + safeBottom + keyboardInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _brandHeader(isRegister),
                  _authCard(cardPadding, isRegister),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _authCard(double cardPadding, bool isRegister) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        cardPadding,
        20,
        cardPadding,
        28,
      ),
      color: AppColors.surfaceWarm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AuthSegmentedControl(
            currentTab: _tab,
            onChanged: _loading ? null : _switchTab,
          ),
          const SizedBox(height: 24),
          Text(
            isRegister ? 'Create your Account' : 'Login to your Account',
            style: AppTextStyles.body.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isRegister
                ? 'Complete the steps below to create your account.'
                : 'Sign in to continue to your XILLAFIT account.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.muted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (isRegister) ...[
            const SizedBox(height: 16),
            _RegisterStepHeader(step: _registerStep),
          ],
          const SizedBox(height: 20),
          if (_formError != null) ...[
            _AuthMessage(message: _formError!),
            const SizedBox(height: AppSpacing.md),
          ],
          isRegister ? _buildRegisterPane() : _buildSignInPane(),
        ],
      ),
    );
  }

  Widget _buildSignInPane() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildForm(false),
        const SizedBox(height: 28),
        _AuthPrimaryButton(
          text: 'Sign in',
          onPressed: _submit,
          isLoading: _loading,
        ),
        const SizedBox(height: 26),
        _GoogleDivider(),
        const SizedBox(height: 18),
        _GoogleButton(
          enabled: !_loading,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Google sign-in is not configured for mobile yet.',
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        _AuthFooter(
          isRegister: false,
          enabled: !_loading,
          onToggle: () => _switchTab(AuthTab.register),
        ),
      ],
    );
  }

  Widget _buildRegisterPane() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildForm(true),
        const SizedBox(height: 28),
        _registerActions(),
        const SizedBox(height: 18),
        _AuthFooter(
          isRegister: true,
          enabled: !_loading,
          onToggle: () => _switchTab(AuthTab.signIn),
        ),
      ],
    );
  }

  Widget _buildForm(bool isRegister) {
    if (isRegister) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: _registerStep == 1
            ? _registerStepOneForm()
            : _registerStepTwoForm(),
      );
    }

    return Column(
      key: const ValueKey('sign-in-form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AuthTextField(
          label: 'Email Address',
          hint: 'customer@xillafit.ph',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          errorText: _emailError,
          enabled: !_loading,
          textInputAction: TextInputAction.next,
          prefixIcon: Icons.alternate_email_rounded,
        ),
        const SizedBox(height: AppSpacing.md),
        _AuthTextField(
          label: 'Password',
          hint: 'Enter your password',
          obscureText: true,
          controller: _passwordController,
          errorText: _passwordError,
          enabled: !_loading,
          textInputAction: TextInputAction.done,
          prefixIcon: Icons.lock_outline_rounded,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Theme(
              data: Theme.of(context).copyWith(
                checkboxTheme: CheckboxThemeData(
                  fillColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.gold;
                    }
                    return const Color(0xFFFFFCF7);
                  }),
                  side: const BorderSide(color: AppColors.border, width: 1.4),
                ),
              ),
              child: Checkbox(
                value: true,
                onChanged: _loading ? null : (_) {},
                visualDensity: VisualDensity.compact,
              ),
            ),
            Expanded(
              child: Text(
                'Remember me',
                style: AppTextStyles.body.copyWith(
                  fontSize: 13,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              'Forgot password?',
              style: AppTextStyles.body.copyWith(
                fontSize: 12,
                color: AppColors.goldDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _registerStepOneForm() {
    return Column(
      key: const ValueKey('register-step-1'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AuthTextField(
          label: 'Username',
          hint: 'Your name or team name',
          controller: _usernameController,
          enabled: !_loading,
          textInputAction: TextInputAction.next,
          prefixIcon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 16),
        _AuthTextField(
          label: 'Email Address',
          hint: 'customer@xillafit.ph',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          errorText: _emailError,
          enabled: !_loading,
          textInputAction: TextInputAction.next,
          prefixIcon: Icons.alternate_email_rounded,
        ),
        const SizedBox(height: 16),
        _AuthTextField(
          label: 'Password',
          hint: 'Enter your password',
          obscureText: true,
          controller: _passwordController,
          errorText: _passwordError,
          enabled: !_loading,
          textInputAction: TextInputAction.next,
          prefixIcon: Icons.lock_outline_rounded,
        ),
        const SizedBox(height: 16),
        _AuthTextField(
          label: 'Confirm Password',
          hint: 'Re-enter your password',
          obscureText: true,
          controller: _confirmPasswordController,
          errorText: _confirmPasswordError,
          enabled: !_loading,
          textInputAction: TextInputAction.next,
          prefixIcon: Icons.verified_user_outlined,
        ),
      ],
    );
  }

  Widget _registerStepTwoForm() {
    return Column(
      key: const ValueKey('register-step-2'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReadOnlyAuthField(
          label: 'Province',
          value: 'Bulacan',
          prefixIcon: Icons.map_outlined,
        ),
        const SizedBox(height: 16),
        _AuthDropdownField(
          label: 'Municipality / City',
          value: _selectedMunicipalityName,
          hint: 'Select your municipality',
          items: bulacanMunicipalities
              .map(
                (municipality) => DropdownMenuItem<String>(
                  value: municipality.name,
                  child: Text(municipality.name),
                ),
              )
              .toList(),
          errorText: _municipalityError,
          enabled: !_loading,
          prefixIcon: Icons.location_city_outlined,
          onChanged: (value) {
            setState(() {
              _selectedMunicipalityName = value;
              _selectedBarangay = null;
              _municipalityError = null;
              _barangayError = null;
            });
          },
        ),
        const SizedBox(height: 16),
        _AuthDropdownField(
          label: 'Barangay',
          value: _selectedBarangay,
          hint: 'Select your barangay',
          items: (_selectedMunicipality?.barangays ?? const <String>[])
              .map(
                (barangay) => DropdownMenuItem<String>(
                  value: barangay,
                  child: Text(barangay),
                ),
              )
              .toList(),
          errorText: _barangayError,
          enabled: !_loading && _selectedMunicipality != null,
          prefixIcon: Icons.place_outlined,
          onChanged: (value) {
            setState(() {
              _selectedBarangay = value;
              _barangayError = null;
            });
          },
        ),
        const SizedBox(height: 16),
        _AuthTextField(
          label: 'Street / House No.',
          hint: 'e.g. 123 Rizal Street',
          controller: _streetAddressController,
          errorText: _streetAddressError,
          enabled: !_loading,
          textInputAction: TextInputAction.next,
          prefixIcon: Icons.home_outlined,
        ),
        const SizedBox(height: 16),
        _ReadOnlyAuthField(
          label: 'ZIP Code',
          value: _zipCode,
          prefixIcon: Icons.markunread_mailbox_outlined,
        ),
      ],
    );
  }

  Widget _registerActions() {
    if (_registerStep == 1) {
      return _AuthPrimaryButton(
        text: 'Next',
        onPressed: _goToRegisterStepTwo,
        isLoading: _loading,
      );
    }

    return Row(
      children: [
        Expanded(
          child: _SecondaryActionButton(
            text: 'Back',
            onPressed: _loading ? null : _goToRegisterStepOne,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: _AuthPrimaryButton(
            text: 'Create account',
            onPressed: _submit,
            isLoading: _loading,
          ),
        ),
      ],
    );
  }

  Widget _brandHeader(bool isRegister) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF091726), Color(0xFF10253C)],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.14),
              ),
            ),
            child: Text(
              'XILLAFIT',
              style: AppTextStyles.label.copyWith(
                color: AppColors.goldLight,
                letterSpacing: 2.6,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isRegister ? 'Create your premium account' : 'Welcome back',
            textAlign: TextAlign.center,
            style: AppTextStyles.title.copyWith(
              color: Colors.white,
              fontSize: 28,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isRegister
                ? 'A simpler 2-step signup flow with all of your existing details preserved.'
                : 'Sign in quickly and continue managing orders, previews, and your account.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: Colors.white.withValues(alpha: 0.84),
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthSegmentedControl extends StatelessWidget {
  const _AuthSegmentedControl({
    required this.currentTab,
    required this.onChanged,
  });

  final AuthTab currentTab;
  final ValueChanged<AuthTab>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1D7A8)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: 'Sign In',
              selected: currentTab == AuthTab.signIn,
              onTap: onChanged == null ? null : () => onChanged!(AuthTab.signIn),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: 'Create Account',
              selected: currentTab == AuthTab.register,
              onTap: onChanged == null ? null : () => onChanged!(AuthTab.register),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        boxShadow: selected
            ? const [
                BoxShadow(
                  color: Color(0x120F172A),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.text : const Color(0xFF7F8897),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthTextField extends StatefulWidget {
  const _AuthTextField({
    required this.label,
    required this.hint,
    required this.controller,
    this.errorText,
    this.keyboardType,
    this.enabled = true,
    this.obscureText = false,
    this.textInputAction,
    this.prefixIcon,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final String? errorText;
  final TextInputType? keyboardType;
  final bool enabled;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final IconData? prefixIcon;

  @override
  State<_AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<_AuthTextField> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final borderColor =
        widget.errorText != null ? AppColors.goldDark : const Color(0xFFE7D8C2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label.toUpperCase(),
          style: AppTextStyles.label.copyWith(
            color: const Color(0xFF7C6B56),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controller,
          obscureText: _obscured,
          enabled: widget.enabled,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          style: AppTextStyles.body.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: widget.errorText,
            errorMaxLines: 3,
            filled: true,
            fillColor: widget.enabled
                ? const Color(0xFFFFFBF5)
                : const Color(0xFFF6EFE2),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            hintStyle: AppTextStyles.body.copyWith(
              color: const Color(0xFFB6A995),
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: widget.prefixIcon == null
                ? null
                : Padding(
                    padding: const EdgeInsetsDirectional.only(start: 2),
                    child: Icon(
                      widget.prefixIcon,
                      color: AppColors.goldDark,
                      size: 20,
                    ),
                  ),
            suffixIcon: widget.obscureText
                ? IconButton(
                    onPressed: widget.enabled
                        ? () => setState(() => _obscured = !_obscured)
                        : null,
                    icon: Icon(
                      _obscured
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: const Color(0xFF7C8798),
                    ),
                  )
                : null,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: borderColor, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppColors.gold, width: 1.4),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: borderColor, width: 1.2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: AppColors.goldDark,
                width: 1.2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: AppColors.goldDark,
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyAuthField extends StatelessWidget {
  const _ReadOnlyAuthField({
    required this.label,
    required this.value,
    required this.prefixIcon,
  });

  final String label;
  final String value;
  final IconData prefixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.label.copyWith(
            color: const Color(0xFF7C6B56),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        InputDecorator(
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF9F2E6),
            prefixIcon: Icon(prefixIcon, color: AppColors.goldDark, size: 20),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: Color(0xFFE8DCC7),
                width: 1.2,
              ),
            ),
          ),
          child: Text(
            value.isEmpty ? 'Auto-filled after selection' : value,
            style: AppTextStyles.body.copyWith(
              color: value.isEmpty ? const Color(0xFFB6A995) : AppColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthDropdownField extends StatelessWidget {
  const _AuthDropdownField({
    required this.label,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    required this.enabled,
    required this.prefixIcon,
    this.errorText,
  });

  final String label;
  final String? value;
  final String hint;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;
  final bool enabled;
  final IconData prefixIcon;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        errorText != null ? AppColors.goldDark : const Color(0xFFE7D8C2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.label.copyWith(
            color: const Color(0xFF7C6B56),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        InputDecorator(
          decoration: InputDecoration(
            errorText: errorText,
            errorMaxLines: 3,
            filled: true,
            fillColor: enabled
                ? const Color(0xFFFFFBF5)
                : const Color(0xFFF6EFE2),
            prefixIcon: Icon(prefixIcon, color: AppColors.goldDark, size: 20),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: borderColor, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppColors.gold, width: 1.4),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: borderColor, width: 1.2),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text(
                hint,
                style: AppTextStyles.body.copyWith(
                  color: const Color(0xFFB6A995),
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: AppTextStyles.body.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w600,
              ),
              items: items,
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthMessage extends StatelessWidget {
  const _AuthMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF5D1A7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: AppColors.goldDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.goldDark,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterStepHeader extends StatelessWidget {
  const _RegisterStepHeader({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step $step of 2',
          style: AppTextStyles.label.copyWith(
            color: AppColors.goldDark,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 6,
                  color: step >= 1
                      ? AppColors.gold
                      : const Color(0xFFE7D8C2),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 6,
                  color: step >= 2
                      ? AppColors.gold
                      : const Color(0xFFE7D8C2),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AuthPrimaryButton extends StatelessWidget {
  const _AuthPrimaryButton({
    required this.text,
    required this.onPressed,
    required this.isLoading,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22F59E0B),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.text,
                    ),
                  )
                : Text(
                    text,
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({
    required this.text,
    required this.onPressed,
  });

  final String text;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          backgroundColor: const Color(0xFFFFFBF5),
          side: const BorderSide(color: Color(0xFFE7D8C2), width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          text,
          style: AppTextStyles.body.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _GoogleDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: Color(0xFFE8DCC7), thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR CONTINUE WITH',
            style: AppTextStyles.label.copyWith(
              color: const Color(0xFF8F7D68),
              letterSpacing: 1.2,
            ),
          ),
        ),
        const Expanded(
          child: Divider(color: Color(0xFFE8DCC7), thickness: 1),
        ),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          backgroundColor: const Color(0xFFFFFBF5),
          side: const BorderSide(color: Color(0xFFE7D8C2), width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              alignment: Alignment.center,
              child: Text(
                'G',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Google',
              style: AppTextStyles.body.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthFooter extends StatelessWidget {
  const _AuthFooter({
    required this.isRegister,
    required this.enabled,
    required this.onToggle,
  });

  final bool isRegister;
  final bool enabled;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          isRegister
              ? 'Already have an account? '
              : "Don't have an account? ",
          style: AppTextStyles.caption.copyWith(
            color: AppColors.muted,
            fontWeight: FontWeight.w500,
          ),
        ),
        GestureDetector(
          onTap: enabled ? onToggle : null,
          child: Text(
            isRegister ? 'Sign in' : 'Create one now',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.goldDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: Colors.white.withValues(alpha: 0.82),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
