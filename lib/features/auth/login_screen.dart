import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/supabase_service.dart';
import '../../core/network/providers.dart';
import '../dashboard/dashboard_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  late AnimationController _driftController;
  late Animation<double> _driftAnimation;
  
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
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    
    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
    _driftAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _driftController, curve: Curves.easeInOutSine),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _driftController.dispose();
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
        SnackBar(
          content: Text(
            'Please fill in all fields.',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppTheme.dangerRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            content: Text(
              'Auth Error: ${e.toString()}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppTheme.dangerRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            content: Text(
              'Google Sign-in Error: ${e.toString()}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppTheme.dangerRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              Color(0xFFEEF2FF), // Soft light indigo
              Color(0xFFF5F3FF), // Soft light violet
              Color(0xFFFDF2F8), // Soft light peach/pink
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Drifting floating bubbles in the background
            AnimatedBuilder(
              animation: _driftAnimation,
              builder: (context, child) {
                return Stack(
                  children: [
                    Positioned(
                      top: -100 + (40 * _driftAnimation.value),
                      right: -100 - (30 * _driftAnimation.value),
                      child: Container(
                        width: 380,
                        height: 380,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                              blurRadius: 140,
                              spreadRadius: 30,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -120 - (50 * _driftAnimation.value),
                      left: -120 + (40 * _driftAnimation.value),
                      child: Container(
                        width: 420,
                        height: 420,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryCyan.withValues(alpha: 0.08),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryCyan.withValues(alpha: 0.1),
                              blurRadius: 150,
                              spreadRadius: 40,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 220 - (30 * _driftAnimation.value),
                      left: -140 - (20 * _driftAnimation.value),
                      child: Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFFD6E8).withValues(alpha: 0.07),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD6E8).withValues(alpha: 0.09),
                              blurRadius: 100,
                              spreadRadius: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            // Central scrollable panel
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // App Logo Icon
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                              border: Border.all(color: Colors.white, width: 2.5),
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
                          
                          // Fintech Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.12)),
                            ),
                            child: Text(
                              'FINTECH SYSTEM',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryBlue,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Heading Titles
                          ShaderMask(
                            shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
                            child: Text(
                              'LendoraZ',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -1.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'PREMIUM FINTECH DEBT COLLECTIONS',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF64748B),
                              letterSpacing: 2.5,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Supabase Connection Status Card
                          _StatusBanner(isDemo: service.isDemoMode),
                          const SizedBox(height: 20),

                          // Glassmorphic Login Card
                          ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                              child: Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.82),
                                  borderRadius: BorderRadius.circular(32),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF1E293B).withValues(alpha: 0.04),
                                      blurRadius: 40,
                                      offset: const Offset(0, 24),
                                    ),
                                    BoxShadow(
                                      color: AppTheme.primaryBlue.withValues(alpha: 0.01),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      _isSignUp ? 'Create Account' : 'Welcome Back',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0F172A),
                                        letterSpacing: -0.5,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _isSignUp 
                                          ? 'Join the next generation of debt recovery' 
                                          : 'Securely authenticate to access your workspace',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF64748B),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 28),
                                    
                                    // Full Name Field (only visible on signup)
                                    if (_isSignUp) ...[
                                      _CustomTextField(
                                        controller: _nameController,
                                        labelText: 'Full Name',
                                        prefixIcon: Icons.person_outline_rounded,
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                    
                                    // Email Address
                                    _CustomTextField(
                                      controller: _emailController,
                                      labelText: 'Email Address',
                                      prefixIcon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    // Password
                                    _CustomTextField(
                                      controller: _passwordController,
                                      labelText: 'Password',
                                      prefixIcon: Icons.lock_outline_rounded,
                                      obscureText: true,
                                    ),
                                    const SizedBox(height: 24),
        
                                    // Role Selection Area
                                    Row(
                                      children: [
                                        const Icon(Icons.shield_outlined, size: 16, color: AppTheme.primaryBlue),
                                        const SizedBox(width: 8),
                                        Text(
                                          _isSignUp ? 'Select Account Role' : 'Select Inspection Role',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: const Color(0xFF1E293B),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
        
                                    // 2-Column Responsive / Premium Role Grid
                                    GridView.count(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 10,
                                      crossAxisSpacing: 10,
                                      childAspectRatio: 2.4,
                                      children: AppUserRole.values.map((role) {
                                        return _RoleCard(
                                          role: role,
                                          isSelected: service.currentRole == role,
                                          onTap: () => service.switchRole(role),
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 28),
                                    
                                    // Main Submit Button
                                    _PremiumButton(
                                      onPressed: _isLoading ? null : () => _handleLogin(service.currentRole),
                                      text: _isSignUp ? 'Register Account' : 'Authenticate Securely',
                                      isLoading: _isLoading,
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    // Sign In / Sign Up Link
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _isSignUp = !_isSignUp;
                                        });
                                      },
                                      child: RichText(
                                        text: TextSpan(
                                          style: GoogleFonts.inter(fontSize: 14),
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
                                    
                                    // Divider Separator
                                    Row(
                                      children: [
                                        const Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1.2)),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          child: Text(
                                            'OR',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF94A3B8),
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                        ),
                                        const Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1.2)),
                                      ],
                                    ),
                                    const SizedBox(height: 18),
  
                                    // Google Authentication Button
                                    _GoogleButton(
                                      onPressed: _isLoading ? null : () => _handleGoogleLogin(service.currentRole),
                                      isLoading: _isLoading,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          
                          // Secure Footer Info
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.lock_outline, size: 13, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 6),
                              Text(
                                'Secured by Supabase Vault & RLS policies',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
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
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// HELPER COMPONENT WIDGETS
// -----------------------------------------------------------------------------

class _StatusBanner extends StatelessWidget {
  final bool isDemo;
  const _StatusBanner({required this.isDemo});

  @override
  Widget build(BuildContext context) {
    final bgColor = isDemo ? const Color(0xFFFFFBEB) : const Color(0xFFECFDF5);
    final borderColor = isDemo ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5);
    final iconColor = isDemo ? const Color(0xFFD97706) : const Color(0xFF10B981);
    final textColor = isDemo ? const Color(0xFFB45309) : const Color(0xFF047857);
    final titleText = isDemo ? 'Sandbox Demo Mode Active' : 'Connected to Supabase Live';
    final descText = isDemo ? 'Running locally on secure simulated database' : 'Enterprise connection secured and online';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.04),
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
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.12),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              isDemo ? Icons.science_rounded : Icons.verified_user_rounded,
              color: iconColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleText,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  descText,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                    color: textColor.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          _PulseDot(isDemo: isDemo),
        ],
      ),
    );
  }
}

class _CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;

  const _CustomTextField({
    required this.controller,
    required this.labelText,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<_CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<_CustomTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                  blurRadius: 12,
                  spreadRadius: 2,
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.01),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        style: GoogleFonts.inter(
          color: const Color(0xFF0F172A),
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: widget.labelText,
          labelStyle: GoogleFonts.inter(
            color: _isFocused ? AppTheme.primaryBlue : const Color(0xFF64748B),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Icon(
              widget.prefixIcon,
              color: _isFocused ? AppTheme.primaryBlue : const Color(0xFF64748B),
              size: 18,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          filled: true,
          fillColor: _isFocused ? Colors.white : const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final AppUserRole role;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.isSelected,
    required this.onTap,
  });

  IconData _getRoleIcon(AppUserRole role) {
    switch (role) {
      case AppUserRole.superAdmin: return Icons.admin_panel_settings_rounded;
      case AppUserRole.companyOwner: return Icons.business_center_rounded;
      case AppUserRole.manager: return Icons.supervisor_account_rounded;
      case AppUserRole.collectionAgent: return Icons.directions_run_rounded;
      case AppUserRole.accountant: return Icons.account_balance_wallet_rounded;
      case AppUserRole.customer: return Icons.person_rounded;
    }
  }

  String _getRoleDescription(AppUserRole role) {
    switch (role) {
      case AppUserRole.superAdmin: return 'Full Control';
      case AppUserRole.companyOwner: return 'Organization';
      case AppUserRole.manager: return 'Team Analytics';
      case AppUserRole.collectionAgent: return 'Collections';
      case AppUserRole.accountant: return 'Financials';
      case AppUserRole.customer: return 'Client Portal';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryBlue.withValues(alpha: 0.05) 
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : const Color(0xFFE2E8F0),
            width: isSelected ? 2.0 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.005),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppTheme.primaryBlue.withValues(alpha: 0.1) 
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getRoleIcon(role),
                size: 16,
                color: isSelected ? AppTheme.primaryBlue : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    role.displayName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                      color: isSelected ? AppTheme.primaryBlue : const Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _getRoleDescription(role),
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isSelected 
                          ? AppTheme.primaryBlue.withValues(alpha: 0.7) 
                          : const Color(0xFF94A3B8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                size: 14,
                color: AppTheme.primaryBlue,
              ),
          ],
        ),
      ),
    );
  }
}

