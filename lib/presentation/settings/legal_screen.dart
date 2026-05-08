import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class LegalScreen extends StatelessWidget {
  final String title;
  final String content;

  const LegalScreen({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        title: Text(title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Text(
          content,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.6),
        ),
      ),
    );
  }
}

class PrivacyPolicy {
  static const String content = '''
MINDLOCK Privacy Policy
Last Updated: May 2026

1. Information We Collect:
MINDLOCK collects app usage statistics, reminders, and focus points. This data is used to provide discipline scores and sync your progress.

2. Usage Data:
We use Android UsageStats API to monitor app usage during missions. This data never leaves your device unless you enable Cloud Sync.

3. Cloud Sync:
If you sign in, your data is stored securely on Google Firebase.

4. Permissions:
- Accessibility: Used for app monitoring.
- DND: Used for focus mode.
- Overlay: Used for reminder alerts.
  ''';
}

class TermsOfService {
  static const String content = '''
MINDLOCK Terms of Service

1. Usage:
You agree to use MINDLOCK for productivity purposes.

2. Discipline:
MINDLOCK is a tool, but your discipline is your own. We are not responsible for missed deadlines if you use the "Emergency Exit".

3. Account:
You are responsible for your Firebase account security.
  ''';
}
