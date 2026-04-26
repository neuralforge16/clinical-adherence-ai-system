import 'package:flutter/material.dart';
import 'pages/login_page.dart';

void main() {
  runApp(const MedApp());
}

class MedApp extends StatelessWidget {
  const MedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Medication System",
      home: const LoginPage(),
    );
  }
}
