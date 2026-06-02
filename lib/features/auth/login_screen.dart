import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/supabase_service.dart';
import '../../core/network/providers.dart';
import '../dashboard/dashboard_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _isSignUp = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _handleLogin(AppUserRole selectedRole) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final fullName = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty || (_isSignUp && fullName.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields.'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final service = ref.read(supabaseServiceProvider);
      if (_isSignUp) {
        await service.signUpWithSupabase(
          email: email,
          password: password,
          fullName: fullName,
          role: selectedRole,
        );
      } else {
        await service.signInWithSupabase(
          email: email,
          password: password,
          fallbackRole: selectedRole,
        );
      }
      
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Auth Error: ${e.toString()}'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    }
  }

  void _handleGoogleLogin(AppUserRole selectedRole) async {
    setState(() => _isLoading = true);
    
    try {
      final service = ref.read(supabaseServiceProvider);
      await service.signInWithGoogle(selectedRole);
      
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-in Error: ${e.toString()}'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(supabaseServiceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient Meshes
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryBlue.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryCyan.withValues(alpha: 0.12),
              ),
            ),
          ),

          // Central login card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo / Title
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                          border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 48,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'LendoraZ',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Premium Fintech Debt Collections',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Connection Status Banner
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: service.isDemoMode 
                              ? AppTheme.warningOrange.withValues(alpha: 0.1) 
                              : AppTheme.neonGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: service.isDemoMode 
                                ? AppTheme.warningOrange.withValues(alpha: 0.3) 
                                : AppTheme.neonGreen.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              service.isDemoMode ? Icons.cloud_off : Icons.cloud_done,
                              color: service.isDemoMode ? AppTheme.warningOrange : AppTheme.neonGreen,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    service.isDemoMode ? 'Running in Local Demo Mode' : 'Connected to Supabase Live',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: service.isDemoMode ? AppTheme.warningOrange : AppTheme.neonGreen,
                                    ),
                                  ),
                                  if (service.isDemoMode) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      service.initError != null
                                          ? 'Error: ${service.initError}'
                                          : 'Initial setup pending. Authenticating locally.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.warningOrange.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ] else ...[
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Database credentials verified and active.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.neonGreen,
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Glassmorphic Form Container
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: AppTheme.glassDecoration(context: context, borderOpacity: 0.15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _isSignUp ? 'Create New Account' : 'Sign In to Platform',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            
                            // Full Name Input (Only shown in Sign Up mode)
                            if (_isSignUp) ...[
                              TextField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: 'Full Name',
                                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            
                            // Email Input
                            TextField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                  labelText: 'Email Address',
                                  prefixIcon: const Icon(Icons.email_outlined, size: 20),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Password Input
                              TextField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                              const SizedBox(height: 24),
  
                              // Role Picker Title
                              Row(
                                children: [
                                  const Icon(Icons.shield_outlined, size: 16, color: AppTheme.primaryBlue),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isSignUp ? 'Select Account Role:' : 'Select Inspection Role:',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
  
                              // Interactive Dropdown for checking Roles
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                                ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<AppUserRole>(
                                  value: service.currentRole,
                                  dropdownColor: Theme.of(context).cardColor,
                                  icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryBlue),
                                  isExpanded: true,
                                  items: AppUserRole.values.map((AppUserRole role) {
                                    return DropdownMenuItem<AppUserRole>(
                                      value: role,
                                      child: Text(
                                        role.displayName,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (AppUserRole? newRole) {
                                    if (newRole != null) {
                                      service.switchRole(newRole);
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Action Button
                            ElevatedButton(
                              onPressed: _isLoading ? null : () => _handleLogin(service.currentRole),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                              ).copyWith(
                                backgroundColor: WidgetStateProperty.all(AppTheme.primaryBlue),
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Container(
                                  constraints: const BoxConstraints(minHeight: 50),
                                  alignment: Alignment.center,
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : Text(
                                          _isSignUp ? 'Register Account' : 'Authenticate Securely',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Sign Up / Sign In Toggle Link
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isSignUp = !_isSignUp;
                                });
                              },
                              child: Text(
                                _isSignUp
                                    ? 'Already have an account? Sign In'
                                    : 'Don\'t have an account? Sign Up',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Expanded(child: Divider()),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text('OR', style: Theme.of(context).textTheme.labelLarge),
                                ),
                                const Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Google Login Button
                            OutlinedButton.icon(
                              onPressed: _isLoading ? null : () => _handleGoogleLogin(service.currentRole),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                              ),
                              icon: const Icon(Icons.g_mobiledata, color: AppTheme.primaryBlue, size: 24),
                              label: const Text(
                                'Continue with Google',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Secured by Supabase Vault & RLS policies',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10),
                      ),
                    ],
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
