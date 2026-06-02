import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lendoraz/core/network/supabase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('SupabaseService Tests', () {
    late SupabaseService service;

    setUp(() async {
      service = SupabaseService();
      await service.init();
    });

    test('Should seed default collections and customers on init', () {
      expect(service.getCustomers().length, greaterThan(0));
      expect(service.getLoans().length, greaterThan(0));
      expect(service.getCollections().length, greaterThan(0));
    });

    test('Default user role should be super_admin', () {
      expect(service.currentRole, AppUserRole.superAdmin);
    });

    test('Should change role profile data on switchRole', () {
      service.switchRole(AppUserRole.collectionAgent);
      expect(service.currentRole, AppUserRole.collectionAgent);
      expect(service.currentUserEmail, 'rohan@lendoraz.com');
    });

    test('Should queue collection offline and transition state when toggleNetworkMode is triggered', () async {
      // Set to offline
      service.toggleNetworkMode();
      expect(service.isOffline, true);

      // Record offline collection
      final col = await service.recordCollection(
        loanId: 'loan-1',
        amount: 5000.0,
        paymentMethod: 'cash',
        notes: 'Offline Test Collection',
      );

      expect(col['status'], 'pending');
      expect(service.offlineQueue.length, 1);

      // Go online and sync
      service.toggleNetworkMode();
      expect(service.isOffline, false);
      
      // Wait for simulated network delay of sync queue to finish
      await Future.delayed(const Duration(milliseconds: 2500));
      expect(service.offlineQueue.length, 0); // Flushed
    });
  });
}