class _PremiumButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;

  const _PremiumButton({
    required this.onPressed,
    required this.text,
    required this.isLoading,
  });

  @override
  State<_PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<_PremiumButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null && !widget.isLoading;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : (_isHovered && enabled ? 1.02 : 1.0),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: enabled 
                  ? AppTheme.primaryGradient 
                  : LinearGradient(
                      colors: [Colors.grey.shade400, Colors.grey.shade500],
                    ),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withValues(
                          alpha: _isHovered ? 0.45 : 0.3,
                        ),
                        blurRadius: _isHovered ? 24 : 16,
                        offset: Offset(0, _isHovered ? 8 : 6),
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.text,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const _GoogleButton({
    required this.onPressed,
    required this.isLoading,
  });

  @override
  State<_GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends State<_GoogleButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null && !widget.isLoading;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : (_isHovered && enabled ? 1.02 : 1.0),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isHovered ? AppTheme.primaryBlue.withValues(alpha: 0.4) : const Color(0xFFE2E8F0),
                width: 1.5,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(
                  'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                  height: 18,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, color: AppTheme.primaryBlue, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  'Continue with Google',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF334155),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  final bool isDemo;
  const _PulseDot({required this.isDemo});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isDemo ? const Color(0xFFD97706) : const Color(0xFF10B981);
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.6),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}
