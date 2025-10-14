import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

// Main Forgot Password Dialog Handler
class ForgotPasswordDialog {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const ForgotPasswordStep1Dialog();
      },
    );
  }
}

// Step 1: Email Input Dialog
class ForgotPasswordStep1Dialog extends StatefulWidget {
  const ForgotPasswordStep1Dialog({super.key});

  @override
  State<ForgotPasswordStep1Dialog> createState() => _ForgotPasswordStep1DialogState();
}

class _ForgotPasswordStep1DialogState extends State<ForgotPasswordStep1Dialog> {
  final TextEditingController emailController = TextEditingController();
  bool isEmailValid = true;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Security Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.blue[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.security,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              'Forgot Password',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              'A verification code will be sent to your email to reset your password.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // Email Input Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Email Input Field with validation styling
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'My email',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: isEmailValid ? Colors.grey[500] : Colors.red,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isEmailValid ? Colors.grey[300]! : Colors.red,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isEmailValid ? Colors.grey[300]! : Colors.red,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isEmailValid ? Colors.blue[600]! : Colors.red,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  onChanged: (value) {
                    // Reset validation state when user types
                    if (!isEmailValid) {
                      setState(() {
                        isEmailValid = true;
                      });
                    }
                  },
                ),
                
                // Error message for invalid email
                if (!isEmailValid)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      'Please enter a valid email address',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[600],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),

            // Send Verification Code Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isLoading ? null : _sendVerificationCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Send Verification Code',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Cancel Button
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Email validation function
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Send verification code handler
  void _sendVerificationCode() async {
    final email = emailController.text.trim();
    
    // Validate email
    if (email.isEmpty || !_isValidEmail(email)) {
      setState(() {
        isEmailValid = false;
      });
      
      // Reset error state after 3 seconds
      Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            isEmailValid = true;
          });
        }
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // TODO: Implement API call to send verification code
      await _sendCodeToEmail(email);
      
      if (mounted) {
        Navigator.of(context).pop(); 
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => ForgotPasswordStep2Dialog(email: email),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending verification code: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Backend API call to send verification code
  Future<void> _sendCodeToEmail(String email) async {
    // TODO: Implement actual API call
    await Future.delayed(const Duration(seconds: 2)); // Simulate network delay
    print('Sending verification code to: $email');
  }
}

// Step 2: Verification Code Input Dialog
class ForgotPasswordStep2Dialog extends StatefulWidget {
  final String email;

  const ForgotPasswordStep2Dialog({
    super.key,
    required this.email,
  });

  @override
  State<ForgotPasswordStep2Dialog> createState() => _ForgotPasswordStep2DialogState();
}

class _ForgotPasswordStep2DialogState extends State<ForgotPasswordStep2Dialog> {
  final List<TextEditingController> codeControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> focusNodes = List.generate(6, (index) => FocusNode());
  bool isCodeValid = true;
  bool isLoading = false;

