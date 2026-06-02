import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/network/providers.dart';
import '../dashboard/dashboard_screen.dart';
import 'login_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(supabaseServiceProvider);

    if (service.isDemoMode) {
      return service.isDemoLoggedIn ? const DashboardScreen() : const LoginScreen();
    }

    // For real Supabase mode
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (service.currentUserEmail.isEmpty) {
          service.updateUserFromSession(session.user);
        }
      });
      return const DashboardScreen();
    }

    return const LoginScreen();
  }
}
