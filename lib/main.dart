import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xillafit_flutter/app_theme.dart';
import 'package:xillafit_flutter/core/config/supabase_env.dart';
import 'package:xillafit_flutter/features/auth/presentation/auth_gate.dart';
import 'package:xillafit_flutter/features/auth/presentation/register_screen.dart';
import 'package:xillafit_flutter/screens/catalog_screen.dart';
import 'package:xillafit_flutter/screens/login_screen.dart';
import 'package:xillafit_flutter/screens/main_shell.dart';
import 'package:xillafit_flutter/screens/messages_screen.dart';
import 'package:xillafit_flutter/screens/notifications_screen.dart';
import 'package:xillafit_flutter/screens/order_history_screen.dart';
import 'package:xillafit_flutter/screens/order_tracking_screen.dart';
import 'package:xillafit_flutter/screens/payment_submission_screen.dart';
import 'package:xillafit_flutter/screens/product_detail_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!SupabaseEnv.isConfigured) {
    throw StateError(
      'Supabase is not configured. Set SUPABASE_URL and SUPABASE_ANON_KEY '
      'via --dart-define or update lib/core/config/supabase_env.dart.',
    );
  }

  await Supabase.initialize(
    url: SupabaseEnv.url,
    anonKey: SupabaseEnv.anonKey,
  );

  runApp(
    const ProviderScope(
      child: XillaApp(),
    ),
  );
}

class XillaApp extends StatelessWidget {
  const XillaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Xilla',
      theme: AppTheme.light(),
      home: const AuthGate(),
      routes: {
        LoginScreen.routeName: (_) => const LoginScreen(),
        RegisterScreen.routeName: (_) => const RegisterScreen(),
        MainShell.routeName: (_) => const MainShell(),
        CatalogScreen.routeName: (_) => const CatalogScreen(),
        ProductDetailScreen.routeName: (_) => const ProductDetailScreen(),
        OrderTrackingScreen.routeName: (_) => const OrderTrackingScreen(),
        OrderHistoryScreen.routeName: (_) => const OrderHistoryScreen(),
        PaymentSubmissionScreen.routeName: (_) => const PaymentSubmissionScreen(),
        NotificationsScreen.routeName: (_) => const NotificationsScreen(),
        MessagesScreen.routeName: (_) => const MessagesScreen(),
      },
    );
  }
}
