import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xillafit_flutter/app_colors.dart';
import 'package:xillafit_flutter/app_text_styles.dart';
import 'package:xillafit_flutter/features/auth/presentation/auth_providers.dart';
import 'package:xillafit_flutter/widgets/common/input_field.dart';
import 'package:xillafit_flutter/widgets/common/primary_button.dart';

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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _emailError;
  String? _passwordError;
  String? _formError;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearFieldErrors() {
    _emailError = null;
    _passwordError = null;
    _formError = null;
  }

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

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    _clearFieldErrors();
    final emailErr = _validateEmail(_emailController.text);
    final passErr = _validatePassword(_passwordController.text);
    if (emailErr != null || passErr != null) {
      setState(() {
        _emailError = emailErr;
        _passwordError = passErr;
      });
      return;
    }

    setState(() => _loading = true);
    final repo = ref.read(authRepositoryProvider);

    try {
      if (_tab == AuthTab.signIn) {
        await repo.signInWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        final res = await repo.signUpWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
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
          setState(() => _tab = AuthTab.signIn);
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
      _clearFieldErrors();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isRegister = _tab == AuthTab.register;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: AppColors.surfaceWarm,
                child: Stack(
                  children: [
                    Positioned(
                      left: -160,
                      top: -220,
                      child: Container(
                        width: 360,
                        height: 360,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [AppColors.gold.withValues(alpha: 0.07), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -180,
                      bottom: -260,
                      child: Container(
                        width: 420,
                        height: 420,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [AppColors.black.withValues(alpha: 0.04), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SingleChildScrollView(
              child: Column(
                children: [
                  _hero(),
                  _tabBar(),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_formError != null) ...[
                          Text(
                            _formError!,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.goldDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        InputField(
                          label: 'Email Address',
                          hint: 'customer@xillafit.ph',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          errorText: _emailError,
                          enabled: !_loading,
                        ),
                        const SizedBox(height: 14),
                        InputField(
                          label: 'Password',
                          hint: 'Enter your password',
                          obscureText: true,
                          controller: _passwordController,
                          errorText: _passwordError,
                          enabled: !_loading,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Checkbox(
                              value: true,
                              onChanged: _loading ? null : (_) {},
                              visualDensity: VisualDensity.compact,
                            ),
                            Text('Remember me', style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.muted)),
                            const Spacer(),
                            Text(
                              'Forgot password?',
                              style: AppTextStyles.body.copyWith(
                                fontSize: 12,
                                color: AppColors.goldDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        PrimaryButton(
                          text: isRegister ? 'Create account' : 'Sign in to XILLAFIT',
                          onPressed: _submit,
                          isLoading: _loading,
                        ),
                        const SizedBox(height: 14),
                        Text('— OR CONTINUE WITH —', style: AppTextStyles.caption.copyWith(fontSize: 12)),
                        const SizedBox(height: 14),
                        OutlineButtonX(
                          text: 'Google',
                          onPressed: _loading
                              ? null
                              : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Google sign-in is not configured for mobile yet.')),
                                  );
                                },
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              isRegister ? 'Already have an account? ' : "Don't have an account? ",
                              style: AppTextStyles.caption.copyWith(fontSize: 12),
                            ),
                            GestureDetector(
                              onTap: _loading ? null : () => _switchTab(isRegister ? AuthTab.signIn : AuthTab.register),
                              child: Text(
                                isRegister ? 'Sign in' : 'Register here',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.goldDark,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
      decoration: BoxDecoration(
        color: AppColors.black,
        border: const Border(bottom: BorderSide(color: AppColors.gold, width: 1.2)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x1AC9902A), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x0DC9902A), Colors.transparent],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'XILLAFIT',
                style: AppTextStyles.label.copyWith(color: AppColors.goldDark, letterSpacing: 3),
              ),
              const SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  style: AppTextStyles.title.copyWith(
                    color: Colors.white,
                    fontSize: 42,
                    height: 0.95,
                    letterSpacing: 1.0,
                  ),
                  children: const [
                    TextSpan(text: 'DESIGN\nCUSTOM\n'),
                    TextSpan(text: 'APPAREL', style: TextStyle(color: AppColors.goldBright)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Preview jerseys & hoodies before you order.',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 12,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text('✦  Live 3D Preview', style: AppTextStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.45), fontSize: 11)),
                  const SizedBox(width: 16),
                  Text('✦  No Min. Order', style: AppTextStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.45), fontSize: 11)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _loading ? null : () => _switchTab(AuthTab.signIn),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _tab == AuthTab.signIn ? AppColors.gold : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  'Sign In',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _tab == AuthTab.signIn ? AppColors.goldDark : AppColors.muted,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _loading ? null : () => _switchTab(AuthTab.register),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _tab == AuthTab.register ? AppColors.gold : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  'Create Account',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _tab == AuthTab.register ? AppColors.goldDark : AppColors.muted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
