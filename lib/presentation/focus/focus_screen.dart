import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mindlock/core/constants/enums.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/hive_boxes.dart';
import '../../data/local/models/user_stats_model.dart';
import '../../data/local/models/mission_model.dart';
import '../../services/discipline_service.dart';
import '../../services/streak_service.dart';
import '../../services/platform_channel.dart';

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});
  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen>
    with TickerProviderStateMixin {
  int _selectedMinutes = 25;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  Timer? _timer;
  Timer? _activeMissionCheckTimer;
  late AnimationController _ringController;
  late AnimationController _pulseController;
  late AnimationController _bgAnimationController;

  bool _hasActiveMission = false;
  int _activeMissionRemainingSeconds = 0;
  int _totalMissionSeconds = 25 * 60;

  final _presets = [15, 25, 30, 45, 60, 90];

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _selectedMinutes * 60),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _checkActiveMission();
    _activeMissionCheckTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkActiveMission();
    });
  }

  Future<void> _checkActiveMission() async {
    final remaining = await PlatformChannel.getRemainingMissionTime();
    if (mounted) {
      if (remaining > 0) {
        // If transitioning from no mission to mission, fetch total time
        if (!_hasActiveMission) {
          final details = await PlatformChannel.getActiveMissionDetails();
          // We can't easily get total mission time from details yet, 
          // let's assume it's current remaining if we just joined, 
          // or we could store total time in Prefs too.
          // For now, let's just use 25m as base for the ring progress if unknown.
        }
        setState(() {
          _hasActiveMission = true;
          _activeMissionRemainingSeconds = remaining;
        });
      } else {
        if (_hasActiveMission) {
          setState(() {
            _hasActiveMission = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _activeMissionCheckTimer?.cancel();
    _ringController.dispose();
    _pulseController.dispose();
    _bgAnimationController.dispose();
    super.dispose();
  }

  void _start() {
    HapticFeedback.mediumImpact();
    setState(() => _isRunning = true);
    _ringController.forward(
        from: 1 - _remainingSeconds / (_selectedMinutes * 60));
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds <= 0) {
        _complete();
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  void _pause() {
    HapticFeedback.lightImpact();
    _timer?.cancel();
    _ringController.stop();
    setState(() => _isRunning = false);
  }

  void _reset() {
    HapticFeedback.selectionClick();
    _timer?.cancel();
    _ringController.reset();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _selectedMinutes * 60;
    });
  }

  void _complete() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = 0;
    });

    final points = (_selectedMinutes / 10).ceil() * 5;
    final stats = ref.read(userStatsProvider);
    final updated = UserStatsModel(
      totalFocusPoints: stats.totalFocusPoints + points,
      missionsCompleted: stats.missionsCompleted + 1,
      missionsFailed: stats.missionsFailed,
      currentStreak: stats.currentStreak,
      longestStreak: stats.longestStreak,
      lastUpdateDate: stats.lastUpdateDate,
    );
    HiveBoxes.userStats.put('main', updated);

    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => _FocusCompleteDialog(
          minutes: _selectedMinutes,
          onDone: () {
            Navigator.pop(context);
            _reset();
          },
        ),
      );
    }
  }

  String get _timeDisplay {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress => 1 - _remainingSeconds / (_selectedMinutes * 60);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Stack(
        children: [
          // Animated Background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgAnimationController,
              builder: (ctx, _) => CustomPaint(
                painter: _AestheticBackgroundPainter(
                  animationValue: _bgAnimationController.value,
                  color: _hasActiveMission ? AppTheme.accentGreen : AppTheme.primaryPurple,
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40),
                      Text(
                        _hasActiveMission ? 'MISSION CONTROL' : 'FOCUS MODE',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.info_outline, color: AppTheme.textMuted, size: 20),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Main Timer Section ─────────────────────────────────────────
                Expanded(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (ctx, _) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Main Outer Glow
                            Container(
                              width: 300,
                              height: 300,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (_hasActiveMission ? AppTheme.accentGreen : AppTheme.primaryPurple)
                                        .withOpacity(0.08 + (_pulseController.value * 0.04)),
                                    blurRadius: 60,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                            ),

                            // Ring layers
                            ...List.generate(3, (i) {
                              final size = 240.0 + i * 35;
                              return Container(
                                width: size,
                                height: size,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: (_hasActiveMission ? AppTheme.accentGreen : AppTheme.primaryPurple)
                                        .withOpacity((0.12 - i * 0.04) * (0.5 + _pulseController.value * 0.5)),
                                    width: 1,
                                  ),
                                ),
                              );
                            }),

                            // The Progress Ring
                            SizedBox(
                              width: 260,
                              height: 260,
                              child: CustomPaint(
                                painter: _RingPainter(
                                  progress: _hasActiveMission ? 0.8 : _progress,
                                  color: _hasActiveMission 
                                      ? AppTheme.accentGreen 
                                      : (_isRunning ? AppTheme.primaryPurple : AppTheme.borderColor),
                                  isGlowing: _isRunning || _hasActiveMission,
                                ),
                              ),
                            ),

                            // Timer Display with Glass Effect
                            GestureDetector(
                              onTap: () async {
                                if (_hasActiveMission) {
                                  HapticFeedback.heavyImpact();
                                  final details = await PlatformChannel.getActiveMissionDetails();
                                  if (mounted && details != null) {
                                    context.push('/mission/active', extra: {
                                      'title': 'Active Mission',
                                      'category': 0,
                                      'duration': (_activeMissionRemainingSeconds / 60).ceil(),
                                      'intensity': details['intensity'] == 'hardcore' ? 2 : (details['intensity'] == 'medium' ? 1 : 0),
                                      'isResuming': true,
                                    });
                                  }
                                }
                              },
                              child: ClipOval(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    width: 220,
                                    height: 220,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.03),
                                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _hasActiveMission ? 'LOCKED' : (_isRunning ? 'FOCUSING' : 'IDLE'),
                                          style: TextStyle(
                                            color: _hasActiveMission 
                                                ? AppTheme.accentGreen 
                                                : (_isRunning ? AppTheme.primaryPurple : AppTheme.textMuted),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 6,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          _hasActiveMission 
                                              ? '${(_activeMissionRemainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_activeMissionRemainingSeconds % 60).toString().padLeft(2, '0')}'
                                              : _timeDisplay,
                                          style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 60,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -2,
                                            fontFeatures: [FontFeature.tabularFigures()],
                                          ),
                                        ),
                                        if (_hasActiveMission) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppTheme.accentGreen.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: AppTheme.accentGreen.withOpacity(0.4)),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.bolt_rounded, color: AppTheme.accentGreen, size: 14),
                                                SizedBox(width: 4),
                                                Text('MISSION LIVE', 
                                                    style: TextStyle(color: AppTheme.accentGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                // ── Bottom Controls Section ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(30, 0, 30, 40),
                  child: _hasActiveMission 
                    ? _buildActiveMissionControls()
                    : _buildStandardControls(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveMissionControls() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.security_rounded, color: AppTheme.accentGreen, size: 18),
                  SizedBox(width: 8),
                  Text('Active Shielding', 
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              const Text('Distractions are blocked globally', 
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    final details = await PlatformChannel.getActiveMissionDetails();
                    if (mounted && details != null) {
                      context.push('/mission/active', extra: {
                        'title': 'Active Mission',
                        'category': 0,
                        'duration': (_activeMissionRemainingSeconds / 60).ceil(),
                        'intensity': details['intensity'] == 'hardcore' ? 2 : (details['intensity'] == 'medium' ? 1 : 0),
                        'isResuming': true,
                      });
                    }
                  },
                  icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                  label: const Text('OPEN MISSION CENTER', style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.w900)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 10,
                    shadowColor: AppTheme.accentGreen.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStandardControls() {
    return Column(
      children: [
        if (!_isRunning) ...[
          const Text('Session Duration', 
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _presets.map((m) {
                final sel = m == _selectedMinutes;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedMinutes = m;
                        _remainingSeconds = m * 60;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: sel ? AppTheme.primaryPurple.withOpacity(0.15) : AppTheme.bgDarkCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: sel ? AppTheme.primaryPurple : AppTheme.borderColor),
                      ),
                      child: Text('${m}m', 
                          style: TextStyle(color: sel ? AppTheme.primaryPurple : AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 32),
        ],

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isRunning || _remainingSeconds < _selectedMinutes * 60) ...[
              _ControlButton(
                icon: Icons.refresh_rounded,
                label: 'RESET',
                onTap: _reset,
                color: AppTheme.textMuted,
              ),
              const SizedBox(width: 40),
            ],
            _ControlButton(
              icon: _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              label: _isRunning ? 'PAUSE' : 'START',
              onTap: _isRunning ? _pause : _start,
              color: AppTheme.primaryPurple,
              large: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool large;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = large ? 80.0 : 56.0;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(large ? 1.0 : 0.1),
              boxShadow: large
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      )
                    ]
                  : null,
              border: large ? null : Border.all(color: color.withOpacity(0.2)),
            ),
            child: Icon(icon,
                color: large ? Colors.white : color,
                size: large ? 36 : 24),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ],
      ),
    );
  }
}

class _FocusCompleteDialog extends StatelessWidget {
  final int minutes;
  final VoidCallback onDone;

  const _FocusCompleteDialog({required this.minutes, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: AppTheme.bgDarkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Text('🌟', style: TextStyle(fontSize: 40)),
              ),
              const SizedBox(height: 20),
              const Text('Focus Achieved!',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Text(
                'You stayed focused for ${minutes} minutes. Your discipline score has increased.',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onDone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('CLAIM REWARD', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isGlowing;
  _RingPainter({required this.progress, required this.color, this.isGlowing = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Background track
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, bgPaint);

    // Glow effect
    if (isGlowing) {
      final glowPaint = Paint()
        ..color = color.withOpacity(0.3)
        ..strokeWidth = 20
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -3.14 / 2,
        progress * 3.14 * 2,
        false,
        glowPaint,
      );
    }

    // Main progress arc
    final paint = Paint()
      ..color = color
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -3.14 / 2,
        endAngle: 3.14 * 2 - 3.14 / 2,
        colors: [color, color.withOpacity(0.6), color],
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
  bool shouldRepaint(_RingPainter old) => true;
}

class _AestheticBackgroundPainter extends CustomPainter {
  final double animationValue;
  final Color color;
  _AestheticBackgroundPainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.03)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);

    // Drifting glow spots
    canvas.drawCircle(
      Offset(size.width * (0.2 + 0.1 * animationValue), size.height * (0.3 + 0.05 * animationValue)),
      100,
      paint,
    );

    canvas.drawCircle(
      Offset(size.width * (0.8 - 0.1 * animationValue), size.height * (0.7 - 0.05 * animationValue)),
      150,
      paint,
    );
  }

  @override
  bool shouldRepaint(_AestheticBackgroundPainter old) => true;
}
