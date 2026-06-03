import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'supabase_service.dart';

// Service Provider
final supabaseServiceProvider = ChangeNotifierProvider<SupabaseService>((ref) {
  return SupabaseService();
});

class SupabaseRefresh extends Notifier<int> {
  @override
  int build() {
    final service = ref.read(supabaseServiceProvider);
    void listener() {
      state = state + 1;
    }
    service.addListener(listener);
    ref.onDispose(() => service.removeListener(listener));
    return 0;
  }
}

final supabaseRefreshProvider = NotifierProvider<SupabaseRefresh, int>(SupabaseRefresh.new);

// Role State Provider
final currentRoleProvider = Provider<AppUserRole>((ref) {
  ref.watch(supabaseRefreshProvider);
  final service = ref.read(supabaseServiceProvider);
  return service.currentRole;
});

// Sync status provider
final isOfflineProvider = Provider<bool>((ref) {
  ref.watch(supabaseRefreshProvider);
  final service = ref.read(supabaseServiceProvider);
  return service.isOffline;
});

// Realtime Collections Provider
final collectionsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return service.collectionsStream;
});

// Realtime Alerts Provider
final alertsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return service.alertsStream;
});

// Realtime Notifications Provider
final notificationsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return service.notificationsStream;
});

// Dynamic Permission checking provider
final hasPermissionProvider = Provider.family<bool, String>((ref, permissionCode) {
  ref.watch(supabaseRefreshProvider);
  final service = ref.read(supabaseServiceProvider);
  return service.hasPermission(permissionCode);
});
