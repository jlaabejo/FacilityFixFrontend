// Required imports
import 'package:flutter/material.dart';
import 'package:facilityfix/landingpage/choose.dart';

// Role homepages
import 'package:facilityfix/tenant/home.dart' as Tenant;
import 'package:facilityfix/staff/home.dart' as Staff;
import 'package:facilityfix/admin/home.dart' as Admin;

class SignUp extends StatefulWidget {
  final String role;
  const SignUp({Key? key, required this.role}) : super(key: key);

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final _formKey = GlobalKey<FormState>();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final birthdateController = TextEditingController();
  final idController = TextEditingController();         // tenant/staff/admin id
  final emailController = TextEditingController();
  final contactNumberController = TextEditingController(); // optional (PH)
  final passwordController = TextEditingController();

  bool _obscurePassword = true;
  String? selectedClassification; // staff only

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    birthdateController.dispose();
    idController.dispose();
    emailController.dispose();
    contactNumberController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _goToHome(String role) {
    Widget dest;
    switch (role.toLowerCase()) {
      case 'admin':
        dest = const Admin.HomePage();
        break;
      case 'staff':
        dest = const Staff.HomePage();
        break;
      case 'tenant':
      default:
        dest = const Tenant.HomePage();
        break;
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => dest),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.role.toLowerCase();
    final isTenant = role == 'tenant';
    final isStaff  = role == 'staff';
    final isAdmin  = role == 'admin';

    const inputPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    const borderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFFE5E6E8), width: 1),
    );
    const hintTextStyle = TextStyle(
      color: Color(0xFF818181),
      fontSize: 14,
      fontFamily: 'Inter',
      fontWeight: FontWeight.w500,
    );

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.5),
        body: GestureDetector(
          onTap: () {}, // keep modal open when tapped
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: 600,
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

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildValidatedField(
                                  controller: firstNameController,
                                  hint: "First Name",
                                ),
                                const SizedBox(height: 16),
                                _buildValidatedField(
                                  controller: lastNameController,
                                  hint: "Last Name",
                                ),
                                const SizedBox(height: 16),

                                // Birthdate
                                TextFormField(
                                  controller: birthdateController,
                                  readOnly: true,
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(1900),
                                      lastDate: DateTime.now(),
                                    );
                                    if (picked != null) {
                                      birthdateController.text =
                                          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                                    }
                                  },
                                  decoration: InputDecoration(
                                    hintText: "Birthdate",
                                    hintStyle: hintTextStyle,
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: inputPadding,
                                    border: borderStyle,
                                    enabledBorder: borderStyle,
                                    suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
                                  ),
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Birthdate is required'
                                      : null,
                                ),
                                const SizedBox(height: 16),

                                // Role-specific fields
                                if (isTenant) ...[
                                  _buildValidatedField(
                                    controller: idController,
                                    hint: "Building & Unit No.",
                                  ),
                                  const SizedBox(height: 16),
                                ] else if (isStaff) ...[
                                  // Staff ID (required)
                                  _buildValidatedField(
                                    controller: idController,
                                    hint: "Staff ID",
                                  ),
                                  const SizedBox(height: 16),
                                  // Staff classification (required)
                                  DropdownButtonFormField<String>(
                                    value: selectedClassification,
                                    onChanged: (v) => setState(() => selectedClassification = v),
                                    items: const [
                                      'General Maintenance',
                                      'Plumbing',
                                      'Electrician',
                                    ].map((label) =>
                                        DropdownMenuItem(value: label, child: Text(label)))
                                      .toList(),
                                    decoration: InputDecoration(
                                      hintText: "Classification",
                                      hintStyle: hintTextStyle,
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: inputPadding,
                                      border: borderStyle,
                                      enabledBorder: borderStyle,
                                    ),
                                    validator: (v) => v == null ? 'Please select classification' : null,
                                  ),
                                  const SizedBox(height: 16),
                                ] else if (isAdmin) ...[
                                  _buildValidatedField(
                                    controller: idController,
                                    hint: "Admin ID",
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                _buildValidatedEmailField(),
                                const SizedBox(height: 16),

                                // OPTIONAL contact number (+63 prefix shown, user types 10 digits)
                                _buildOptionalPhoneField(),
                                const SizedBox(height: 16),

                                _buildValidatedPasswordField(),
                              ],
                            ),
                          ),

                          // Sign Up Button
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF818181),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      // All good — go to role home
                                      _goToHome(role);
                                    }
                                  },
                                  child: const Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
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
                                      builder: (_) => const ChooseRole(isLogin: true),
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

  // ------- Field builders -------

  Widget _buildValidatedField({required TextEditingController controller, required String hint}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFF818181),
          fontSize: 14,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFFE5E6E8), width: 1),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFFE5E6E8), width: 1),
        ),
      ),
      validator: (v) => (v == null || v.isEmpty) ? '$hint is required' : null,
    );
  }

  Widget _buildValidatedEmailField() {
    return TextFormField(
      controller: emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        hintText: "Email",
        hintStyle: TextStyle(
          color: Color(0xFF818181),
          fontSize: 14,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFFE5E6E8), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFFE5E6E8), width: 1),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Email is required';
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v)) return 'Enter a valid email';
        return null;
      },
    );
  }

  // OPTIONAL phone: allow empty; if not empty, must be 10 digits (without +63)
  Widget _buildOptionalPhoneField() {
    return TextFormField(
      controller: contactNumberController,
      keyboardType: TextInputType.phone,
      maxLength: 11, // user may type 10 digits; keeping 11 visual room is fine
      decoration: const InputDecoration(
        hintText: "Contact Number (optional)",
        hintStyle: TextStyle(color: Color(0xFF818181)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFFE5E6E8), width: 1),
        ),
        counterText: "",
        prefixText: "+63 ",
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return null; // optional
        final digitsOnly = v.replaceAll(RegExp(r'\D'), '');
        if (!RegExp(r'^\d{10}$').hasMatch(digitsOnly)) {
          return 'Enter 10 digits (exclude +63)';
        }
        return null;
      },
    );
  }

  Widget _buildValidatedPasswordField() {
    return TextFormField(
      controller: passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        hintText: "Password",
        hintStyle: const TextStyle(color: Color(0xFF818181)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFFE5E6E8), width: 1),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: const Color(0xFF818181),
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Password is required';
        if (v.length < 6) return 'Password must be at least 6 characters';
        return null;
      },
    );
  }
}
