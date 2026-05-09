import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../services/data_sync_service.dart';
import '../../services/auth_service.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final syncService = ref.read(dataSyncServiceProvider);

      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }

      // After successful login/signup, restore data from cloud
      await syncService.fullSync();

      if (mounted) context.go('/check-onboarding');
    } catch (e) {
      setState(() => _error = e.toString().replaceAll(RegExp(r'\[.*?\]'), ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            left: -100,
            child: _Glow(color: AppTheme.primaryPurple.withOpacity(0.2)),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: _Glow(color: AppTheme.accentCyan.withOpacity(0.2)),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 80),
                    Text(
                      _isLogin ? 'Welcome Back' : 'Create Account',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isLogin 
                        ? 'Login to sync your discipline data' 
                        : 'Start your journey to absolute focus',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    _InputField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    _InputField(
                      controller: _passwordController,
                      label: 'Password',
                      icon: Icons.lock_outline,
                      isPassword: true,
                    ),
                    
                    if (_error != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        _error!,
                        style: const TextStyle(color: AppTheme.accentAmber, fontSize: 13),
                      ),
                    ],
                    
                    const SizedBox(height: 40),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(_isLogin ? 'Login' : 'Sign Up', 
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Center(
                      child: TextButton(
                        onPressed: () => setState(() => _isLogin = !_isLogin),
                        child: Text(
                          _isLogin ? "Don't have an account? Sign Up" : "Already have an account? Login",
                          style: const TextStyle(color: AppTheme.textMuted),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final Color color;
  const _Glow({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      height: 400,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 100,
            spreadRadius: 50,
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isPassword;
  final TextInputType? keyboardType;

  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.isPassword = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.bgDarkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            keyboardType: keyboardType,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppTheme.primaryPurple, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
