import 'package:facilityfix/widgets/forgotPassword.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:facilityfix/tenant/home.dart' as Tenant;
import 'package:facilityfix/staff/home.dart' as Staff;
import 'package:facilityfix/admin/home.dart' as Admin;
import 'package:facilityfix/widgets/forms.dart';

// 👇 per-role ping
import 'package:facilityfix/services/api_services.dart';
import 'package:facilityfix/config/env.dart';

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
  const LogIn({Key? key, required this.role}) : super(key: key);

  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final idController = TextEditingController();
  final passwordController = TextEditingController();
  final buildingController = TextEditingController();

  String? _emailErr;
  String? _idErr;
  String? _buildingErr;
  String? _passwordErr;

  bool _obscurePassword = true;

  String get _normalizedRole => widget.role.toLowerCase();
  bool get _isTenant => _normalizedRole == 'tenant';
  bool get _isStaff => _normalizedRole == 'staff';
  bool get _isAdmin => _normalizedRole == 'admin';

  String get _idLabel {
    if (_isTenant) return 'Tenant ID';
    if (_isStaff) return 'Staff ID';
    if (_isAdmin) return 'Admin ID';
    return 'ID';
  }

  @override
  void initState() {
    super.initState();
    // Ping the specific role’s baseUrl after open
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final api = APIService(roleOverride: _toAppRole(widget.role));
      final ok = await api.testConnection();
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server unreachable: ${api.baseUrl}')),
        );
      }
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    idController.dispose();
    passwordController.dispose();
    buildingController.dispose();
    super.dispose();
  }

  bool _validate() {
    _emailErr = null;
    _idErr = null;
    _buildingErr = null;
    _passwordErr = null;

    final email = emailController.text.trim();
    final id = idController.text.trim();
    final building = buildingController.text.trim();
    final pass = passwordController.text;

    final emailRe = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$');

    if (email.isEmpty) {
      _emailErr = 'Email is required.';
    } else if (!emailRe.hasMatch(email)) {
      _emailErr = 'Enter a valid email address.';
    }

    if (id.isEmpty) {
      _idErr = '$_idLabel is required.';
    }

    if (_isTenant && building.isEmpty) {
      _buildingErr = 'Building & Unit No. is required.';
    }

    if (pass.isEmpty) {
      _passwordErr = 'Password is required.';
    } else if (pass.length < 6) {
      _passwordErr = 'Password must be at least 6 characters.';
    }

    _formKey.currentState?.validate();
    setState(() {});
    return _emailErr == null &&
        _idErr == null &&
        _buildingErr == null &&
        _passwordErr == null;
  }

  void _handleLogin() {
    if (!_validate()) return;

    Widget destination;
    switch (_normalizedRole) {
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
        break;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(), // tap outside to dismiss
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.5),
        body: GestureDetector(
          onTap: () {}, // prevent dismiss on modal tap
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
                        const Text(
                          'Log In',
                          style: TextStyle(
                            color: Color(0xFF005CE7),
                            fontSize: 30,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 24),
                        Form(
                          key: _formKey,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                              children: [
                                // Email
                                InputField(
                                  label: 'Email',
                                  hintText: 'you@example.com',
                                  controller: emailController,
                                  keyboardType:
                                      TextInputType.emailAddress,
                                  isRequired: true,
                                  errorText: _emailErr,
                                  prefixIcon: const Icon(
                                      Icons.mail,
                                      color: Color(0xFF98A2B3)),
                                ),

                                // Role-specific fields
                                if (_isTenant) ...[
                                  InputField(
                                    label: _idLabel,
                                    hintText: 'e.g., T-000123',
                                    controller: idController,
                                    isRequired: true,
                                    errorText: _idErr,
                                    prefixIcon: const Icon(
                                        Icons.badge_outlined,
                                        color: Color(0xFF98A2B3)),
                                  ),
                                  InputField(
                                    label: 'Building & Unit No.',
                                    hintText:
                                        'e.g., Tower A – 10F – 10B',
                                    controller: buildingController,
                                    isRequired: true,
                                    errorText: _buildingErr,
                                    prefixIcon: const Icon(
                                        Icons.location_city_outlined,
                                        color: Color(0xFF98A2B3)),
                                  ),
                                ] else ...[
                                  InputField(
                                    label: _idLabel,
                                    hintText: _isStaff
                                        ? 'e.g., S-000321'
                                        : 'e.g., ADM-0001',
                                    controller: idController,
                                    isRequired: true,
                                    errorText: _idErr,
                                    prefixIcon: const Icon(
                                        Icons.badge_outlined,
                                        color: Color(0xFF98A2B3)),
                                  ),
                                ],

                                // Password
                                InputField(
                                  label: 'Password',
                                  hintText: 'Enter your password',
                                  controller: passwordController,
                                  isRequired: true,
                                  obscureText: _obscurePassword,
                                  errorText: _passwordErr,
                                  prefixIcon: const Icon(
                                      Icons.lock_outline,
                                      color: Color(0xFF98A2B3)),
                                  suffixIcon: Padding(
                                    padding:
                                        const EdgeInsets.only(right: 4),
                                    child: GestureDetector(
                                      behavior: HitTestBehavior
                                          .translucent,
                                      onTap: () => setState(() =>
                                          _obscurePassword =
                                              !_obscurePassword),
                                      child: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24),
                          child: SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF005CE7),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              onPressed: _handleLogin,
                              child: const Text(
                                'Log In',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
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
}
