import 'package:flutter/material.dart';

class DonationTransparencyScreen extends StatelessWidget {
  const DonationTransparencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Transparency'),
        backgroundColor: const Color(0xFFF6EBDD),
        foregroundColor: const Color(0xFF3E2A1F),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF6EBDD),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Text(
          '''
eRamakoti is a devotional app created to help devotees digitally write Sri Rama Nama and participate in spiritual practice.

Core spiritual features of the app are intended to remain accessible to all users. Any support offered through the app is completely voluntary.

Contributions help in:
• Maintaining app infrastructure (hosting, Firebase services, Play Store, Apple Developer account)
• Continuous development, improvements, and user support
• Supporting initiatives such as goshalas (cow protection)
• Assisting development and maintenance of small and rural temples

Support is not a purchase of blessings, spiritual outcomes, or any guaranteed results. They are voluntary offerings made by users who wish to support the platform and its associated causes.

To promote transparency, verified contributions are displayed in the app under the Wall of Support, including basic details such as name (or anonymized), amount, and date.

For any questions or clarifications, users can reach out through the support/contact section of the app.
          ''',
          style: TextStyle(
            fontSize: 15,
            height: 1.6,
            color: Color(0xFF3E2A1F),
          ),
        ),
      ),
    );
  }
}