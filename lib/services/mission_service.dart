import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'platform_channel.dart';
import 'discipline_service.dart';
import 'streak_service.dart';

final missionServiceProvider = Provider<MissionService>((ref) {
  return MissionService(ref);
});

class MissionService {
  final Ref _ref;

  MissionService(this._ref);

  void initialize() {
    PlatformChannel.initializeListener();
    PlatformChannel.onEscapeAttempt = _handleEscapeAttempt;
  }

  Future<void> _handleEscapeAttempt(String packageName) async {
    // 1. Show the penalty overlay
    final bool isOverlayActive = await FlutterOverlayWindow.isActive();
    if (!isOverlayActive) {
      await FlutterOverlayWindow.showOverlay(
        enableDrag: false,
        flag: OverlayFlag.focusThrough,
        alignment: OverlayAlignment.center,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.none,
        height: WindowSize.matchParent,
        width: WindowSize.matchParent,
      );
    }

    // 2. Add a small penalty to discipline score or log the attempt
    // (Actual persistence happens in ActiveMissionScreen, but we can add global tracking here)
    _ref.read(userStatsProvider.notifier).addFocusPoints(-10);
  }
}
