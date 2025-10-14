import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:facilityfix/landingpage/login.dart';
import 'package:facilityfix/landingpage/signup.dart';

// ✅ per-role ping
import 'package:facilityfix/services/api_services.dart';
import 'package:facilityfix/config/env.dart'; // defines AppRole

AppRole _toAppRole(String role) {
  switch (role.toLowerCase()) {
    case 'tenant':
      return AppRole.tenant;
    case 'staff':
      return AppRole.staff;
    default:
      return AppRole.tenant;
  }
}

class ChooseRole extends StatelessWidget {
  final bool isLogin; // true for login, false for sign up
  const ChooseRole({super.key, required this.isLogin});

  static const blue = Color(0xFF426CC2);
  static const brandBlue = Color(0xFF005CE7);
  static const textColor = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blue, // ✅ solid blue background
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SafeArea(
          child: Column(
            children: [
              // Logo (200px) with generous spacing
              const SizedBox(height: 32),
              Image.asset(
                "assets/images/logo.png",
                height: 200, // ✅ 200px logo
              ),
              const SizedBox(height: 24),

              // Centered card (kept for contrast & readability)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x144B5563),
                              blurRadius: 16,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isLogin ? 'Log In as' : 'Sign Up as',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Choose your role to continue',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF475467),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(height: 1, color: const Color(0xFFF1F5F9)),
                            const SizedBox(height: 20),

                            // Role buttons (open as modal bottom sheets)
                            _buildRoleButton(context, 'Tenant', 'tenant', brandBlue, isLogin),
                            const SizedBox(height: 12),
                            _buildRoleButton(context, 'Staff', 'staff', brandBlue, isLogin),

                            const SizedBox(height: 20),

                            // Back button
                            SizedBox(
                              width: 160,
                              height: 40,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  'Back',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(
    BuildContext context,
    String label,
    String role,
    Color brandBlue,
    bool isLogin,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandBlue,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        onPressed: () async {
          // 🔌 Quick, non-blocking preflight ping for this role’s baseUrl
          final api = APIService(roleOverride: _toAppRole(role));
          final ok = await api.testConnection();

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(ok ? 'Connected: ${api.baseUrl}' : 'Can’t reach: ${api.baseUrl}'),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }

          // Open as a modal bottom sheet on TOP of ChooseRole.
          if (context.mounted) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => isLogin ? LogIn(role: role) : SignUp(role: role),
            );
          }
        },
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
