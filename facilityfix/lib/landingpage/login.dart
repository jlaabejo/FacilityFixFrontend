// lib/widgets/login.dart
import 'package:facilityfix/widgets/forgotPassword.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:facilityfix/tenant/home.dart' as Tenant;
import 'package:facilityfix/staff/home.dart' as Staff;
import 'package:facilityfix/admin/home.dart' as Admin;
import 'package:facilityfix/widgets/forms.dart';

// per-role ping + backend calls
import 'package:facilityfix/services/api_services.dart';
import 'package:facilityfix/config/env.dart';
import 'package:facilityfix/services/auth_storage.dart';

AppRole _toAppRole(String role) {
  switch (role.toLowerCase()) {
    case 'tenant':
      return AppRole.tenant;
    case 'staff':
      return AppRole.staff;
    case 'admin':
      return AppRole.admin;
    default:
      return AppRole.tenant;
  }
}

class LogIn extends StatefulWidget {
  final String role; // 'tenant' | 'staff' | 'admin'
  const LogIn({Key? key, required this.role, String? lanIp}) : super(key: key);

  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String? _emailErr;
  String? _passwordErr;

  bool _obscurePassword = true;
  bool _loading = false;

  String get _normalizedRole => widget.role.toLowerCase();

  @override
  void initState() {
    super.initState();
    // Ping this role’s baseUrl right after opening
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final api = APIService(roleOverride: _toAppRole(widget.role));
      final ok = await api.testConnection();
      if (!mounted) return;
      if (!ok) _showSnack('Server unreachable: ${api.baseUrl}');
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  bool _validate() {
    _emailErr = null;
    _passwordErr = null;

    final email = emailController.text.trim();
    final pass = passwordController.text;

    final emailRe = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$');

    if (email.isEmpty) {
      _emailErr = 'Email is required.';
    } else if (!emailRe.hasMatch(email)) {
      _emailErr = 'Enter a valid email address.';
    }

    if (pass.isEmpty) {
      _passwordErr = 'Password is required.';
    } else if (pass.length < 6) {
      _passwordErr = 'Password must be at least 6 characters.';
    }

    _formKey.currentState?.validate();
    setState(() {});
    return _emailErr == null && _passwordErr == null;
  }

  String _firstFromProfile(Map<String, dynamic> p, String fallbackEmail) {
    final first = (p['first_name'] ?? '').toString().trim();
    if (first.isNotEmpty) return first;
    final full = (p['full_name'] ?? '').toString().trim();
    if (full.isNotEmpty) {
      final parts = full.split(RegExp(r'\s+'));
      if (parts.isNotEmpty && parts.first.isNotEmpty) return parts.first;
    }
    final at = fallbackEmail.indexOf('@');
    if (at > 0) return fallbackEmail.substring(0, at);
    return 'User';
  }

  Future<void> _handleLogin() async {
    if (!_validate()) return;

    setState(() => _loading = true);

    final api = APIService(roleOverride: _toAppRole(widget.role));
    final email = emailController.text.trim();
    final pass = passwordController.text;

    try {
      // Backend accepts email+password; 'role' sent but ignored by backend (ok).
      final res = await api.loginRoleBased(
        role: widget.role,
        email: email,
        password: pass,
      );

      // Read snake_case response
      final Map<String, dynamic> profile =
          (res['profile'] is Map<String, dynamic>) ? (res['profile'] as Map<String, dynamic>) : <String, dynamic>{};

      final role = ((res['role'] ?? profile['role'] ?? widget.role).toString()).toLowerCase();

      // Build and save a complete local profile in snake_case
      final localProfile = <String, dynamic>{
        'user_id': profile['user_id'] ?? res['user_id'],
        'first_name': profile['first_name'] ?? '',
        'last_name': profile['last_name'] ?? '',
        'full_name': profile['full_name'] ??
            '${(profile['first_name'] ?? '').toString()} ${(profile['last_name'] ?? '').toString()}'.trim(),
        'birth_date': profile['birth_date'],
        'email': res['email'] ?? profile['email'] ?? email,
        'phone_number': profile['phone_number'],
        'role': role,
        'building_unit': profile['building_unit'],

        // staff-only 
        'staff_department': profile['staff_department'],
      };
      await AuthStorage.saveProfile(localProfile);

      // Token (snake_case primary; fallbacks included)
      final idToken = (res['id_token'] ?? res['token'] ?? res['idToken'] ?? '').toString();
      if (idToken.isNotEmpty) {
        await AuthStorage.saveToken(idToken);
      }

      // Route by role
      Widget destination;
      switch (role) {
        case 'tenant':
          destination = const Tenant.HomePage();
          break;
        case 'staff':
          destination = const Staff.HomePage();
          break;
        case 'admin':
          destination = const Admin.HomePage();
          break;
        default:
          destination = const Tenant.HomePage();
      }

      if (!mounted) return;
      final first = _firstFromProfile(localProfile, localProfile['email'] ?? email);
      _showSnack('Welcome $first');
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => destination));
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.5),
        body: GestureDetector(
          onTap: () {},
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F4F6),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Log In as ${widget.role[0].toUpperCase()}${widget.role.substring(1)}',
                          style: const TextStyle(
                            color: Color(0xFF005CE7),
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 20),
                        Form(
                          key: _formKey,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                InputField(
                                  label: 'Email',
                                  hintText: 'you@example.com',
                                  controller: emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  isRequired: true,
                                  errorText: _emailErr,
                                  prefixIcon: const Icon(Icons.mail, color: Color(0xFF98A2B3)),
                                ),
                                InputField(
                                  label: 'Password',
                                  hintText: 'Enter your password',
                                  controller: passwordController,
                                  isRequired: true,
                                  obscureText: _obscurePassword,
                                  errorText: _passwordErr,
                                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF98A2B3)),
                                  suffixIcon: Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.translucent,
                                      onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                                      child: Icon(
                                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                        color: const Color(0xFF818181),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Login Button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF005CE7),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              onPressed: _loading ? null : _handleLogin,
                              child: _loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Log In',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white),
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Forgot Password
                        GestureDetector(
                          onTap: _openForgotPassword,
                          child: const Text(
                            'I forgot my password',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openForgotPassword() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const ForgotPasswordEmailModal(),
    );
  }
}