  @override
  void dispose() {
    for (var controller in codeControllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Security Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.blue[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.security,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              'Forgot Password',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Description with email
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: 'A reset code has been sent to\n'),
                  TextSpan(
                    text: widget.email,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const TextSpan(text: ', check your email to continue\nthe password reset process.'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Verification Code Input Boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) => _buildCodeInputBox(index)),
            ),
            
            // Error message for invalid code
            if (!isCodeValid)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Please enter a valid 6-digit code',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[600],
                  ),
                ),
              ),
            
            const SizedBox(height: 24),

            // Resend Code Section
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Haven't received the verification code? ",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                GestureDetector(
                  onTap: _resendCode,
                  child: Text(
                    'Resend it.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submitCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Submit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Back Button
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              child: Text(
                'Back',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build individual code input box
  Widget _buildCodeInputBox(int index) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        border: Border.all(
          color: isCodeValid ? Colors.grey[300]! : Colors.red,
          width: isCodeValid ? 1 : 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextFormField(
        controller: codeControllers[index],
        focusNode: focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        onChanged: (value) {
          // Reset validation when user types
          if (!isCodeValid) {
            setState(() {
              isCodeValid = true;
            });
          }
          
          // Auto-focus next field
          if (value.isNotEmpty && index < 5) {
            focusNodes[index + 1].requestFocus();
          }
          
          // Auto-focus previous field on backspace
          if (value.isEmpty && index > 0) {
            focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }

  // Get the complete verification code
  String _getVerificationCode() {
    return codeControllers.map((controller) => controller.text).join();
  }

  // Submit verification code
  void _submitCode() async {
    final code = _getVerificationCode();
    
    // Validate code (must be 6 digits)
    if (code.length != 6 || !RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() {
        isCodeValid = false;
      });
      
      // Reset error state after 3 seconds
      Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            isCodeValid = true;
          });
        }
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // TODO: Implement API call to verify code
      await _verifyCode(widget.email, code);
      
      if (mounted) {
        Navigator.of(context).pop();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => ForgotPasswordStep3Dialog(
              email: widget.email,
              verificationCode: code,
            ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isCodeValid = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid verification code: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Resend verification code
  void _resendCode() async {
    try {
      // TODO: Implement resend code API call
      await _sendCodeToEmail(widget.email);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code resent successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resending code: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Backend API calls
  Future<void> _verifyCode(String email, String code) async {
    // TODO: Implement actual API call
    await Future.delayed(const Duration(seconds: 1));
    print('Verifying code: $code for email: $email');
  }

  Future<void> _sendCodeToEmail(String email) async {
    // TODO: Implement actual API call
    await Future.delayed(const Duration(seconds: 1));
    print('Resending code to: $email');
  }
}

// Step 3: Set New Password Dialog
class ForgotPasswordStep3Dialog extends StatefulWidget {
  final String email;
  final String verificationCode;

  const ForgotPasswordStep3Dialog({
    super.key,
    required this.email,
    required this.verificationCode,
  });

  @override
  State<ForgotPasswordStep3Dialog> createState() => _ForgotPasswordStep3DialogState();
}

class _ForgotPasswordStep3DialogState extends State<ForgotPasswordStep3Dialog> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool isPasswordValid = true;
  bool isConfirmPasswordValid = true;
  bool isLoading = false;

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Security Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.blue[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.security,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              'Set a New Password',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              'Please set a new password to secure your Work Mate account.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // Password Input Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Password',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Password Input Field
                TextFormField(
                  controller: passwordController,
                  obscureText: !isPasswordVisible,
                  decoration: InputDecoration(
                    hintText: 'Input Password',
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: isPasswordValid ? Colors.grey[500] : Colors.red,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                      icon: Icon(
                        isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey[500],
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isPasswordValid ? Colors.grey[300]! : Colors.red,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isPasswordValid ? Colors.grey[300]! : Colors.red,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isPasswordValid ? Colors.blue[600]! : Colors.red,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  onChanged: (value) {
                    if (!isPasswordValid) {
                      setState(() {
                        isPasswordValid = true;
                      });
                    }
                  },
                ),
                
                // Password validation error
                if (!isPasswordValid)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      'Password must be at least 8 characters long',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[600],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Confirm Password Input Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Confirm Password',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Confirm Password Input Field
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: !isConfirmPasswordVisible,
                  decoration: InputDecoration(
                    hintText: 'Re Enter Your Password',
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: isConfirmPasswordValid ? Colors.grey[500] : Colors.red,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          isConfirmPasswordVisible = !isConfirmPasswordVisible;
                        });
                      },
                      icon: Icon(
                        isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey[500],
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isConfirmPasswordValid ? Colors.grey[300]! : Colors.red,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isConfirmPasswordValid ? Colors.grey[300]! : Colors.red,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isConfirmPasswordValid ? Colors.blue[600]! : Colors.red,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  onChanged: (value) {
                    if (!isConfirmPasswordValid) {
                      setState(() {
                        isConfirmPasswordValid = true;
                      });
                    }
                  },
                ),
                
                // Confirm password validation error
                if (!isConfirmPasswordValid)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      'Passwords do not match',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[600],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isLoading ? null : _setNewPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Submit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Back Button
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              child: Text(
                'Back',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Password validation
  bool _isPasswordValid(String password) {
    return password.length >= 8;
  }

  // Set new password handler
  void _setNewPassword() async {
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;
    
    bool hasError = false;
    
    // Validate password
    if (!_isPasswordValid(password)) {
      setState(() {
        isPasswordValid = false;
      });
      hasError = true;
    }
    
    // Validate confirm password
    if (password != confirmPassword) {
      setState(() {
        isConfirmPasswordValid = false;
      });
      hasError = true;
    }
    
    if (hasError) {
      // Reset error states after 3 seconds
      Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            isPasswordValid = true;
            isConfirmPasswordValid = true;
          });
        }
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // TODO: Implement API call to update password
      await _updatePassword(widget.email, widget.verificationCode, password);
      
      if (mounted) {
        Navigator.of(context).pop();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const ForgotPasswordStep4Dialog(),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating password: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Backend API call to update password
  Future<void> _updatePassword(String email, String code, String newPassword) async {
    // TODO: Implement actual API call
    await Future.delayed(const Duration(seconds: 2));
    print('Updating password for email: $email with code: $code');
  }
}

// Step 4: Success Dialog - Completion of the existing code
class ForgotPasswordStep4Dialog extends StatelessWidget {
  const ForgotPasswordStep4Dialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Icon with checkmark
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green[400],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),

            // Success Title
            const Text(
              'Password Successfully Updated',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Success Description
            Text(
              'Your account password has been updated.\nPlease use your email and new password to sign in.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // Done Button to close all dialogs
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  // Close all dialog stack and return to login
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}