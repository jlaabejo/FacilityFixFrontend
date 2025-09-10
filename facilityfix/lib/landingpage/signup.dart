import 'package:facilityfix/widgets/buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:facilityfix/landingpage/choose.dart';
import 'package:facilityfix/tenant/home.dart'; // HomePage
import 'package:facilityfix/widgets/forms.dart' hide DropdownField; // InputField, DropdownField

// 👇 optional per-role ping (same as in LogIn)
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

class SignUp extends StatefulWidget {
  final String role; // 'tenant' | 'staff' | 'admin'
  const SignUp({Key? key, required this.role}) : super(key: key);

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final _formKey = GlobalKey<FormState>();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final birthdateController = TextEditingController();
  final idController = TextEditingController(); // tenant building/unit
  final emailController = TextEditingController();
  final contactNumberController = TextEditingController();
  final passwordController = TextEditingController();

  // Staff classification
  String? _selectedClassification;
  final TextEditingController classificationOtherController =
      TextEditingController();

  bool _submitted = false;

  String? _firstNameErr;
  String? _lastNameErr;
  String? _birthdateErr;
  String? _tenantBuildingErr;
  String? _emailErr;
  String? _contactErr;
  String? _passwordErr;
  String? _staffClassErr;

  bool _obscurePassword = true;

  bool get _isTenant => widget.role.toLowerCase() == 'tenant';
  bool get _isStaff => widget.role.toLowerCase() == 'staff';
  bool get _isAdmin => widget.role.toLowerCase() == 'admin';

  @override
  void initState() {
    super.initState();
    // Optional: ping on open
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
    firstNameController.dispose();
    lastNameController.dispose();
    birthdateController.dispose();
    idController.dispose();
    emailController.dispose();
    contactNumberController.dispose();
    passwordController.dispose();
    classificationOtherController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      birthdateController.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      setState(() => _birthdateErr = null);
    }
  }

  bool _validate() {
    _firstNameErr = null;
    _lastNameErr = null;
    _birthdateErr = null;
    _tenantBuildingErr = null;
    _emailErr = null;
    _contactErr = null;
    _passwordErr = null;
    _staffClassErr = null;

    final first = firstNameController.text.trim();
    final last = lastNameController.text.trim();
    final bday = birthdateController.text.trim();
    final email = emailController.text.trim();
    final contact = contactNumberController.text.trim();
    final pass = passwordController.text;

    if (first.isEmpty) _firstNameErr = 'First Name is required.';
    if (last.isEmpty) _lastNameErr = 'Last Name is required.';
    if (bday.isEmpty) _birthdateErr = 'Birthdate is required.';

    if (_isTenant && idController.text.trim().isEmpty) {
      _tenantBuildingErr = 'Building & Unit No. is required.';
    }

    if (_isStaff && _selectedClassification == 'Others') {
      if (classificationOtherController.text.trim().isEmpty) {
        _staffClassErr = 'Please specify your classification.';
      }
    }

    final emailRe = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$');
    if (email.isEmpty) {
      _emailErr = 'Email is required.';
    } else if (!emailRe.hasMatch(email)) {
      _emailErr = 'Enter a valid email address.';
    }

    if (contact.isNotEmpty && !RegExp(r'^\d{10}$').hasMatch(contact)) {
      _contactErr = 'Enter 10 digits (exclude +63).';
    }

    if (pass.isEmpty) {
      _passwordErr = 'Password is required.';
    } else if (pass.length < 6) {
      _passwordErr = 'Password must be at least 6 characters.';
    }

    _formKey.currentState?.validate();
    setState(() {});
    final basicOk = _firstNameErr == null &&
        _lastNameErr == null &&
        _birthdateErr == null &&
        _tenantBuildingErr == null &&
        _emailErr == null &&
        _contactErr == null &&
        _passwordErr == null;

    final staffOk = !_isStaff || _staffClassErr == null;
    return basicOk && staffOk;
  }

  void _onSubmit() {
    setState(() => _submitted = true);
    if (!_validate()) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(), // tap outside to dismiss
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.5),
        body: GestureDetector(
          onTap: () {}, // prevent dismiss on content tap
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: 600, // fixed modal height
              width: double.infinity,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Color(0xFF005CE7),
                              fontSize: 30,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 24),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // First Name
                                InputField(
                                  label: 'First Name',
                                  hintText: 'e.g., Juan',
                                  controller: firstNameController,
                                  isRequired: true,
                                  errorText: _firstNameErr,
                                ),

                                // Last Name
                                InputField(
                                  label: 'Last Name',
                                  hintText: 'e.g., Dela Cruz',
                                  controller: lastNameController,
                                  isRequired: true,
                                  errorText: _lastNameErr,
                                ),

                                // Birthdate (read-only with picker)
                                InputField(
                                  label: 'Birthdate',
                                  hintText: 'YYYY-MM-DD',
                                  controller: birthdateController,
                                  isRequired: true,
                                  readOnly: true,
                                  onTap: _pickBirthdate,
                                  errorText: _birthdateErr,
                                  prefixIcon: const Icon(
                                      Icons.calendar_today,
                                      color: Color(0xFF98A2B3)),
                                ),

                                // Tenant-only: Building & Unit
                                if (_isTenant)
                                  InputField(
                                    label: 'Building & Unit No.',
                                    hintText:
                                        'e.g., Tower A – 10F – 10B',
                                    controller: idController,
                                    isRequired: true,
                                    errorText: _tenantBuildingErr,
                                    prefixIcon: const Icon(
                                        Icons.location_city_outlined,
                                        color: Color(0xFF98A2B3)),
                                  ),

                                // Staff-only: Classification dropdown
                                if (_isStaff) ...[
                                  DropdownField<String>(
                                    label: 'Classification',
                                    items: const [
                                      'General Maintenance',
                                      'Plumbing',
                                      'Electrician',
                                      'Others',
                                    ],
                                    value: _selectedClassification,
                                    onChanged: (v) => setState(() {
                                      _selectedClassification = v;
                                      if (v != 'Others') {
                                        _staffClassErr = null;
                                      }
                                    }),
                                    isRequired: _submitted,
                                    requiredMessage:
                                        'Classification is required.',
                                    hintText: 'Select classification',
                                    otherController:
                                        classificationOtherController,
                                  ),
                                  if (_staffClassErr != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      _staffClassErr!,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFFD92D20),
                                        height: 1.0,
                                      ),
                                    ),
                                  ],
                                ],

                                // Email
                                InputField(
                                  label: 'Email',
                                  hintText: 'you@example.com',
                                  controller: emailController,
                                  keyboardType:
                                      TextInputType.emailAddress,
                                  isRequired: true,
                                  errorText: _emailErr,
                                  prefixIcon: const Icon(Icons.mail,
                                      color: Color(0xFF98A2B3)),
                                ),

                                // Contact Number (+63 prefix; 10 digits only, optional)
                                InputField(
                                  label: 'Contact Number',
                                  hintText: 'e.g., 9123456789',
                                  controller: contactNumberController,
                                  keyboardType: TextInputType.number,
                                  isRequired: false,
                                  errorText: _contactErr,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                  prefixIcon: const Text(
                                    '+63 ',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      color: Color(0xFF667085),
                                    ),
                                  ),
                                ),

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

                          const SizedBox(height: 8),

                          // Sign Up Button
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24),
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
                                onPressed: _onSubmit,
                                child: const Text(
                                  'Sign Up',
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

                          const SizedBox(height: 24),

                          // Already have an account
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Already have an account? '),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ChooseRole(isLogin: true),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Log in',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
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
