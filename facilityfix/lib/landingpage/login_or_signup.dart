import 'package:facilityfix/landingpage/choose.dart';
import 'package:flutter/material.dart';

class LoginOrSignup extends StatelessWidget {
  final String role;
  const LoginOrSignup({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Logo
            Padding(
              padding: const EdgeInsets.only(top: 40.0),
              child: Center(
                child: Image.asset(
                  "assets/images/Logo.png",
                  height: 120,
                ),
              ),
            ),

            // Spacer 
            const Spacer(),

            // Welcome
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const Text(
                    'Welcome',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // Login
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF005CE8),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            opaque: false, 
                            transitionDuration: Duration.zero,
                            reverseTransitionDuration: Duration.zero,
                            pageBuilder: (context, animation, secondaryAnimation) => ChooseRole(isLogin: true), // true = login
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return child; 
                            },
                          ),
                        );
                      },

                      child: const Text(
                        'Log In',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Sign Up
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF005CE8),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () { // Sign Up
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            opaque: false, 
                            transitionDuration: Duration.zero,
                            reverseTransitionDuration: Duration.zero,
                            pageBuilder: (context, animation, secondaryAnimation) => ChooseRole(isLogin: false), // false = sign up
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return child;
                            },
                          ),
                        );
                      },

                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}