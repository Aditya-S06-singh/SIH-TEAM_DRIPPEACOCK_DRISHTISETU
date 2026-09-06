import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/audit_providers.dart';
import 'dashboard_screen.dart';
import 'incharge_portal_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController =
      TextEditingController(text: 'auditor.lead@sentinel.org');
  final _passwordController = TextEditingController(text: 'Inspector#2026');
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isAuditorRole = true; // true = Ministry Auditor, false = Site Incharge
  String _selectedFacilityId = 'zone-101';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _switchRole(bool isAuditor) {
    setState(() {
      _isAuditorRole = isAuditor;
      if (isAuditor) {
        _emailController.text = 'auditor.lead@sentinel.org';
        _passwordController.text = 'Inspector#2026';
      } else {
        _emailController.text = 'incharge.delhi@dosje-rehab.org';
        _passwordController.text = 'Incharge#2026';
      }
    });
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      ref.read(currentUserProvider.notifier).signIn(
            _emailController.text,
            _passwordController.text,
          );
      setState(() => _isLoading = false);

      if (_isAuditorRole) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => InchargePortalScreen(
              assignedZoneId: _selectedFacilityId,
              inchargeName: 'Dr. Ramesh Kumar (Project Incharge)',
            ),
          ),
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
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFF131920),
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0xFF26303D), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withOpacity(0.18),
                          blurRadius: 28,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.security_rounded,
                      size: 46,
                      color: Colors.cyanAccent,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Attendance & Surveillance Sentinel',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Biometric Turnstile vs YOLO AI Discrepancy Engine',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white60,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Modern Segmented Role Switcher
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131920),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF26303D)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _switchRole(true),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _isAuditorRole ? const Color(0xFF00B4D8) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '🏛️ Auditor Console',
                                style: TextStyle(
                                  color: _isAuditorRole ? Colors.white : Colors.white60,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _switchRole(false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !_isAuditorRole ? Colors.teal : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '🏢 Site Incharge',
                                style: TextStyle(
                                  color: !_isAuditorRole ? Colors.white : Colors.white60,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (!_isAuditorRole) ...[
                    // Facility Selector for Incharge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131920),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF26303D)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedFacilityId,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF131920),
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.tealAccent),
                          items: const [
                            DropdownMenuItem(
                              value: 'zone-101',
                              child: Text('Central Assembly Hall (Floor 1)', style: TextStyle(color: Colors.white, fontSize: 13)),
                            ),
                            DropdownMenuItem(
                              value: 'zone-102',
                              child: Text('Robotics Workshop Block B (Basement 1)', style: TextStyle(color: Colors.white, fontSize: 13)),
                            ),
                            DropdownMenuItem(
                              value: 'zone-103',
                              child: Text('Server Room & Telecom Hub (Floor 3)', style: TextStyle(color: Colors.white, fontSize: 13)),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedFacilityId = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: _isAuditorRole ? 'Auditor Official Email' : 'Site Incharge ID',
                      labelStyle: const TextStyle(color: Colors.white60),
                      prefixIcon: Icon(
                        _isAuditorRole ? Icons.badge_outlined : Icons.business_center_outlined,
                        color: _isAuditorRole ? Colors.cyanAccent : Colors.tealAccent,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF131920),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF26303D)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _isAuditorRole ? Colors.cyanAccent : Colors.tealAccent),
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
                    'Confidential Internal Audit Terminal v2.4',
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
