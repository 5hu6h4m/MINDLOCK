import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../presentation/home/home_screen.dart';
import '../../presentation/reminders/reminders_screen.dart';
import '../../presentation/reminders/create_reminder_screen.dart';
import '../../presentation/focus/focus_screen.dart';
import '../../presentation/sleep/sleep_screen.dart';
import '../../presentation/analytics/analytics_screen.dart';
import '../../presentation/settings/settings_screen.dart';
import '../../presentation/onboarding/onboarding_screen.dart';
import '../../presentation/shell/main_shell.dart';
import '../../presentation/mission/mission_creation_screen.dart';
import '../../presentation/mission/active_mission_screen.dart';
import '../../presentation/mission/mission_complete_screen.dart';
import '../../core/constants/enums.dart';
import '../../data/local/models/mission_model.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/check-onboarding',
    routes: [
      GoRoute(
        path: '/check-onboarding',
        builder: (context, state) => const OnboardingCheck(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/reminders',
            builder: (context, state) => const RemindersScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  return CreateReminderScreen(editData: extra);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/focus',
            builder: (context, state) => const FocusScreen(),
          ),
          GoRoute(
            path: '/sleep',
            builder: (context, state) => const SleepScreen(),
          ),
          GoRoute(
            path: '/analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/mission/create',
            builder: (context, state) => const MissionCreationScreen(),
          ),
          GoRoute(
            path: '/mission/active',
            builder: (context, state) {
              final args = state.extra as Map<String, dynamic>;
              return ActiveMissionScreen(
                title: args['title'],
                category: MissionCategory.values[args['category']],
                durationMinutes: args['duration'],
                intensity: MissionIntensity.values[args['intensity']],
                isCoFocus: args['isCoFocus'] ?? false,
                roomCode: args['roomCode'] ?? '',
              );
            },
          ),
          GoRoute(
            path: '/mission/complete',
            builder: (context, state) {
              final mission = state.extra as MissionModel;
              return MissionCompleteScreen(mission: mission);
            },
          ),
        ],
      ),
    ],
  );
});

class OnboardingCheck extends StatefulWidget {
  const OnboardingCheck({super.key});
  @override
  State<OnboardingCheck> createState() => _OnboardingCheckState();
}

class _OnboardingCheckState extends State<OnboardingCheck> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('hasSeenOnboarding') ?? false;
    if (mounted) {
      if (hasSeen) {
        context.go('/home');
      } else {
        context.go('/onboarding');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
