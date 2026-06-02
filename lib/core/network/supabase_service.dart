import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

enum AppUserRole {
  superAdmin,
  companyOwner,
  manager,
  collectionAgent,
  accountant,
  customerPortalUser;

  String get displayName {
    switch (this) {
      case AppUserRole.superAdmin: return 'Super Admin';
      case AppUserRole.companyOwner: return 'Company Owner';
      case AppUserRole.manager: return 'Manager';
      case AppUserRole.collectionAgent: return 'Collection Agent';
      case AppUserRole.accountant: return 'Accountant';
      case AppUserRole.customerPortalUser: return 'Customer Portal';
    }
  }
}

class SupabaseService extends ChangeNotifier {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  bool _isDemoMode = true;
  bool _isOffline = false;
  bool _isDemoLoggedIn = false;
  AppUserRole _currentRole = AppUserRole.superAdmin;
  String _currentUserEmail = '';
  String _currentUserName = '';
  String? _initError;

  // Offline queue
  final List<Map<String, dynamic>> _offlineQueue = [];
  
  // Demo In-Memory Database
  final List<Map<String, dynamic>> _customers = [];
  final List<Map<String, dynamic>> _loans = [];
  final List<Map<String, dynamic>> _collections = [];
  final List<Map<String, dynamic>> _reminders = [];
  final List<Map<String, dynamic>> _leads = [];
  final List<Map<String, dynamic>> _chitFunds = [];
  final List<Map<String, dynamic>> _goldLoans = [];
  final List<Map<String, dynamic>> _alerts = [];
  final List<Map<String, dynamic>> _notifications = [];

  bool get isDemoMode => _isDemoMode;
  bool get isOffline => _isOffline;
  bool get isDemoLoggedIn => _isDemoLoggedIn;
  AppUserRole get currentRole => _currentRole;
  String get currentUserEmail => _currentUserEmail;
  String get currentUserName => _currentUserName;
  String? get initError => _initError;
  List<Map<String, dynamic>> get offlineQueue => _offlineQueue;

  // Streams for realtime updates
  final _collectionController = StreamController<List<Map<String, dynamic>>>.broadcast();
  final _alertController = StreamController<List<Map<String, dynamic>>>.broadcast();
  final _notificationController = StreamController<List<Map<String, dynamic>>>.broadcast();

  Stream<List<Map<String, dynamic>>> get collectionsStream => _collectionController.stream;
  Stream<List<Map<String, dynamic>>> get alertsStream => _alertController.stream;
  Stream<List<Map<String, dynamic>>> get notificationsStream => _notificationController.stream;

  Future<void> init() async {
    // Try to load online keys or fall back to demo mode
    try {
      bool alreadyInitialized = false;
      try {
        final client = Supabase.instance.client;
        alreadyInitialized = true;
      } catch (_) {
        alreadyInitialized = false;
      }

      if (!alreadyInitialized) {
        await Supabase.initialize(
          url: 'https://otscqoooecqvznfyhhun.supabase.co',
          anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im90c2Nxb29vZWNxdnpuZnloaHVuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAzODE0MjcsImV4cCI6MjA5NTk1NzQyN30.p6bmgv85Nbg5GolJd9FYg-c1AOmeVWuAnOT_eLElYx4',
        );
      }
      _isDemoMode = false;
      _initError = null;
      
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        updateUserFromSession(currentUser);
      }
    } catch (e) {
      _isDemoMode = true;
      _initError = e.toString();
      debugPrint("Supabase initialize error: $e");
    }

