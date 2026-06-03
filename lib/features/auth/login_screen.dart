import 'dart:ui';
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

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFEEF3FC),
              Color(0xFFFBF4F5),
              Color(0xFFF2F7F6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Soft floating bubbles for parallax depth
            Positioned(
              top: -150,
              right: -100,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFDCE9FF).withValues(alpha: 0.6),
                      const Color(0xFFDCE9FF).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -150,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFE8FDF5).withValues(alpha: 0.7),
                      const Color(0xFFE8FDF5).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 200,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFFF0F5).withValues(alpha: 0.8),
                      const Color(0xFFFFF0F5).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Central login card
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo / Title
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: ShaderMask(
                            shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
                            child: const Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 44,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'LendoraZ',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Text(
                          'Premium Fintech Debt Collections',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Connection Status Banner
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: service.isDemoMode 
                                ? const Color(0xFFFFFBEB) 
                                : const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: service.isDemoMode 
                                  ? const Color(0xFFFDE68A) 
                                  : const Color(0xFFA7F3D0),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (service.isDemoMode 
                                    ? const Color(0xFFD97706) 
                                    : const Color(0xFF059669)).withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: service.isDemoMode 
                                      ? const Color(0xFFFEF3C7) 
                                      : const Color(0xFFD1FAE5),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  service.isDemoMode ? Icons.offline_bolt_outlined : Icons.cloud_done_outlined,
                                  color: service.isDemoMode ? const Color(0xFFD97706) : const Color(0xFF059669),
                                  size: 18,
                                ),
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
                                        color: service.isDemoMode ? const Color(0xFFB45309) : const Color(0xFF047857),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      service.isDemoMode 
                                          ? (service.initError != null ? 'Error: ${service.initError}' : 'Using local sandbox environment.')
                                          : 'Enterprise connection secured and online.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: service.isDemoMode ? const Color(0xFFD97706) : const Color(0xFF059669),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Glassmorphic Form Container
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1E293B).withValues(alpha: 0.06),
                                    blurRadius: 30,
                                    offset: const Offset(0, 15),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    _isSignUp ? 'Create New Account' : 'Sign In to Platform',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -0.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  // Full Name Input (Only shown in Sign Up mode)
                                  if (_isSignUp) ...[
                                    TextField(
                                      controller: _nameController,
                                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15),
                                      decoration: _buildInputDecoration(
                                        labelText: 'Full Name',
                                        prefixIcon: Icons.person_outline_rounded,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  
                                  // Email Input
                                  TextField(
                                    controller: _emailController,
                                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15),
                                    decoration: _buildInputDecoration(
                                      labelText: 'Email Address',
                                      prefixIcon: Icons.email_outlined,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Password Input
                                  TextField(
                                    controller: _passwordController,
                                    obscureText: true,
                                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15),
                                    decoration: _buildInputDecoration(
                                      labelText: 'Password',
                                      prefixIcon: Icons.lock_outline_rounded,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
      
                                  // Role Picker Title
                                  Row(
                                    children: [
                                      const Icon(Icons.shield_outlined, size: 16, color: AppTheme.primaryBlue),
                                      const SizedBox(width: 8),
                                      Text(
                                        _isSignUp ? 'Select Account Role' : 'Select Inspection Role',
                                        style: const TextStyle(
                                          color: Color(0xFF1E293B),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
      
                                  // Interactive Dropdown for checking Roles
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<AppUserRole>(
                                        value: service.currentRole,
                                        dropdownColor: Colors.white,
                                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryBlue, size: 22),
                                        isExpanded: true,
                                        items: AppUserRole.values.map((AppUserRole role) {
                                          return DropdownMenuItem<AppUserRole>(
                                            value: role,
                                            child: Text(
                                              role.displayName,
                                              style: const TextStyle(
                                                color: Color(0xFF0F172A),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
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
                                  const SizedBox(height: 28),

                                  // Action Button
                                  Container(
                                    height: 54,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: AppTheme.primaryGradient,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                                          blurRadius: 16,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : () => _handleLogin(service.currentRole),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
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
                                  const SizedBox(height: 16),
                                  
                                  // Sign Up / Sign In Toggle Link
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _isSignUp = !_isSignUp;
                                      });
                                    },
                                    child: RichText(
                                      text: TextSpan(
                                        style: const TextStyle(fontSize: 14, fontFamily: 'Inter'),
                                        children: [
                                          TextSpan(
                                            text: _isSignUp ? 'Already have an account? ' : 'Don\'t have an account? ',
                                            style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                          ),
                                          TextSpan(
                                            text: _isSignUp ? 'Sign In' : 'Sign Up',
                                            style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w700),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1.2)),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Text(
                                          'OR',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF94A3B8),
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ),
                                      const Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1.2)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Google Login Button
                                  OutlinedButton.icon(
                                    onPressed: _isLoading ? null : () => _handleGoogleLogin(service.currentRole),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                                      backgroundColor: Colors.white,
                                      elevation: 0,
                                    ),
                                    icon: Image.network(
                                      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                                      height: 18,
                                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, color: AppTheme.primaryBlue, size: 22),
                                    ),
                                    label: const Text(
                                      'Continue with Google',
                                      style: TextStyle(
                                        color: Color(0xFF334155),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.lock_outline, size: 12, color: Color(0xFF94A3B8)),
                            SizedBox(width: 6),
                            Text(
                              'Secured by Supabase Vault & RLS policies',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(
        color: Color(0xFF64748B),
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF94A3B8), size: 20),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.dangerRed, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.dangerRed, width: 2),
      ),
    );
  }
}
