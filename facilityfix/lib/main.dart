import 'package:facilityfix/admin/home.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF005CE8),
        hintColor: const Color(0xFFF4F5FF),
        iconButtonTheme: IconButtonThemeData(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(const Color(0xFFF4F5FF)),
            foregroundColor: MaterialStateProperty.all<Color>(const Color(0xFF005CE8)),
          ),
        ),
        fontFamily: 'Inter',
      ),
      home: HomePage()
    );
  }
}