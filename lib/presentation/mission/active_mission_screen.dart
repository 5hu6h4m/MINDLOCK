import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/enums.dart';
import '../../services/platform_channel.dart';
import '../../data/local/hive_boxes.dart';
import '../../data/local/models/mission_model.dart';
import '../../data/local/models/user_stats_model.dart';
import '../../services/firestore_service.dart';

class ActiveMissionScreen extends StatefulWidget {
  final String title;
  final MissionCategory category;
  final int durationMinutes;
  final MissionIntensity intensity;

  const ActiveMissionScreen({
    super.key,
    required this.title,
    required this.category,
    required this.durationMinutes,
    required this.intensity,
    this.isCoFocus = false,
    this.roomCode = '',
  });

  final bool isCoFocus;
  final String roomCode;

  @override
  State<ActiveMissionScreen> createState() => _ActiveMissionScreenState();
}

class _ActiveMissionScreenState extends State<ActiveMissionScreen>
    with TickerProviderStateMixin {
  late MissionModel _mission;
  late Timer _timer;
  int _secondsRemaining = 0;
  int _escapeAttempts = 0;
  bool _isCompleted = false;

  late AnimationController _pulseController;
  late AnimationController _interventionController;

  bool _showingIntervention = false;
  final _firestore = FirestoreService();
  StreamSubscription? _roomSubscription;

  final List<String> _blockedApps = [
    "com.google.android.youtube",
    "com.instagram.android",
    "com.zhiliaoapp.musically",
    "com.snapchat.android",
    "com.reddit.frontpage",
    "com.facebook.android",
    "com.twitter.android",
  ];

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.durationMinutes * 60;
    
    // Create mission record
    _mission = MissionModel(
      id: const Uuid().v4(),
      title: widget.title,
      categoryIndex: widget.category.index,
      durationMinutes: widget.durationMinutes,
      intensityIndex: widget.intensity.index,
      startTime: DateTime.now(),
      blockedApps: _blockedApps,
    );
    HiveBoxes.missions.put(_mission.id, _mission);

    // Setup animations
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _interventionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    if (widget.intensity != MissionIntensity.hardcore) {
      PlatformChannel.startMission(_blockedApps, widget.intensity.name);
      PlatformChannel.onEscapeAttempt = _handleEscapeAttempt;
      // Enable Smart DND
      PlatformChannel.setDNDMode(true);
    }

    // Co-Focus Logic
    if (widget.isCoFocus && widget.roomCode.isNotEmpty) {
      _setupCoFocus();
    }

    // Start timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _completeMission();
        }
      });
    });
  }

  void _handleEscapeAttempt(String pkg) {
    if (_isCompleted) return;
    setState(() {
      _escapeAttempts++;
      _mission.escapeAttempts = _escapeAttempts;
      _mission.save();
    });

    PlatformChannel.vibrate(intensity: 2);
    _showIntervention();
    
    // Notify room of escape
    if (widget.isCoFocus) {
      _firestore.updateRoomStatus(widget.roomCode, 'failed');
    }
  }

  void _setupCoFocus() async {
    // Check if room exists, if not create it
    await _firestore.createRoom(widget.roomCode, widget.durationMinutes);
    
    _roomSubscription = _firestore.watchRoom(widget.roomCode).listen((doc) {
      if (!doc.exists) return;
      final status = doc.get('status');
      if (status == 'failed' && !_isCompleted) {
        _handleBuddyFailed();
      }
    });
  }

  void _handleBuddyFailed() {
    _timer.cancel();
    _isCompleted = true;
    PlatformChannel.stopMission();
    PlatformChannel.setDNDMode(false);
    
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: AppTheme.bgDarkCard,
          title: const Text('MISSION FAILED', style: TextStyle(color: AppTheme.accentRed)),
          content: const Text('Your buddy escaped! The collective focus has been broken.'),
          actions: [
            TextButton(
              onPressed: () => context.go('/home'),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      );
    }
  }

  void _showIntervention() {
    if (_showingIntervention) return;
    setState(() => _showingIntervention = true);
    _interventionController.forward();

    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        _interventionController.reverse().then((_) {
          setState(() => _showingIntervention = false);
        });
      }
    });
  }

  void _completeMission() {
    _timer.cancel();
    _isCompleted = true;
    
    // Stop native blocking
    PlatformChannel.stopMission();
    PlatformChannel.onEscapeAttempt = null;
    PlatformChannel.setDNDMode(false);

    // Calculate XP
    int xp = widget.durationMinutes * 10;
    if (widget.intensity == MissionIntensity.hardcore) xp = (xp * 1.5).toInt();
    if (_escapeAttempts == 0) xp += 50; // Flawless bonus
    
    // Penalize escapes
    xp -= (_escapeAttempts * 20);
    if (xp < 0) xp = 0;

    _mission.isCompleted = true;
    _mission.endTime = DateTime.now();
    _mission.focusPointsEarned = xp;
    _mission.save();

    // Update User Stats
    final stats = HiveBoxes.userStats.get('main') ?? UserStatsModel();
    stats.totalFocusPoints += xp;
    stats.missionsCompleted++;
    stats.currentStreak++;
    if (stats.currentStreak > stats.longestStreak) {
      stats.longestStreak = stats.currentStreak;
    }
    stats.lastMissionDate = DateTime.now();
    HiveBoxes.userStats.put('main', stats);

    // Navigate to completion
    if (mounted) {
      context.go('/mission/complete', extra: _mission);
    }
  }

  void _abortMission() {
    _timer.cancel();
    PlatformChannel.stopMission();
    PlatformChannel.onEscapeAttempt = null;
    PlatformChannel.setDNDMode(false);

    // Save as failed
    _mission.endTime = DateTime.now();
    _mission.save();

    final stats = HiveBoxes.userStats.get('main') ?? UserStatsModel();
    stats.missionsFailed++;
    stats.currentStreak = 0;
    HiveBoxes.userStats.put('main', stats);

    context.pop();
  }

  @override
  void dispose() {
    _timer.cancel();
    _roomSubscription?.cancel();
    _pulseController.dispose();
    _interventionController.dispose();
    PlatformChannel.stopMission();
    PlatformChannel.onEscapeAttempt = null;
    super.dispose();
  }

  String get _formattedTime {
    final h = _secondsRemaining ~/ 3600;
    final m = (_secondsRemaining % 3600) ~/ 60;
    final s = _secondsRemaining % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Block system back button
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: Stack(
          children: [
            // Ambient particles / glow
            AnimatedBuilder(
              animation: _pulseController,
              builder: (ctx, child) {
                return Positioned(
                  top: MediaQuery.of(context).size.height * 0.2,
                  left: -50,
                  right: -50,
                  child: Container(
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.intensity == MissionIntensity.hardcore
                          ? AppTheme.accentRed.withOpacity(0.05 + _pulseController.value * 0.05)
                          : AppTheme.accentBlue.withOpacity(0.05 + _pulseController.value * 0.05),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                      child: const SizedBox(),
                    ),
                  ),
                );
              },
            ),

            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'MISSION ACTIVE',
                    style: TextStyle(
                      color: widget.intensity == MissionIntensity.hardcore ? AppTheme.accentRed : AppTheme.accentBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  
                  if (widget.isCoFocus) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.accentCyan.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.accentCyan.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people_alt_rounded, color: AppTheme.accentCyan, size: 14),
                          const SizedBox(width: 8),
                          Text(
                            'Co-Focus: Room ${widget.roomCode}',
                            style: const TextStyle(color: AppTheme.accentCyan, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const Spacer(),

                  // Huge Timer
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Progress Ring
                      SizedBox(
                        width: 280,
                        height: 280,
                        child: CircularProgressIndicator(
                          value: _secondsRemaining / (widget.durationMinutes * 60),
                          strokeWidth: 4,
                          backgroundColor: AppTheme.borderColor,
                          color: widget.intensity == MissionIntensity.hardcore ? AppTheme.accentRed : AppTheme.accentBlue,
                        ),
                      ),
                      // Time Text
                      Text(
                        _formattedTime,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: _secondsRemaining >= 3600 ? 56 : 72,
                          fontWeight: FontWeight.w300,
                          letterSpacing: -2,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),
                  if (_escapeAttempts > 0)
                    Text(
                      'Escape Attempts: $_escapeAttempts',
                      style: const TextStyle(
                        color: AppTheme.accentRed,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const SizedBox(height: 40),

                  // Emergency Exit (Requires hold)
                  GestureDetector(
                    onLongPress: _abortMission,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.bgDarkElevated,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: const Text(
                        'Hold to Abort',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),

            // Intervention Overlay
            if (_showingIntervention)
              FadeTransition(
                opacity: _interventionController,
                child: Container(
                  color: AppTheme.bgDark.withOpacity(0.9),
                  width: double.infinity,
                  height: double.infinity,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppTheme.accentRed, size: 64),
                          const SizedBox(height: 24),
                          const Text(
                            'STAY LOCKED IN.',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'You started this mission for a reason.\nScrolling now will break your progress.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
