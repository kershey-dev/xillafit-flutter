import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xillafit_flutter/app_colors.dart';
import 'package:xillafit_flutter/features/auth/presentation/auth_providers.dart';
import 'package:xillafit_flutter/screens/main_shell.dart';
import 'package:xillafit_flutter/screens/onboarding_screen.dart';

/// Root gate: session → main shell, no session → login.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authRepository = ref.watch(authRepositoryProvider);
    final rememberedSession = authRepository.hasRememberedSession;
    final sessionAsync = ref.watch(authSessionProvider);
    return sessionAsync.when(
      skipLoadingOnReload: true,
      data: (session) {
        if (session != null || rememberedSession) {
          return const MainShell();
        }
        return const OnboardingScreen();
      },
      loading: () => rememberedSession
          ? const MainShell()
          : const _AuthBootstrapSplash(),
      error: (Object error, StackTrace stack) => rememberedSession
          ? const MainShell()
          : const OnboardingScreen(),
    );
  }
}

class _AuthBootstrapSplash extends StatelessWidget {
  const _AuthBootstrapSplash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2),
      ),
    );
  }
}
