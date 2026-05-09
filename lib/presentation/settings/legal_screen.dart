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
MindLock Privacy Policy
Last Updated: May 2026

1. Introduction
MindLock is committed to protecting your privacy. This policy explains how we handle your data.

2. Accessibility Service (CRITICAL)
MindLock uses the Android Accessibility Service to:
- Monitor which application is in the foreground.
- Detect scrolling behavior in specific "distracting" apps.
- Restrict or close apps according to your "Mission Mode" or "Anti-Scroll" settings.

DISCLOSURE: The Accessibility Service is used ONLY for the core functionality of blocking apps and enforcing discipline. We DO NOT:
- Collect any personal or sensitive user data.
- Monitor your keystrokes or read your messages.
- Share any data with third parties.
- Use your data for advertising.

3. Device Administrator
We use Device Administrator permissions to lock the screen during "Deep Sleep" sessions to prevent late-night phone usage.

4. Usage Data
We use the Android UsageStats API to calculate your discipline score. This data is processed locally on your device.

5. Cloud Sync
If you choose to sign in, your progress, streaks, and reminders are stored securely on Google Firebase. You can delete this data at any time.

6. Permissions Summary
- Accessibility: App blocking & Anti-Scroll.
- Device Admin: Screen locking.
- Overlay: Showing alerts over other apps.
- Usage Stats: Calculating productivity scores.

7. Contact
For any privacy concerns, contact: shubhamja9863@gmail.com
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
