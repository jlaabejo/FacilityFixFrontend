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
  final userIdController = TextEditingController();
  final passwordController = TextEditingController();

  // Role extras
  final staffDeptController = TextEditingController();     // staffDepartment
  final buildingUnitIdController = TextEditingController(); // buildingUnitId

  String? _emailErr;
  String? _userIdErr;
  String? _passwordErr;
  String? _deptErr;
  String? _bunitErr;

  bool _obscurePassword = true;
  bool _loading = false;

  String get _normalizedRole => widget.role.toLowerCase();
  bool get _isTenant => _normalizedRole == 'tenant';
  bool get _isStaff => _normalizedRole == 'staff';
  bool get _isAdmin => _normalizedRole == 'admin';

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
    userIdController.dispose();
    passwordController.dispose();
    staffDeptController.dispose();
    buildingUnitIdController.dispose();
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
    _userIdErr = null;
    _passwordErr = null;
    _deptErr = null;
    _bunitErr = null;

    final email = emailController.text.trim();
    final userId = userIdController.text.trim();
    final pass = passwordController.text;

    final emailRe = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$');

    if (email.isEmpty) {
      _emailErr = 'Email is required.';
    } else if (!emailRe.hasMatch(email)) {
      _emailErr = 'Enter a valid email address.';
    }

    if (userId.isEmpty) {
      _userIdErr = (_isTenant ? 'Tenant ID' : _isStaff ? 'Staff ID' : 'Admin ID') + ' is required.';
    }

    if (pass.isEmpty) {
      _passwordErr = 'Password is required.';
    } else if (pass.length < 6) {
      _passwordErr = 'Password must be at least 6 characters.';
    }

    if (_isStaff) {
      if (staffDeptController.text.trim().isEmpty) {
        _deptErr = 'Department is required.';
      }
    }

    if (_isTenant) {
      if (buildingUnitIdController.text.trim().isEmpty) {
        _bunitErr = 'Building & Unit ID is required.';
      }
    }

    _formKey.currentState?.validate();
    setState(() {});
    return _emailErr == null &&
        _userIdErr == null &&
        _passwordErr == null &&
        _deptErr == null &&
        _bunitErr == null;
  }

  Future<void> _handleLogin() async {
    if (!_validate()) return;

    setState(() => _loading = true);

    final api = APIService(roleOverride: _toAppRole(widget.role));
    final email = emailController.text.trim();
    final userId = userIdController.text.trim();
    final pass = passwordController.text;
    final dept = _isStaff ? staffDeptController.text.trim() : null;
    final bunit = _isTenant ? buildingUnitIdController.text.trim() : null;

    try {
      final res = await api.loginRoleBased(
        role: widget.role,
        email: email,
        userId: userId,
        password: pass,
        staffDepartment: dept,
        buildingUnitId: bunit,
      );

      // Save profile + token
      final profile = <String, dynamic>{
        'user_id': res['user_id'] ?? userId,
        'first_name': res['first_name'] ?? res['firstName'] ?? '',
        'last_name': res['last_name'] ?? res['lastName'] ?? '',
        'email': res['email'] ?? email,
        'role': (res['role'] ?? widget.role).toString(),
        'building_unit': res['building_unit'] ?? res['unit'] ?? bunit ?? '',
      };
      await AuthStorage.saveProfile(profile);

      final idToken = (res['id_token'] ?? res['token'] ?? '').toString();
      if (idToken.isNotEmpty) {
        await AuthStorage.saveToken(idToken);
      }

      final role = (res['role'] ?? widget.role).toString().toLowerCase();
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
      _showSnack('Welcome ${profile['user_id'] ?? ''}');
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => destination));
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _idLabel {
    if (_isTenant) return 'Tenant ID';
    if (_isStaff) return 'Staff ID';
    if (_isAdmin) return 'Admin ID';
    return 'User ID';
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
                                  label: _idLabel,
                                  hintText: _isTenant
                                      ? 'e.g., T-000123'
                                      : _isStaff
                                          ? 'e.g., S-000321'
                                          : 'e.g., ADM-0001',
                                  controller: userIdController,
                                  isRequired: true,
                                  errorText: _userIdErr,
                                  prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF98A2B3)),
                                ),
                                if (_isStaff)
                                  InputField(
                                    label: 'Department',
                                    hintText: 'e.g., Electrical',
                                    controller: staffDeptController,
                                    isRequired: true,
                                    errorText: _deptErr,
                                    prefixIcon: const Icon(Icons.apartment_outlined, color: Color(0xFF98A2B3)),
                                  ),
                                if (_isTenant)
                                  InputField(
                                    label: 'Building & Unit ID',
                                    hintText: 'e.g., B1-U502 (or TowerA-10F-10B)',
                                    controller: buildingUnitIdController,
                                    isRequired: true,
                                    errorText: _bunitErr,
                                    prefixIcon: const Icon(Icons.location_city_outlined, color: Color(0xFF98A2B3)),
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
