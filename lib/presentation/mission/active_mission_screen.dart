import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/enums.dart';
import '../../data/local/models/mission_model.dart';
import '../../data/local/models/user_stats_model.dart';
import '../../data/local/hive_boxes.dart';
import '../../services/platform_channel.dart';
import '../../services/firestore_service.dart';

class ActiveMissionScreen extends StatefulWidget {
  final String title;
  final MissionCategory category;
  final int durationMinutes;
  final MissionIntensity intensity;
  final bool isResuming;

  const ActiveMissionScreen({
    super.key,
    required this.title,
    required this.category,
    required this.durationMinutes,
    required this.intensity,
    this.isCoFocus = false,
    this.roomCode = '',
    this.isResuming = false,
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
    
    // Create or resume mission record
    _mission = MissionModel(
      id: const Uuid().v4(),
      title: widget.title,
      categoryIndex: widget.category.index,
      durationMinutes: widget.durationMinutes,
      intensityIndex: widget.intensity.index,
      startTime: DateTime.now(),
      blockedApps: _blockedApps,
    );
    
    if (!widget.isResuming) {
      HiveBoxes.missions.put(_mission.id, _mission);
    }

    // Setup animations
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _interventionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _initializeMission();
  }

  Future<void> _initializeMission() async {
    // Request Notification Permission
    await Permission.notification.request();

    if (widget.isResuming) {
      final remaining = await PlatformChannel.getRemainingMissionTime();
      setState(() {
        _secondsRemaining = remaining;
      });
    } else {
      PlatformChannel.startMission(_blockedApps, widget.intensity.name, _secondsRemaining);
      PlatformChannel.setDNDMode(true);
    }

    PlatformChannel.onEscapeAttempt = _handleEscapeAttempt;

    if (widget.isCoFocus && widget.roomCode.isNotEmpty) {
      _setupCoFocus();
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _completeMission();
          }
        });
      }
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
    
    if (widget.isCoFocus) {
      _firestore.updateRoomStatus(widget.roomCode, 'failed');
    }
  }

  void _setupCoFocus() async {
    await _firestore.createRoom(widget.roomCode, widget.durationMinutes);
    final roomStream = _firestore.watchRoom(widget.roomCode);
    if (roomStream != null) {
      _roomSubscription = roomStream.listen((doc) {
        if (!doc.exists) return;
        final status = doc.get('status');
        if (status == 'failed' && !_isCompleted) {
          _handleBuddyFailed();
        }
      });
    }
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
    PlatformChannel.stopMission();
    PlatformChannel.setDNDMode(false);
    
    _mission.endTime = DateTime.now();
    _mission.isCompleted = true;
    _mission.focusPointsEarned = (widget.durationMinutes / 10).ceil() * 10;
    _mission.save();

    final stats = HiveBoxes.userStats.get('main') ?? UserStatsModel();
    stats.totalFocusPoints += _mission.focusPointsEarned;
    stats.missionsCompleted++;
    stats.currentStreak++;
    if (stats.currentStreak > stats.longestStreak) {
      stats.longestStreak = stats.currentStreak;
    }
    HiveBoxes.userStats.put('main', stats);

    if (mounted) {
      context.go('/mission/complete', extra: _mission);
    }
  }

  void _abortMission() {
    _timer.cancel();
    PlatformChannel.stopMission();
    PlatformChannel.onEscapeAttempt = null;
    PlatformChannel.setDNDMode(false);

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
    super.dispose();
  }

  String get _timeDisplay {
    final m = _secondsRemaining ~/ 60;
    final s = _secondsRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Background Glow
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (ctx, _) => CustomPaint(
                  painter: _MissionBackgroundPainter(
                    pulse: _pulseController.value,
                    color: AppTheme.accentGreen,
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  
                  Text(
                    'MISSION ACTIVE',
                    style: TextStyle(
                      color: AppTheme.accentGreen.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const Spacer(),

                  // Main Timer
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 320,
                          height: 320,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentGreen.withOpacity(0.1 + (_pulseController.value * 0.05)),
                                blurRadius: 80,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(
                          width: 280,
                          height: 280,
                          child: CustomPaint(
                            painter: _MissionRingPainter(
                              progress: _secondsRemaining / (widget.durationMinutes * 60),
                              color: AppTheme.accentGreen,
                            ),
                          ),
                        ),

                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _timeDisplay,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 84,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -2,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            const Text(
                              'REMAINING',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Bottom Area
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
                    child: Column(
                      children: [
                        if (_escapeAttempts > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'ESCAPES PREVENTED: $_escapeAttempts',
                                    style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        
                        GestureDetector(
                          onLongPressStart: (_) => _interventionController.forward(),
                          onLongPressEnd: (_) {
                            if (_interventionController.value < 1.0) {
                              _interventionController.reverse();
                            }
                          },
                          onLongPress: _abortMission,
                          child: AnimatedBuilder(
                            animation: _interventionController,
                            builder: (ctx, _) {
                              return Container(
                                width: 220,
                                height: 64,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(32),
                                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                                  color: Colors.white.withOpacity(0.03),
                                ),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(32),
                                      child: LinearProgressIndicator(
                                        value: _interventionController.value,
                                        backgroundColor: Colors.transparent,
                                        valueColor: const AlwaysStoppedAnimation(Colors.redAccent),
                                        minHeight: 64,
                                      ),
                                    ),
                                    const Center(
                                      child: Text(
                                        'HOLD TO ABORT',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.5,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'You are shielded until timer ends',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (_showingIntervention)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.black.withOpacity(0.8),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shield_rounded, color: AppTheme.accentGreen, size: 80),
                          const SizedBox(height: 24),
                          const Text(
                            'SHIELD ACTIVE',
                            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Scrolling will weaken your discipline.\nStay focused on your mission.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
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

class _MissionRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _MissionRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, bgPaint);

    final paint = Paint()
      ..color = color
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -3.14 / 2,
        endAngle: 3.14 * 2 - 3.14 / 2,
        colors: [color.withOpacity(0.5), color, color.withOpacity(0.5)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14 / 2,
      progress * 3.14 * 2,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_MissionRingPainter old) => old.progress != progress;
}

class _MissionBackgroundPainter extends CustomPainter {
  final double pulse;
  final Color color;
  _MissionBackgroundPainter({required this.pulse, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.02 + pulse * 0.02)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);

    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.4), 150 + pulse * 50, paint);
  }

  @override
  bool shouldRepaint(_MissionBackgroundPainter old) => true;
}
