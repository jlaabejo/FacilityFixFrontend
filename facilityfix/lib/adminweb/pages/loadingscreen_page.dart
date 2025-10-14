import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoadingScreenPage extends StatefulWidget {
  const LoadingScreenPage({super.key});

  @override
  State<LoadingScreenPage> createState() => _LoadingScreenPageState();
}

class _LoadingScreenPageState extends State<LoadingScreenPage> {
  @override
  void initState() {
    super.initState();

    // Delay before navigating to login
    Future.delayed(const Duration(seconds: 7), () {
      if (mounted) {
        context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      body: SizedBox.expand(
        child: Image.asset(
          'assets/images/loadingscreen1.gif',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}