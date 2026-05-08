import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/hive_boxes.dart';
import '../../data/local/models/user_stats_model.dart';
import '../../data/local/models/mission_model.dart';
import '../../services/discipline_service.dart';
import '../../services/streak_service.dart';

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
  late AnimationController _ringController;
  late AnimationController _pulseController;

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
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ringController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _start() {
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
    _timer?.cancel();
    _ringController.stop();
    setState(() => _isRunning = false);
  }

  void _reset() {
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

    // ── Save Focus Data ───────────────────────────────────────────────────
    final points = (_selectedMinutes / 10).ceil() * 5; // e.g. 25 min = 15 points
    
    // Update Stats
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

    // Log as a completed mission for analytics
    final mission = MissionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Focus Session',
      category: 'Focus',
      startTime: DateTime.now().subtract(Duration(minutes: _selectedMinutes)),
      endTime: DateTime.now(),
      durationMinutes: _selectedMinutes,
      intensity: 'light',
      isCompleted: true,
      focusPointsGained: points,
    );
    HiveBoxes.missions.add(mission);
    // Show completion dialog
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

  double get _progress =>
      1 - _remainingSeconds / (_selectedMinutes * 60);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        title: const Text('Focus Mode'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),

            // ── Timer Ring ────────────────────────────────────────────────
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (ctx, _) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glow rings
                        if (_isRunning)
                          ...List.generate(3, (i) {
                            final size = 240.0 + i * 40;
                            return Container(
                              width: size,
                              height: size,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.primaryPurple.withOpacity(
                                      (0.15 - i * 0.04) *
                                          (0.5 + _pulseController.value * 0.5)),
                                  width: 1,
                                ),
                              ),
                            );
                          }),

                        // Progress ring
                        SizedBox(
                          width: 230,
                          height: 230,
                          child: AnimatedBuilder(
                            animation: _ringController,
                            builder: (ctx, _) => CustomPaint(
                              painter: _RingPainter(
                                progress: _progress,
                                color: _isRunning
                                    ? AppTheme.primaryPurple
                                    : AppTheme.borderColor,
                              ),
                            ),
                          ),
                        ),

                        // Center content
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!_isRunning && _remainingSeconds == _selectedMinutes * 60)
                              const Text('FOCUS',
                                  style: TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 12,
                                      letterSpacing: 3)),
                            if (_isRunning)
                              const Text('FOCUSING',
                                  style: TextStyle(
                                      color: AppTheme.primaryPurple,
                                      fontSize: 12,
                                      letterSpacing: 3)),
                            const SizedBox(height: 4),
                            Text(
                              _timeDisplay,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 52,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -2,
                              ),
                            ),
                            Text(
                              '$_selectedMinutes min session',
                              style: const TextStyle(
                                  color: AppTheme.textMuted, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // ── Presets ───────────────────────────────────────────────────
            if (!_isRunning)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Duration',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _presets.map((m) {
                        final sel = m == _selectedMinutes;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _selectedMinutes = m;
                            _remainingSeconds = m * 60;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppTheme.primaryPurple.withOpacity(0.2)
                                  : AppTheme.bgDarkCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: sel
                                    ? AppTheme.primaryPurple
                                    : AppTheme.borderColor,
                              ),
                            ),
                            child: Text('${m}m',
                                style: TextStyle(
                                  color: sel
                                      ? AppTheme.primaryPurple
                                      : AppTheme.textMuted,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                )),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

            // ── Controls ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 0, 40, 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (_isRunning || _remainingSeconds < _selectedMinutes * 60)
                    _ControlButton(
                      icon: Icons.refresh_rounded,
                      label: 'Reset',
                      onTap: _reset,
                      color: AppTheme.textMuted,
                    ),
                  _ControlButton(
                    icon: _isRunning
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    label: _isRunning ? 'Pause' : 'Start',
                    onTap: _isRunning ? _pause : _start,
                    color: AppTheme.primaryPurple,
                    large: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
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
    final size = large ? 72.0 : 52.0;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(large ? 1.0 : 0.12),
              boxShadow: large
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      )
                    ]
                  : null,
            ),
            child: Icon(icon,
                color: large ? Colors.white : color,
                size: large ? 32 : 22),
          ),
          const SizedBox(height: 6),
          Text(label,
              style:
                  const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
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
    return Dialog(
      backgroundColor: AppTheme.bgDarkCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text('Focus Complete!',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'You completed a ${minutes}-minute focus session.',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDone,
                child: const Text('Awesome!'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Ring painter
// ──────────────────────────────────────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Background ring
    final bgPaint = Paint()
      ..color = AppTheme.bgDarkElevated
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final paint = Paint()
      ..color = color
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -3.14 / 2,
        endAngle: 3.14 * 2 - 3.14 / 2,
        colors: [color, color.withOpacity(0.5)],
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
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