    _loadMockData();
    await _loadOfflineQueue();
  }

  void toggleNetworkMode() {
    _isOffline = !_isOffline;
    if (!_isOffline) {
      syncOfflineQueue();
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    if (!_isDemoMode) {
      await Supabase.instance.client.auth.signOut();
    }
    _isDemoLoggedIn = false;
    _currentUserEmail = '';
    _currentUserName = '';
    notifyListeners();
  }

  void updateUserFromSession(User user) async {
    _currentUserEmail = user.email ?? '';
    _currentUserName = user.email?.split('@')[0] ?? 'Authorized User';

    try {
      final profileData = await Supabase.instance.client
          .from('profiles')
          .select('full_name, role')
          .eq('id', user.id)
          .single();

      _currentUserName = profileData['full_name'] ?? _currentUserName;
      final String? roleStr = profileData['role'];
      if (roleStr != null) {
        for (var r in AppUserRole.values) {
          final dbRole = roleStr.toLowerCase().replaceAll('_', '');
          final enumRole = r.name.toLowerCase().replaceAll('_', '');
          if (dbRole == enumRole) {
            _currentRole = r;
            break;
          }
        }
      }
    } catch (e) {
      // Safe fallback if public profiles table hasn't been read or doesn't exist
    }
    notifyListeners();
  }

  Future<void> signInWithSupabase({
    required String email,
    required String password,
    required AppUserRole fallbackRole,
  }) async {
    if (_isDemoMode) {
      _isDemoLoggedIn = true;
      switchRole(fallbackRole);
      return;
    }

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _isDemoLoggedIn = true;
        _currentUserEmail = response.user!.email ?? email;
        _currentUserName = 'Supabase User';

        // Attempt to fetch profile role from Supabase DB profiles table
        try {
          final profileData = await Supabase.instance.client
              .from('profiles')
              .select('full_name, role')
              .eq('id', response.user!.id)
              .single();

          _currentUserName = profileData['full_name'] ?? 'Supabase User';
          final String? roleStr = profileData['role'];
          if (roleStr != null) {
            for (var r in AppUserRole.values) {
              final dbRole = roleStr.toLowerCase().replaceAll('_', '');
              final enumRole = r.name.toLowerCase().replaceAll('_', '');
              if (dbRole == enumRole) {
                _currentRole = r;
                break;
              }
            }
          }
        } catch (dbError) {
          // If profiles table or user row is not yet registered in public, use drop-down selection role
          switchRole(fallbackRole);
        }
        notifyListeners();
        _addNotification(
          title: 'Supabase Session Active',
          message: 'Signed in as $_currentUserEmail with role ${_currentRole.displayName}.',
          type: 'success',
        );
      }
    } catch (e) {
      _addNotification(
        title: 'Supabase Authentication Failed',
        message: e.toString(),
        type: 'danger',
      );
      rethrow;
    }
  }

  Future<void> signUpWithSupabase({
    required String email,
    required String password,
    required String fullName,
    required AppUserRole role,
  }) async {
    if (_isDemoMode) {
      _isDemoLoggedIn = true;
      _currentUserEmail = email;
      _currentUserName = fullName;
      _currentRole = role;
      notifyListeners();
      return;
    }

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': _roleToDbString(role),
        },
      );

      if (response.user != null) {
        _isDemoLoggedIn = true;
        // Create the profile row in the database as fallback
        try {
          await Supabase.instance.client.from('profiles').upsert({
            'id': response.user!.id,
            'email': email,
            'full_name': fullName,
            'role': _roleToDbString(role),
            'status': 'active',
          });
        } catch (dbError) {
          debugPrint("Public profile creation fallback error: $dbError");
          // If the profile already exists (inserted by the trigger), this is fine.
          // Otherwise, it might be due to missing SQL tables.
        }

        _currentUserEmail = email;
        _currentUserName = fullName;
        _currentRole = role;
        notifyListeners();
        
        _addNotification(
          title: 'Account Created',
          message: 'Registered new profile for $email.',
          type: 'success',
        );
      }
    } catch (e) {
      _addNotification(
        title: 'Signup Error',
        message: e.toString(),
        type: 'danger',
      );
      rethrow;
    }
  }

  String _roleToDbString(AppUserRole role) {
    switch (role) {
      case AppUserRole.superAdmin: return 'super_admin';
      case AppUserRole.companyOwner: return 'company_owner';
      case AppUserRole.manager: return 'manager';
      case AppUserRole.collectionAgent: return 'collection_agent';
      case AppUserRole.accountant: return 'accountant';
      case AppUserRole.customerPortalUser: return 'customer_portal_user';
    }
  }

  Future<void> signInWithGoogle(AppUserRole fallbackRole) async {
    if (_isDemoMode) {
      switchRole(fallbackRole);
      _currentUserEmail = 'google-user@lendoraz.com';
      _currentUserName = 'Google User';
      notifyListeners();
      return;
    }

    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'com.lendora.z.lendoraz://login-callback',
      );
    } catch (e) {
      _addNotification(
        title: 'Google OAuth Failed',
        message: e.toString(),
        type: 'danger',
      );
      rethrow;
    }
  }

  void switchRole(AppUserRole role) {
    _currentRole = role;
    switch (role) {
      case AppUserRole.superAdmin:
        _currentUserName = 'Amit Varma (Super)';
        _currentUserEmail = 'admin@lendoraz.com';
        break;
      case AppUserRole.companyOwner:
        _currentUserName = 'Rajesh Singhal';
        _currentUserEmail = 'owner@lendoraz.com';
        break;
      case AppUserRole.manager:
        _currentUserName = 'Sarah D\'Souza';
        _currentUserEmail = 'sarah@lendoraz.com';
        break;
      case AppUserRole.collectionAgent:
        _currentUserName = 'Rohan Naik';
        _currentUserEmail = 'rohan@lendoraz.com';
        break;
      case AppUserRole.accountant:
        _currentUserName = 'Nisha Iyer';
        _currentUserEmail = 'nisha@lendoraz.com';
        break;
      case AppUserRole.customerPortalUser:
        _currentUserName = 'Ravi Kumar';
        _currentUserEmail = 'ravi@gmail.com';
        break;
    }
    notifyListeners();
  }

  // ==========================================
  // Mock Data Seeding
  // ==========================================
  void _loadMockData() {
    // Seed Customers
    _customers.addAll([
      {
        'id': 'cust-1',
        'full_name': 'Ravi Kumar',
        'phone': '+91 98765 43210',
        'email': 'ravi@gmail.com',
        'pan_number': 'ABCDE1234F',
        'aadhaar_number': '1234-5678-9012',
        'credit_score': 720,
        'risk_level': 'low',
        'address': 'Flat 402, Skyline Towers, Indiranagar, Bengaluru',
        'geo_location': {'lat': 12.9716, 'lng': 77.5946},
      },
      {
        'id': 'cust-2',
        'full_name': 'Ananya Sharma',
        'phone': '+91 98765 00123',
        'email': 'ananya@gmail.com',
        'pan_number': 'FGHIJ5678K',
        'aadhaar_number': '5678-9012-3456',
        'credit_score': 610,
        'risk_level': 'medium',
        'address': 'Sector 15, HSR Layout, Bengaluru',
        'geo_location': {'lat': 12.9141, 'lng': 77.6413},
      },
      {
        'id': 'cust-3',
        'full_name': 'Vikram Malhotra',
        'phone': '+91 91234 56789',
        'email': 'vikram@yahoo.com',
        'pan_number': 'KLMNO9012P',
        'aadhaar_number': '9012-3456-7890',
        'credit_score': 480,
        'risk_level': 'high',
        'address': 'B-302, Green Glen Layout, Bellandur, Bengaluru',
        'geo_location': {'lat': 12.9279, 'lng': 77.6822},
      },
    ]);

    // Seed Loans
    _loans.addAll([
      {
        'id': 'loan-1',
        'customer_id': 'cust-1',
        'principal_amount': 500000.0,
        'interest_rate_annual': 12.0,
        'term_months': 24,
        'monthly_installment': 23536.0,
        'remaining_balance': 320000.0,
        'paid_balance': 180000.0,
        'start_date': '2025-06-01',
        'due_date': '2027-06-01',
        'status': 'active',
        'collateral_type': 'gold',
        'missed_dues': 0,
      },
      {
        'id': 'loan-2',
        'customer_id': 'cust-2',
        'principal_amount': 200000.0,
        'interest_rate_annual': 15.0,
        'term_months': 12,
        'monthly_installment': 18051.0,
        'remaining_balance': 90255.0,
        'paid_balance': 126357.0,
        'start_date': '2025-11-01',
        'due_date': '2026-11-01',
        'status': 'active',
        'collateral_type': 'none',
        'missed_dues': 2,
      },
      {
        'id': 'loan-3',
        'customer_id': 'cust-3',
        'principal_amount': 150000.0,
        'interest_rate_annual': 18.0,
        'term_months': 12,
        'monthly_installment': 13750.0,
        'remaining_balance': 110000.0,
        'paid_balance': 27500.0,
        'start_date': '2026-01-01',
        'due_date': '2027-01-01',
        'status': 'defaulted',
        'collateral_type': 'chit',
        'missed_dues': 5,
      },
    ]);

    // Seed Collections
    _collections.addAll([
      {
        'id': 'coll-1',
        'loan_id': 'loan-1',
        'agent_id': 'agent-1',
        'amount': 23536.0,
        'collection_date': '2026-06-02T10:00:00Z',
        'payment_method': 'upi',
        'status': 'success',
        'receipt_uuid': const Uuid().v4(),
        'notes': 'Paid via PhonePe successfully.',
        'geo_location': {'lat': 12.9719, 'lng': 77.5937},
      },
      {
        'id': 'coll-2',
        'loan_id': 'loan-2',
        'agent_id': 'agent-1',
        'amount': 10000.0,
        'collection_date': '2026-06-01T15:30:00Z',
        'payment_method': 'cash',
        'status': 'success',
        'receipt_uuid': const Uuid().v4(),
        'notes': 'Part payment collected in cash.',
        'geo_location': {'lat': 12.9145, 'lng': 77.6410},
      }
    ]);

    // Seed Reminders
    _reminders.addAll([
      {
        'id': 'rem-1',
        'loan_id': 'loan-1',
        'template_type': 'upcoming_due',
        'channel': 'whatsapp',
        'scheduled_for': '2026-06-04T09:00:00Z',
        'status': 'pending',
      },
      {
        'id': 'rem-2',
        'loan_id': 'loan-2',
        'template_type': 'overdue_notice',
        'channel': 'sms',
        'scheduled_for': '2026-06-02T08:00:00Z',
        'status': 'sent',
        'sent_at': '2026-06-02T08:05:00Z',
      }
    ]);

    // Seed Leads
    _leads.addAll([
      {
        'id': 'lead-1',
        'full_name': 'Kartik Aaryan',
        'phone': '+91 88990 12345',
        'email': 'kartik@gmail.com',
        'requested_amount': 300000.0,
        'status': 'new_lead',
        'notes': 'Applied online for Business Expansion.',
      },
      {
        'id': 'lead-2',
        'full_name': 'Meera Sen',
        'phone': '+91 77665 43210',
        'email': 'meera@gmail.com',
        'requested_amount': 100000.0,
        'status': 'contacted',
        'notes': 'Called customer, requested documents.',
      },
      {
        'id': 'lead-3',
        'full_name': 'Sanjay Dutt',
        'phone': '+91 99009 88776',
        'email': 'sanjay@rediff.com',
        'requested_amount': 750000.0,
        'status': 'approved',
        'notes': 'Documents verified, pending signature.',
      }
    ]);

    // Seed Chit Funds
    _chitFunds.addAll([
      {
        'id': 'chit-1',
        'group_name': 'Indiranagar Premium A1',
        'total_value': 1000000.0,
        'max_members': 20,
        'contribution_monthly': 50000.0,
        'duration_months': 20,
        'status': 'active',
        'current_auction_month': 5,
        'members': [
          {'name': 'Ravi Kumar', 'status': 'paid'},
          {'name': 'Vikram Malhotra', 'status': 'unpaid'},
          {'name': 'Ananya Sharma', 'status': 'paid'},
        ],
        'auctions': [
          {
            'month': 1,
            'winner': 'Suresh Raina',
            'bid': 150000.0,
            'dividend': 7500.0,
          },
          {
            'month': 2,
            'winner': 'Mahendra Singh',
            'bid': 120000.0,
            'dividend': 6000.0,
          }
        ]
      }
    ]);

    // Seed Gold Loans
    _goldLoans.addAll([
      {
        'id': 'gold-1',
        'loan_id': 'loan-1',
        'weight_grams': 120.5,
        'purity_karats': 22,
        'valuation_amount': 780000.0,
        'release_status': 'pledged',
        'item_images': [
          'https://images.unsplash.com/photo-1617038260897-41a1f14a8ca0?q=80&w=400'
        ]
      }
    ]);

    // Seed Alerts
    _alerts.addAll([
      {
        'id': 'alert-1',
        'customer_id': 'cust-3',
        'loan_id': 'loan-3',
        'missed_dues_count': 5,
        'triggered_at': '2026-05-15T09:00:00Z',
        'status': 'active',
      },
      {
        'id': 'alert-2',
        'customer_id': 'cust-2',
        'loan_id': 'loan-2',
        'missed_dues_count': 3,
        'triggered_at': '2026-06-01T04:20:00Z',
        'status': 'active',
      }
    ]);

    // Seed Notifications
    _notifications.addAll([
      {
        'id': 'notif-1',
        'title': 'New Collection Recorded',
        'message': 'Agent Rohan collected ₹23,536 from Ravi Kumar.',
        'time': '2 hours ago',
        'type': 'success',
      },
      {
        'id': 'notif-2',
        'title': 'Risk Alert Triggered',
        'message': 'Vikram Malhotra missed 5 consecutive payments.',
        'time': '1 day ago',
        'type': 'danger',
      },
      {
        'id': 'notif-3',
        'title': 'New Inbound Lead',
        'message': 'Kartik Aaryan requested a business loan of ₹3,00.000.',
        'time': '3 hours ago',
        'type': 'info',
      }
    ]);

    // Dispatch initial collections stream
    _updateControllers();
  }

  void _updateControllers() {
    _collectionController.add(List.from(_collections));
    _alertController.add(List.from(_alerts));
    _notificationController.add(List.from(_notifications));
  }

  // ==========================================
  // Getters for Data Models
  // ==========================================
  List<Map<String, dynamic>> getCustomers() => _customers;
  List<Map<String, dynamic>> getLoans() => _loans;
  List<Map<String, dynamic>> getCollections() => _collections;
  List<Map<String, dynamic>> getReminders() => _reminders;
  List<Map<String, dynamic>> getLeads() => _leads;
  List<Map<String, dynamic>> getChitFunds() => _chitFunds;
  List<Map<String, dynamic>> getGoldLoans() => _goldLoans;
  List<Map<String, dynamic>> getAlerts() => _alerts;
  List<Map<String, dynamic>> getNotifications() => _notifications;

  Map<String, dynamic>? getCustomerById(String id) {
    return _customers.firstWhere((c) => c['id'] == id, orElse: () => {});
  }

  Map<String, dynamic>? getLoanById(String id) {
    return _loans.firstWhere((l) => l['id'] == id, orElse: () => {});
  }

  // ==========================================
  // Collection Actions & Offline Sync System
  // ==========================================
  Future<Map<String, dynamic>> recordCollection({
    required String loanId,
    required double amount,
    required String paymentMethod,
    required String notes,
    String? voiceNoteUrl,
    Map<String, double>? location,
  }) async {
    final loanIndex = _loans.indexWhere((l) => l['id'] == loanId);
    if (loanIndex != -1) {
      // Calculate penalties if any
      final penalties = calculatePenalty(loanId);
      final totalWithPenalty = amount;
      
      // Update Loan Balance
      final loan = _loans[loanIndex];
      double currentRemaining = loan['remaining_balance'] as double;
      double currentPaid = loan['paid_balance'] as double;

      double outstandingWithPenalty = currentRemaining + penalties['total_penalty']!;
      double newRemaining = (outstandingWithPenalty - amount).clamp(0.0, double.infinity);
      double newPaid = currentPaid + amount;

      _loans[loanIndex] = {
        ...loan,
        'remaining_balance': newRemaining,
        'paid_balance': newPaid,
        'missed_dues': newRemaining == 0 ? 0 : loan['missed_dues'],
        'status': newRemaining == 0 ? 'settled' : loan['status'],
      };
    }

    final collectionItem = {
      'id': 'coll-${const Uuid().v4().substring(0, 8)}',
      'loan_id': loanId,
      'agent_id': 'agent-1',
      'amount': amount,
      'collection_date': DateTime.now().toIso8601String(),
      'payment_method': paymentMethod,
      'status': _isOffline ? 'pending' : 'success',
      'receipt_uuid': const Uuid().v4(),
      'notes': notes,
      'voice_note_url': voiceNoteUrl,
      'geo_location': location ?? {'lat': 12.9716, 'lng': 77.5946},
    };

    if (_isOffline) {
      // Save in queue
      _offlineQueue.add(collectionItem);
      await _saveOfflineQueue();
      
      // Trigger local mock notification
      _addNotification(
        title: 'Offline Collection Recorded',
        message: 'Saved ₹$amount. Will sync automatically when online.',
        type: 'warning',
      );
    } else {
      _collections.insert(0, collectionItem);
      _addNotification(
        title: 'Collection Processed',
        message: 'Collected ₹$amount from Customer.',
        type: 'success',
      );
    }

    _updateControllers();
    notifyListeners();
    return collectionItem;
  }

  Future<void> _saveOfflineQueue() async {
    final prefs = await SharedPreferences.getInstance();
    // In demo mode, serialize to string list
    final List<String> list = _offlineQueue.map((c) => c.toString()).toList();
    await prefs.setStringList('offline_collections', list);
  }

  Future<void> _loadOfflineQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('offline_collections');
    if (list != null) {
      // Load offline items (parse maps in simulation mode)
      _offlineQueue.clear();
      // Add items dynamically for demo purposes
    }
  }

  Future<void> syncOfflineQueue() async {
    if (_offlineQueue.isEmpty) return;

    _addNotification(
      title: 'Syncing Offline Queue',
      message: 'Processing ${_offlineQueue.length} offline records...',
      type: 'info',
    );

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    for (var item in _offlineQueue) {
      item['status'] = 'success';
      item['synced_at'] = DateTime.now().toIso8601String();
      _collections.insert(0, item);
    }

    _addNotification(
      title: 'Sync Completed',
      message: 'Successfully synced ${_offlineQueue.length} collection logs.',
      type: 'success',
    );

    _offlineQueue.clear();
    await _saveOfflineQueue();
    _updateControllers();
    notifyListeners();
  }

  // ==========================================
  // Helper calculations (Penalties, AI Risk, CRM, Forecasting)
  // ==========================================
  Map<String, double> calculatePenalty(String loanId) {
    final loan = getLoanById(loanId);
    if (loan == null) return {'late_fee': 0.0, 'interest_penalty': 0.0, 'bounce_charges': 0.0, 'total_penalty': 0.0};

    int missedDues = loan['missed_dues'] ?? 0;
    if (missedDues == 0) return {'late_fee': 0.0, 'interest_penalty': 0.0, 'bounce_charges': 0.0, 'total_penalty': 0.0};

    // Calculate penalties dynamically
    double lateFee = missedDues * 500.0;
    double interestPenalty = (loan['principal_amount'] as double) * 0.02 * missedDues;
    double bounceCharges = missedDues > 1 ? 250.0 : 0.0;

    return {
      'late_fee': lateFee,
      'interest_penalty': interestPenalty,
      'bounce_charges': bounceCharges,
      'total_penalty': lateFee + interestPenalty + bounceCharges,
    };
  }

  Map<String, dynamic> predictAIRisk(String customerId) {
    final customer = getCustomerById(customerId);
    if (customer == null) return {'level': 'low', 'score': 90.0, 'reason': 'Clean history'};

    // Match loan data
    final custLoans = _loans.where((l) => l['customer_id'] == customerId);
    if (custLoans.isEmpty) return {'level': 'low', 'score': 95.0, 'reason': 'No active loans'};

    final mainLoan = custLoans.first;
    int missed = mainLoan['missed_dues'] ?? 0;
    double rem = mainLoan['remaining_balance'] as double;
    double pr = mainLoan['principal_amount'] as double;

    if (missed >= 5) {
      return {
        'level': 'high',
        'score': 15.0,
        'reason': 'Critical: $missed missed dues & high remaining balance (₹$rem).',
      };
    } else if (missed >= 2 || (rem / pr) > 0.8 && customer['credit_score'] < 650) {
      return {
        'level': 'medium',
        'score': 45.0,
        'reason': 'Warning: $missed missed dues & weak credit rating.',
      };
    }

    return {
      'level': 'low',
      'score': 85.0,
      'reason': 'Stable: Consistent repayment & high credit rating.',
    };
  }

  // NLP Voice Parser
  Map<String, dynamic> parseVoiceCollection(String speechText) {
    // Expected phrases: "Ravi paid 500", "Ananya pays 1000", "Ravi Kumar paid 23536"
    final cleanText = speechText.toLowerCase();
    String detectedCustomerName = '';
    double detectedAmount = 0.0;
    String detectedLoanId = '';

    // Simple keyword extraction
    for (var cust in _customers) {
      final name = cust['full_name'].toString().toLowerCase();
      if (cleanText.contains(name) || cleanText.contains(name.split(' ')[0])) {
        detectedCustomerName = cust['full_name'];
        final custLoans = _loans.where((l) => l['customer_id'] == cust['id']);
        if (custLoans.isNotEmpty) {
          detectedLoanId = custLoans.first['id'];
        }
        break;
      }
    }

    // Number extraction
    final RegExp numRegex = RegExp(r'\b\d+\b');
    final match = numRegex.firstMatch(cleanText);
    if (match != null) {
      detectedAmount = double.tryParse(match.group(0)!) ?? 0.0;
    }

    return {
      'success': detectedCustomerName.isNotEmpty && detectedAmount > 0,
      'customer': detectedCustomerName,
      'amount': detectedAmount,
      'loan_id': detectedLoanId,
      'raw_text': speechText,
    };
  }

  // Predictive cashflow forecast (Feature 19)
  Map<String, double> getCashflowForecast() {
    double totalActiveOutstanding = 0.0;
    for (var l in _loans) {
      if (l['status'] == 'active') {
        totalActiveOutstanding += (l['remaining_balance'] as double);
      }
    }

    // Simple predictive analysis
    double expectedTomorrow = totalActiveOutstanding * 0.005;
    double expectedWeekly = totalActiveOutstanding * 0.035;
    double expectedMonthly = totalActiveOutstanding * 0.15;

    return {
      'tomorrow': expectedTomorrow,
      'weekly': expectedWeekly,
      'monthly': expectedMonthly,
    };
  }

  // CRM Leads Pipelines Actions
  void updateLeadStatus(String leadId, String newStatusStr) {
    final idx = _leads.indexWhere((l) => l['id'] == leadId);
    if (idx != -1) {
      _leads[idx]['status'] = newStatusStr;
      notifyListeners();
    }
  }

  // ==========================================
  // Super Admin Controls (Feature 16 & 17)
  // ==========================================
  Future<List<Map<String, dynamic>>> getAllProfiles() async {
    if (_isDemoMode) {
      return [
        {'id': 'user-1', 'email': 'admin@lendoraz.com', 'full_name': 'Amit Varma (Super)', 'role': 'super_admin', 'status': 'active'},
        {'id': 'user-2', 'email': 'owner@lendoraz.com', 'full_name': 'Rajesh Singhal', 'role': 'company_owner', 'status': 'active'},
        {'id': 'user-3', 'email': 'sarah@lendoraz.com', 'full_name': 'Sarah D\'Souza', 'role': 'manager', 'status': 'active'},
        {'id': 'user-4', 'email': 'rohan@lendoraz.com', 'full_name': 'Rohan Naik', 'role': 'collection_agent', 'status': 'active'},
        {'id': 'user-5', 'email': 'nisha@lendoraz.com', 'full_name': 'Nisha Iyer', 'role': 'accountant', 'status': 'suspended'},
        {'id': 'user-6', 'email': 'ravi@gmail.com', 'full_name': 'Ravi Kumar', 'role': 'customer_portal_user', 'status': 'active'},
      ];
    }
    final response = await Supabase.instance.client
        .from('profiles')
        .select()
        .order('email', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateUserProfileRole({
    required String userId,
    required AppUserRole newRole,
    required String status,
  }) async {
    if (_isDemoMode) {
      _addNotification(
        title: 'User Profile Updated (Mock)',
        message: 'Saved role ${newRole.displayName} with status $status.',
        type: 'success',
      );
      return;
    }

    try {
      await Supabase.instance.client.from('profiles').update({
        'role': _roleToDbString(newRole),
        'status': status,
      }).eq('id', userId);

      await logAuditAction(
        action: 'UPDATE_ROLE',
        targetId: userId,
        details: {
          'new_role': _roleToDbString(newRole),
          'new_status': status,
        },
      );
    } catch (e) {
      _addNotification(
        title: 'Failed to Update User',
        message: e.toString(),
        type: 'danger',
      );
      rethrow;
    }
  }

  Future<void> logAuditAction({
    required String action,
    String? targetId,
    Map<String, dynamic>? details,
  }) async {
    if (_isDemoMode) {
      return;
    }

    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      await Supabase.instance.client.from('audit_logs').insert({
        'actor_id': currentUserId,
        'action': action,
        'target_id': targetId,
        'details': details ?? {},
      });
    } catch (e) {
      debugPrint("Failed to write audit log: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getAuditLogs() async {
    if (_isDemoMode) {
      return [
        {'id': 'log-1', 'action': 'USER_LOGIN', 'target_id': 'user-1', 'details': {'ip': '127.0.0.1'}, 'created_at': DateTime.now().subtract(const Duration(minutes: 10)).toIso8601String(), 'profiles': {'full_name': 'Amit Varma (Super)'}},
        {'id': 'log-2', 'action': 'UPDATE_ROLE', 'target_id': 'user-5', 'details': {'new_role': 'accountant', 'new_status': 'suspended'}, 'created_at': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(), 'profiles': {'full_name': 'Sarah D\'Souza'}},
        {'id': 'log-3', 'action': 'COLLECTION_SYNC', 'target_id': 'coll-1', 'details': {'amount': 23536.0}, 'created_at': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(), 'profiles': {'full_name': 'Rohan Naik'}},
      ];
    }
    final response = await Supabase.instance.client
        .from('audit_logs')
        .select('*, profiles(full_name)')
        .order('created_at', ascending: false)
        .limit(100);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getSystemSettings() async {
    if (_isDemoMode) {
      return [
        {'key': 'interest_rate_default', 'value': '12.0', 'description': 'Default annual interest rate for new loans'},
        {'key': 'penalty_rate_monthly', 'value': '2.0', 'description': 'Default monthly penalty rate for overdue loans'},
        {'key': 'sync_interval_seconds', 'value': '60', 'description': 'Default sync polling interval for offline cache queue'}
      ];
    }
    final response = await Supabase.instance.client
        .from('system_settings')
        .select()
        .order('key', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateSystemSetting(String key, String value) async {
    if (_isDemoMode) {
      _addNotification(
        title: 'Settings Saved (Mock)',
        message: '$key updated to $value.',
        type: 'success',
      );
      return;
    }

    try {
      await Supabase.instance.client
          .from('system_settings')
          .update({'value': value})
          .eq('key', key);

      await logAuditAction(
        action: 'UPDATE_SETTING',
        targetId: key,
        details: {'value': value},
      );
    } catch (e) {
      _addNotification(
        title: 'Failed to Save Setting',
        message: e.toString(),
        type: 'danger',
      );
      rethrow;
    }
  }

  // Add notification log
  void _addNotification({
    required String title,
    required String message,
    required String type,
  }) {
    _notifications.insert(0, {
      'id': 'notif-${const Uuid().v4().substring(0, 8)}',
      'title': title,
      'message': message,
      'time': 'Just now',
      'type': type,
    });
    _updateControllers();
  }

  @override
  void dispose() {
    _collectionController.close();
    _alertController.close();
    _notificationController.close();
    super.dispose();
  }
}
