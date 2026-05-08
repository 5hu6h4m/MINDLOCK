import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../services/platform_channel.dart';
import '../../data/repositories/reminder_repository.dart';

class AlarmScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> data;
  const AlarmScreen({super.key, required this.data});

  @override
  ConsumerState<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends ConsumerState<AlarmScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    // Vibrate repeatedly for high priority
    _startVibration();
  }

  void _startVibration() async {
    final priority = widget.data['priority'] as int? ?? 1;
    if (priority >= 2) {
      for (int i = 0; i < 5; i++) {
        await PlatformChannel.vibrate(intensity: priority);
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.data['title'] ?? 'MINDLOCK REMINDER';
    final body = widget.data['body'] ?? '';
    final priority = widget.data['priority'] as int? ?? 1;
    final color = priority >= 3 ? AppTheme.accentRed : priority >= 2 ? AppTheme.accentAmber : AppTheme.primaryPurple;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Stack(
        children: [
          // Background Pulse
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      color.withOpacity(0.15 * _pulseController.value),
                      AppTheme.bgDark,
                    ],
                    radius: 1.5,
                  ),
                ),
              );
            },
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Icon with Pulse
                  ScaleTransition(
                    scale: Tween(begin: 1.0, end: 1.1).animate(_pulseController),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withOpacity(0.1),
                        border: Border.all(color: color.withOpacity(0.5), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.2),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(
                        priority >= 3 ? Icons.warning_rounded : Icons.alarm_on_rounded,
                        color: color,
                        size: 64,
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                  
                  // Text Info
                  FadeTransition(
                    opacity: _slideController,
                    child: Column(
                      children: [
                        Text(
                          title.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: color,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          body,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Action Buttons
                  FadeTransition(
                    opacity: _slideController,
                    child: Column(
                      children: [
                        _ActionButton(
                          label: 'DONE',
                          icon: Icons.check_circle_rounded,
                          color: AppTheme.accentGreen,
                          onTap: () async {
                            final id = widget.data['reminder_id']?.toString();
                            if (id != null) {
                              await ref.read(reminderRepositoryProvider).markCompleted(id);
                            }
                            if (mounted) Navigator.pop(context);
                          },
                        ),
                        const SizedBox(height: 16),
                        _ActionButton(
                          label: 'SNOOZE 10 MIN',
                          icon: Icons.snooze_rounded,
                          color: AppTheme.textSecondary,
                          onTap: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.5), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
