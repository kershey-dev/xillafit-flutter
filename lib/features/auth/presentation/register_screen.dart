import 'package:flutter/material.dart';
import 'package:xillafit_flutter/screens/login_screen.dart';

/// Separate route for “register” that reuses the existing combined auth UI
/// (Create Account tab). No duplicate layout.
class RegisterScreen extends StatelessWidget {
  static const routeName = '/register';

  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginScreen(initialTab: AuthTab.register);
  }
}
