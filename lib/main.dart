import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/platform_channel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'data/local/hive_boxes.dart';
import 'core/providers/settings_provider.dart';
import 'services/notification_service.dart';
import 'services/alarm_service.dart';
import 'services/mission_service.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'presentation/overlay/mission_penalty_overlay.dart';
import 'services/data_sync_service.dart';

@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MissionPenaltyOverlay(),
  ));
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase safely
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  await Hive.initFlutter();
  await HiveBoxes.registerAdapters();
  await HiveBoxes.openBoxes();
  await NotificationService.initialize();
  await AlarmService.initialize();
  PlatformChannel.initializeListener();

  // Request critical permissions for Android
  try {
    await [
      Permission.notification,
      Permission.systemAlertWindow,
    ].request();
    
    // Check exact alarm natively
    await PlatformChannel.checkExactAlarmPermission();
  } catch (e) {
    debugPrint('MINDLOCK: Permission error: $e');
  }

  runApp(const ProviderScope(child: MindLockApp()));
}

class MindLockApp extends ConsumerWidget {
  const MindLockApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize global services
    ref.read(missionServiceProvider).initialize();
    
    // Trigger Cloud Sync
    Future.microtask(() => ref.read(dataSyncServiceProvider).fullSync());

    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeProvider);

    // Listen for native alarms
    _setupNativeListener(ref, router);

    // Initial Sync for No Scroll
    final settings = ref.read(settingsProvider);
    PlatformChannel.setNoScrollMode(settings.noScrollEnabled);

    return MaterialApp.router(
      title: 'MINDLOCK',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }

  void _setupNativeListener(WidgetRef ref, GoRouter router) {
    PlatformChannel.onNativeAlarm = (data) {
      debugPrint('MINDLOCK: Received native alarm in Flutter: $data');
      router.push('/reminders/alarm', extra: data);
    };

    PlatformChannel.onNativeNavigation = (route) {
      debugPrint('MINDLOCK: Native requested navigation to: $route');
      router.push(route);
    };
  }
}
