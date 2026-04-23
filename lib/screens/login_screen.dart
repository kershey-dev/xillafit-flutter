import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xillafit_flutter/app_colors.dart';
import 'package:xillafit_flutter/app_spacing.dart';
import 'package:xillafit_flutter/app_text_styles.dart';
import 'package:xillafit_flutter/features/auth/data/bulacan_locations.dart';
import 'package:xillafit_flutter/features/auth/presentation/auth_providers.dart';
import 'package:xillafit_flutter/screens/onboarding_screen.dart';

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
  StreamSubscription<AuthState>? _authSubscription;
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
  bool _navigatedAfterAuth = false;
  String? _selectedMunicipalityName;
  String? _selectedBarangay;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      if (data.event != AuthChangeEvent.signedIn || !mounted || _navigatedAfterAuth) {
        return;
      }
      _navigatedAfterAuth = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
      });
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
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
    if (_tab != AuthTab.register) return null;
    if (v.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(v)) {
      return 'Password must include at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(v)) {
      return 'Password must include at least one lowercase letter';
    }
    if (!RegExp(r'\d').hasMatch(v)) {
      return 'Password must include at least one number';
    }
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

  bool _hasStepOneValidationIssues({
    required String? emailErr,
    required String? passErr,
    required String? confirmPasswordErr,
  }) {
    return emailErr != null || passErr != null || confirmPasswordErr != null;
  }

  void _moveToRegisterStepOneForErrors() {
    if (_tab != AuthTab.register) return;
    if (_registerStep != 1) {
      _registerStep = 1;
    }
  }

  String _friendlyRegisterErrorMessage(AuthException error) {
    final message = error.message.trim();
    final lower = message.toLowerCase();

    if (lower.contains('already registered') ||
        lower.contains('already been registered') ||
        lower.contains('user already registered') ||
        lower.contains('already exists')) {
      return 'That email is already registered. Please sign in instead.';
    }

    if (lower.contains('password')) {
      return 'Your password does not meet the required format.';
    }

    return message;
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
        if (_hasStepOneValidationIssues(
          emailErr: emailErr,
          passErr: passErr,
          confirmPasswordErr: confirmPasswordErr,
        )) {
          _moveToRegisterStepOneForErrors();
        }
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
        if (!mounted) return;
        _navigatedAfterAuth = true;
        Navigator.of(context).popUntil((route) => route.isFirst);
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
        final friendlyMessage = _friendlyRegisterErrorMessage(e);
        final lower = friendlyMessage.toLowerCase();
        setState(() {
          if (_tab == AuthTab.register &&
              (lower.contains('email') || lower.contains('password'))) {
            _moveToRegisterStepOneForErrors();
          }
          if (lower.contains('already registered')) {
            _emailError = 'That email is already registered';
          } else if (lower.contains('password')) {
            _passwordError = friendlyMessage;
          }
          _formError = friendlyMessage;
        });
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

  Future<void> _submitGoogleSignIn() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _clearFieldErrors();
      _loading = true;
    });

    try {
      final launched = await ref.read(authRepositoryProvider).signInWithGoogle();
      if (!mounted) return;
      if (!launched) {
        setState(() {
          _formError = 'Could not open Google sign-in. Please try again.';
        });
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _formError = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _formError = e.toString());
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
    final passErr = _validatePassword(_passwordController.text);
    final confirmPasswordErr =
        _validateConfirmPassword(_confirmPasswordController.text);
    if (emailErr != null || passErr != null || confirmPasswordErr != null) {
      setState(() {
        _emailError = emailErr;
        _passwordError = passErr;
        _confirmPasswordError = confirmPasswordErr;
      });
      return;
    }
    setState(() => _registerStep = 2);
  }

  void _goToRegisterStepOne() {
    FocusScope.of(context).unfocus();
    setState(() => _registerStep = 1);
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacementNamed(OnboardingScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final isRegister = _tab == AuthTab.register;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;

    if (!isRegister) {
      return Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: const Color(0xFFFAFAFA),
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(22, 10, 22, 24 + safeBottom + keyboardInset),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.sizeOf(context).height - safeBottom - 34,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AuthBackButton(onPressed: _goBack),
                  const SizedBox(height: 26),
                  Text(
                    'Welcome back',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 33,
                      fontWeight: FontWeight.w900,
                      color: AppColors.goldDark,
                      height: 0.98,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Enter your credentials to continue',
                    style: AppTextStyles.body.copyWith(
                      color: const Color(0xFF6B7280),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (_formError != null) ...[
                    _AuthMessage(message: _formError!),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  _buildSignInPane(),
                  const SizedBox(height: 18),
                  _AuthFooter(
                    isRegister: false,
                    enabled: !_loading,
                    onToggle: () => _switchTab(AuthTab.register),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(22, 10, 22, 24 + safeBottom + keyboardInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AuthBackButton(
                onPressed: () {
                  if (_registerStep == 2) {
                    _goToRegisterStepOne();
                    return;
                  }
                  _goBack();
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Create account',
                style: AppTextStyles.body.copyWith(
                  fontSize: 33,
                  fontWeight: FontWeight.w900,
                  color: AppColors.goldDark,
                  height: 0.98,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Set up your XILLAFIT account in two quick steps.',
                style: AppTextStyles.body.copyWith(
                  color: const Color(0xFF6B7280),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              _RegisterProgressPill(step: _registerStep),
              const SizedBox(height: 20),
              if (_formError != null) ...[
                _AuthMessage(message: _formError!),
                const SizedBox(height: AppSpacing.md),
              ],
              _buildRegisterPane(),
              const SizedBox(height: 18),
              _AuthFooter(
                isRegister: true,
                enabled: !_loading,
                onToggle: () => _switchTab(AuthTab.signIn),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignInPane() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SignInField(
          hint: 'Email address',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          errorText: _emailError,
          enabled: !_loading,
          textInputAction: TextInputAction.next,
          prefixIcon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 14),
        _SignInField(
          hint: 'Password',
          obscureText: true,
          controller: _passwordController,
          errorText: _passwordError,
          enabled: !_loading,
          textInputAction: TextInputAction.done,
          prefixIcon: Icons.lock_outline_rounded,
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Forgot password?',
            style: AppTextStyles.body.copyWith(
              color: AppColors.goldDark,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 18),
        _SignInActionButton(
          text: 'Log in',
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.text,
          onPressed: _submit,
          isLoading: _loading,
        ),
        const SizedBox(height: 12),
        _GoogleOnlyButton(
          enabled: !_loading,
          onPressed: _submitGoogleSignIn,
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildRegisterPane() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildForm(true),
        const SizedBox(height: 22),
        _registerActions(),
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
        _SignInField(
          hint: 'Full name',
          controller: _usernameController,
          enabled: !_loading,
          textInputAction: TextInputAction.next,
          prefixIcon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 14),
        _SignInField(
          hint: 'Email address',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          errorText: _emailError,
          enabled: !_loading,
          textInputAction: TextInputAction.next,
          prefixIcon: Icons.alternate_email_rounded,
        ),
        const SizedBox(height: 14),
        _SignInField(
          hint: 'Password',
          obscureText: true,
          controller: _passwordController,
          errorText: _passwordError,
          enabled: !_loading,
          textInputAction: TextInputAction.next,
          prefixIcon: Icons.lock_outline_rounded,
        ),
        const SizedBox(height: 14),
        _SignInField(
          hint: 'Confirm password',
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
        const _RegisterSectionLabel(text: 'Address details'),
        const SizedBox(height: 12),
        _CleanReadOnlyField(
          label: 'Province',
          value: 'Bulacan',
          prefixIcon: Icons.map_outlined,
        ),
        const SizedBox(height: 14),
        _CleanDropdownField(
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
        const SizedBox(height: 14),
        _CleanDropdownField(
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
        const SizedBox(height: 14),
        _SignInField(
          hint: 'Street / House No.',
          controller: _streetAddressController,
          errorText: _streetAddressError,
          enabled: !_loading,
          textInputAction: TextInputAction.next,
          prefixIcon: Icons.home_outlined,
        ),
        const SizedBox(height: 14),
        _CleanReadOnlyField(
          label: 'ZIP Code',
          value: _zipCode,
          prefixIcon: Icons.markunread_mailbox_outlined,
        ),
      ],
    );
  }

  Widget _registerActions() {
    if (_registerStep == 1) {
      return _SignInActionButton(
        text: 'Next',
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.text,
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
            compactStyle: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: _SignInActionButton(
            text: 'Create account',
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.text,
            onPressed: _submit,
            isLoading: _loading,
          ),
        ),
      ],
    );
  }

}

class _AuthBackButton extends StatelessWidget {
  const _AuthBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onPressed,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFEAEAEA)),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: AppColors.text,
            ),
          ),
        ),
      ),
    );
  }
}

class _SignInField extends StatefulWidget {
  const _SignInField({
    required this.hint,
    required this.controller,
    this.errorText,
    this.keyboardType,
    this.enabled = true,
    this.obscureText = false,
    this.textInputAction,
    this.prefixIcon,
  });

  final String hint;
  final TextEditingController controller;
  final String? errorText;
  final TextInputType? keyboardType;
  final bool enabled;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final IconData? prefixIcon;

  @override
  State<_SignInField> createState() => _SignInFieldState();
}

class _SignInFieldState extends State<_SignInField> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
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
        errorMaxLines: 2,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        hintStyle: AppTextStyles.body.copyWith(
          color: const Color(0xFFB7B7B7),
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: widget.prefixIcon == null
            ? null
            : Icon(
                widget.prefixIcon,
                color: const Color(0xFFC8C8C8),
                size: 20,
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
                  size: 18,
                  color: const Color(0xFFC8C8C8),
                ),
              )
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.goldDark),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.goldDark, width: 1.4),
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

class _SignInActionButton extends StatelessWidget {
  const _SignInActionButton({
    required this.text,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
    required this.isLoading,
  });

  final String text;
  final Color backgroundColor;
  final Color foregroundColor;
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
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foregroundColor,
                ),
              )
            : Text(
                text,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w800,
                  color: foregroundColor,
                ),
              ),
      ),
    );
  }
}

