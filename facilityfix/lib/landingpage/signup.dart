import 'package:facilityfix/landingpage/forgot_password.dart';
import 'package:facilityfix/pages/homepage.dart';
import 'package:flutter/material.dart';

class SignUp extends StatefulWidget {
  final String role;
  const SignUp({Key? key, required this.role}) : super(key: key);

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final birthdateController = TextEditingController();
  final idController = TextEditingController();
  final contactNumberController = TextEditingController(); // ✅ Added
  final passwordController = TextEditingController();

  bool _obscurePassword = true;
  String? selectedClassification;

  @override
  Widget build(BuildContext context) {
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
      onTap: () => Navigator.of(context).pop(), // Dismiss the modal on tap outside
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.5),
        body: GestureDetector(
          onTap: () {}, // prevent tap to dismiss the modal
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
                          'Sign Up',
                          style: TextStyle(
                            color: Color(0xFF005CE7),
                            fontSize: 30,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Form
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [ 
                              _buildTextField(firstNameController, "First Name"),
                              const SizedBox(height: 16), // First Name field
                              _buildTextField(lastNameController, "Last Name"),
                              const SizedBox(height: 16), // Last Name field

                              // Birthdate Picker
                              TextField(
                                controller: birthdateController,
                                readOnly: true,
                                onTap: () async {
                                  DateTime? pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(1900),
                                    lastDate: DateTime.now(),
                                  );
                                  if (pickedDate != null) {
                                    birthdateController.text =
                                        "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
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
                              ),
                              const SizedBox(height: 16),

                              // Role-specific input
                              if (widget.role == 'tenant') ...[
                                _buildTextField(idController, "Building & Unit No."),
                                const SizedBox(height: 16),
                              ] else if (widget.role == 'staff') ...[
                                DropdownButtonFormField<String>(
                                  value: selectedClassification,
                                  onChanged: (value) {
                                    setState(() => selectedClassification = value);
                                  },
                                  items: [
                                    'General Maintenance',
                                    'Plumbing',
                                    'Electrician',
                                  ].map((label) => DropdownMenuItem(
                                        value: label,
                                        child: Text(label),
                                      )).toList(),
                                  decoration: InputDecoration(
                                    hintText: "Classification",
                                    hintStyle: hintTextStyle,
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: inputPadding,
                                    border: borderStyle,
                                    enabledBorder: borderStyle,
                                  ),
                                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF818181)),
                                  dropdownColor: Colors.white,
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Contact Number
                              TextField(
                                controller: contactNumberController,
                                keyboardType: TextInputType.phone,
                                maxLength: 11,
                                decoration: InputDecoration(
                                  hintText: "Contact Number",
                                  hintStyle: hintTextStyle,
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: inputPadding,
                                  border: borderStyle,
                                  enabledBorder: borderStyle,
                                  counterText: "",
                                  prefixText: "+63 ",
                                  prefixStyle: const TextStyle(color: Colors.black),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Password
                              TextField(
                                controller: passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  hintText: "Password",
                                  hintStyle: hintTextStyle,
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: inputPadding,
                                  border: borderStyle,
                                  enabledBorder: borderStyle,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: const Color(0xFF818181),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Sign Up Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF818181),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              // TODO: Add form validation
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const HomePage()),
                              );
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
                        ),
                        const SizedBox(height: 24),

                        // Forgot Password
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                opaque: false,
                                transitionDuration: Duration.zero,
                                reverseTransitionDuration: Duration.zero,
                                pageBuilder: (context, animation, secondaryAnimation) =>
                                    const ForgotPassword(),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  return child;
                                },
                              ),
                            );
                          },
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

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
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
    );
  }
}
