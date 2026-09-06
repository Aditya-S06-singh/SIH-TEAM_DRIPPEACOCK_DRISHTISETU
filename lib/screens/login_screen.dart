import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/audit_providers.dart';
import 'dashboard_screen.dart';
import 'inspector_app_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController =
      TextEditingController(text: 'official.lead@dosje.gov.in');
  final _passwordController = TextEditingController(text: 'Official#2026');
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _activeRole = 'official'; // 'official' | 'inspector'

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _switchRole(String role) {
    setState(() {
      _activeRole = role;
      if (role == 'official') {
        _emailController.text = 'official.lead@dosje.gov.in';
        _passwordController.text = 'Official#2026';
      } else {
        _emailController.text = 'inspector.pmu04@dosje.gov.in';
        _passwordController.text = 'Inspector#2026';
      }
    });
  }

  Widget _buildRoleTab(String role, String label, Color color) {
    final isSelected = _activeRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchRole(role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      ref.read(currentUserProvider.notifier).signIn(
            _emailController.text,
            _passwordController.text,
            role: _activeRole,
          );
      setState(() => _isLoading = false);

      if (_activeRole == 'official') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const InspectorAppScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D12),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF131920),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF26303D), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withValues(alpha: 0.18),
                          blurRadius: 28,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.account_balance_rounded,
                      size: 42,
                      color: Colors.cyanAccent,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'DrishtiSetu',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Intelligent Scheme Monitoring & Inspection Platform\nDoSJE • Problem Statement 26095',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white60,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2-Way Segmented Role Switcher
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131920),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF26303D)),
                    ),
                    child: Row(
                      children: [
                        _buildRoleTab('official', '🏛️ DoSJE Official', const Color(0xFF00B4D8)),
                        _buildRoleTab('inspector', '📱 Field Inspector', Colors.purpleAccent),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: _activeRole == 'official'
                          ? 'DoSJE Official Email'
                          : 'Inspector Service ID / Email',
                      labelStyle: const TextStyle(color: Colors.white60),
                      prefixIcon: Icon(
                        _activeRole == 'official'
                            ? Icons.badge_outlined
                            : Icons.verified_user_outlined,
                        color: _activeRole == 'official'
                            ? Colors.cyanAccent
                            : Colors.purpleAccent,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF131920),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF26303D)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _activeRole == 'official'
                              ? Colors.cyanAccent
                              : Colors.purpleAccent,
                        ),
                      ),
                    ),
                    validator: (v) => v == null || !v.contains('@')
                        ? 'Enter a valid enterprise email'
                        : null,
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Security Password',
                      labelStyle: const TextStyle(color: Colors.white60),
                      prefixIcon: const Icon(Icons.lock_outline,
                          color: Colors.cyanAccent),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white54,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF131920),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF26303D)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.cyanAccent),
                      ),
                    ),
                    validator: (v) => v == null || v.length < 6
                        ? 'Password must be at least 6 characters'
                        : null,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent.shade700,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.black, strokeWidth: 2.5),
                            )
                          : Text(
                              'AUTHENTICATE & ENTER',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Confidential Internal Audit Terminal v5.1',
                    textAlign: TextAlign.center,
                    style:
                        GoogleFonts.inter(fontSize: 11, color: Colors.white24),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
