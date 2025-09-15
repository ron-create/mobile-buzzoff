import 'package:flutter/material.dart';
import '../utils/responsive.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: const Color(0xFF6A89A7),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFBDDDFC),
      body: Padding(
        padding: EdgeInsets.all(Responsive.padding(context, 20)),
        child: Center(
          child: Text(
            'This is a placeholder for the Privacy Policy.\n\nReplace this with your actual privacy policy.',
            style: TextStyle(fontSize: Responsive.font(context, 16)),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}