import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/network/supabase_service.dart';
import 'core/network/providers.dart';
import 'features/auth/auth_gate.dart';
import 'features/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Core Supabase & Demo Database
  final supabaseService = SupabaseService();
  await supabaseService.init();

  runApp(
    const ProviderScope(
      child: LendoraZApp(),
    ),
  );
}

class LendoraZApp extends ConsumerWidget {
  const LendoraZApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to changes in service state (e.g. settings)
    ref.watch(supabaseServiceProvider);

    return MaterialApp(
      title: 'LendoraZ Premium Fintech',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: service.themeMode,
      home: const AuthGate(),
      routes: {
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