class _GoogleOnlyButton extends StatelessWidget {
  const _GoogleOnlyButton({
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
          minimumSize: const Size.fromHeight(54),
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFE5E7EB)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _GoogleMark(size: 20),
            const SizedBox(width: 10),
            Text(
              'Log in using Google',
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

class _GoogleMark extends StatelessWidget {
  const _GoogleMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _GoogleMarkPainter(),
    );
  }
}

class _GoogleMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);

    final blue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final green = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;
    final yellow = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill;
    final red = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;

    final pathBlue = Path()
      ..moveTo(22.56, 12.25)
      ..cubicTo(22.56, 11.47, 22.49, 10.72, 22.36, 10.0)
      ..lineTo(12.0, 10.0)
      ..lineTo(12.0, 14.26)
      ..lineTo(17.92, 14.26)
      ..cubicTo(17.66, 15.63, 16.88, 16.79, 15.71, 17.57)
      ..lineTo(15.71, 20.34)
      ..lineTo(19.28, 20.34)
      ..cubicTo(21.36, 18.42, 22.56, 15.6, 22.56, 12.25)
      ..close();

    final pathGreen = Path()
      ..moveTo(12.0, 23.0)
      ..cubicTo(14.97, 23.0, 17.46, 22.02, 19.28, 20.34)
      ..lineTo(15.71, 17.57)
      ..cubicTo(14.73, 18.23, 13.48, 18.63, 12.0, 18.63)
      ..cubicTo(9.14, 18.63, 6.71, 16.7, 5.84, 14.1)
      ..lineTo(2.18, 16.94)
      ..cubicTo(3.99, 20.53, 7.7, 23.0, 12.0, 23.0)
      ..close();

    final pathYellow = Path()
      ..moveTo(5.84, 14.09)
      ..cubicTo(5.62, 13.43, 5.49, 12.73, 5.49, 12.0)
      ..cubicTo(5.49, 11.27, 5.62, 10.57, 5.84, 9.91)
      ..lineTo(5.84, 7.07)
      ..lineTo(2.18, 7.07)
      ..cubicTo(1.43, 8.55, 1.0, 10.22, 1.0, 12.0)
      ..cubicTo(1.0, 13.78, 1.43, 15.45, 2.18, 16.93)
      ..lineTo(5.03, 14.71)
      ..lineTo(5.84, 14.09)
      ..close();

    final pathRed = Path()
      ..moveTo(12.0, 5.38)
      ..cubicTo(13.62, 5.38, 15.06, 5.94, 16.21, 7.02)
      ..lineTo(19.36, 3.87)
      ..cubicTo(17.45, 2.09, 14.97, 1.0, 12.0, 1.0)
      ..cubicTo(7.7, 1.0, 3.99, 3.47, 2.18, 7.07)
      ..lineTo(5.84, 9.91)
      ..cubicTo(6.71, 7.31, 9.14, 5.38, 12.0, 5.38)
      ..close();

    canvas.drawPath(pathBlue, blue);
    canvas.drawPath(pathGreen, green);
    canvas.drawPath(pathYellow, yellow);
    canvas.drawPath(pathRed, red);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RegisterProgressPill extends StatelessWidget {
  const _RegisterProgressPill({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final progress = step / 2;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$step',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  step == 1 ? 'Account details' : 'Delivery details',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                'Step $step of 2',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.goldDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Container(color: const Color(0xFFF1F5F9)),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.gold, AppColors.goldBright],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            step == 1
                ? 'Start with your basic account information.'
                : 'Finish your delivery details to complete setup.',
            style: AppTextStyles.body.copyWith(
              color: const Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterSectionLabel extends StatelessWidget {
  const _RegisterSectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.body.copyWith(
        color: AppColors.text,
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _CleanReadOnlyField extends StatelessWidget {
  const _CleanReadOnlyField({
    required this.label,
    required this.value,
    required this.prefixIcon,
  });

  final String label;
  final String value;
  final IconData prefixIcon;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.body.copyWith(
          color: const Color(0xFF6B7280),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        prefixIcon: Icon(prefixIcon, color: const Color(0xFFC8C8C8), size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
        ),
      ),
      child: Text(
        value.isEmpty ? 'Auto-filled after selection' : value,
        style: AppTextStyles.body.copyWith(
          color: value.isEmpty ? const Color(0xFF9CA3AF) : AppColors.text,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CleanDropdownField extends StatelessWidget {
  const _CleanDropdownField({
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
    final validValue = items.any((item) => item.value == value) ? value : null;

    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        labelStyle: AppTextStyles.body.copyWith(
          color: const Color(0xFF6B7280),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(prefixIcon, color: const Color(0xFFC8C8C8), size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.4),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: validValue,
          isExpanded: true,
          hint: Text(
            hint,
            style: AppTextStyles.body.copyWith(
              color: const Color(0xFFB7B7B7),
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


class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({
    required this.text,
    required this.onPressed,
    this.compactStyle = false,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool compactStyle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: compactStyle ? const Size.fromHeight(54) : null,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          backgroundColor: compactStyle ? Colors.white : const Color(0xFFFFFBF5),
          side: BorderSide(
            color: compactStyle ? const Color(0xFFE5E7EB) : const Color(0xFFE7D8C2),
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(compactStyle ? 999 : 20),
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
          style: AppTextStyles.body.copyWith(
            color: const Color(0xFF6B7280),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        GestureDetector(
          onTap: enabled ? onToggle : null,
          child: Text(
            isRegister ? 'Sign in' : 'Create one now',
            style: AppTextStyles.body.copyWith(
              color: AppColors.goldDark,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
