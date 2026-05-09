import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../presentation/home/home_screen.dart';
import '../../presentation/reminders/reminders_screen.dart';
import '../../presentation/reminders/create_reminder_screen.dart';
import '../../presentation/reminders/alarm_screen.dart';
import '../../presentation/focus/focus_screen.dart';
import '../../presentation/sleep/sleep_screen.dart';
import '../../presentation/analytics/analytics_screen.dart';
import '../../presentation/settings/settings_screen.dart';
import '../../presentation/onboarding/onboarding_screen.dart';
import '../../presentation/shell/main_shell.dart';
import '../../presentation/mission/mission_creation_screen.dart';
import '../../presentation/insights/insights_screen.dart';
import '../../presentation/mission/active_mission_screen.dart';
import '../../presentation/mission/mission_complete_screen.dart';
import '../../presentation/auth/auth_screen.dart';
import '../../core/constants/enums.dart';
import '../../data/local/models/mission_model.dart';
import '../../presentation/reflection/daily_reflection_overlay.dart';
import '../../presentation/reflection/journal_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/check-auth',
    routes: [
      GoRoute(
        path: '/check-auth',
        builder: (context, state) => const AuthCheck(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
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
            pageBuilder: (context, state) => _buildPage(context, state, const HomeScreen()),
          ),
          GoRoute(
            path: '/reminders',
            pageBuilder: (context, state) => _buildPage(context, state, const RemindersScreen()),
            routes: [
              GoRoute(
                path: 'create',
                pageBuilder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  return _buildPage(context, state, CreateReminderScreen(editData: extra));
                },
              ),
              GoRoute(
                path: 'alarm',
                pageBuilder: (context, state) => _buildPage(context, state, AlarmScreen(
                  data: state.extra as Map<String, dynamic>? ?? {},
                )),
              ),
            ],
          ),
          GoRoute(
            path: '/focus',
            pageBuilder: (context, state) => _buildPage(context, state, const FocusScreen()),
          ),
          GoRoute(
            path: '/sleep',
            pageBuilder: (context, state) => _buildPage(context, state, const SleepScreen()),
          ),
          GoRoute(
            path: '/analytics',
            pageBuilder: (context, state) => _buildPage(context, state, const AnalyticsScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => _buildPage(context, state, const SettingsScreen()),
          ),
          GoRoute(
            path: '/insights',
            pageBuilder: (context, state) => _buildPage(context, state, const InsightsScreen()),
          ),
          GoRoute(
            path: '/mission/create',
            pageBuilder: (context, state) => _buildPage(context, state, const MissionCreationScreen()),
          ),
          GoRoute(
            path: '/journal',
            pageBuilder: (context, state) => _buildPage(context, state, const JournalScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/mission/active',
        parentNavigatorKey: null,
        pageBuilder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return _buildPage(context, state, ActiveMissionScreen(
            title: args['title'],
            category: MissionCategory.values[args['category']],
            durationMinutes: args['duration'],
            intensity: MissionIntensity.values[args['intensity']],
            isCoFocus: args['isCoFocus'] ?? false,
            roomCode: args['roomCode'] ?? '',
            isResuming: args['isResuming'] ?? false,
          ));
        },
      ),
      GoRoute(
        path: '/mission/complete',
        pageBuilder: (context, state) {
          final mission = state.extra as MissionModel;
          return _buildPage(context, state, MissionCompleteScreen(mission: mission));
        },
      ),
      GoRoute(
        path: '/reflection/overlay',
        pageBuilder: (context, state) => _buildPage(context, state, const DailyReflectionOverlay()),
      ),
    ],
  );
});

CustomTransitionPage<void> _buildPage(BuildContext context, GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      );
    },
  );
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});
  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final user = FirebaseAuth.instance.currentUser;
    if (mounted) {
      if (user != null) {
        context.go('/check-onboarding');
      } else {
        context.go('/auth');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

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
