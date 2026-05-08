import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'data/local/hive_boxes.dart';
import 'services/notification_service.dart';
import 'services/mission_service.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'presentation/overlay/mission_penalty_overlay.dart';

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
  await Hive.initFlutter();
  await HiveBoxes.registerAdapters();
  await HiveBoxes.openBoxes();
  await NotificationService.initialize();
  runApp(const ProviderScope(child: MindLockApp()));
}

class MindLockApp extends ConsumerWidget {
  const MindLockApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize global services
    ref.read(missionServiceProvider).initialize();

    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'MINDLOCK',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
