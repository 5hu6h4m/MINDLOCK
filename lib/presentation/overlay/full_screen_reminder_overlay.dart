import 'package:flutter/material.dart';
import 'dart:math';
import '../../core/theme/app_theme.dart';
import '../../data/local/models/reminder_model.dart';

/// Full-screen reminder overlay shown when a high-priority reminder fires.
/// This is launched as a full-screen intent from native Android.
class FullScreenReminderOverlay extends StatefulWidget {
  final ReminderModel reminder;
  final VoidCallback onDone;
  final VoidCallback onSnooze;
  final VoidCallback onIgnore;
  final VoidCallback onDelay;

  const FullScreenReminderOverlay({
    super.key,
    required this.reminder,
    required this.onDone,
    required this.onSnooze,
    required this.onIgnore,
    required this.onDelay,
  });

  @override
  State<FullScreenReminderOverlay> createState() =>
      _FullScreenReminderOverlayState();
}

class _FullScreenReminderOverlayState extends State<FullScreenReminderOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _entryController;
  late Animation<double> _scaleEntry;
  late Animation<double> _fadeEntry;

  // Strict mode math puzzle
  int _mathA = 0, _mathB = 0;
  final _answerController = TextEditingController();
  bool _mathCorrect = false;
  bool _showMathError = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _scaleEntry = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutBack),
    );
    _fadeEntry = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOut),
    );

    // Generate math puzzle for strict mode
    final rng = Random();
    _mathA = rng.nextInt(20) + 5;
    _mathB = rng.nextInt(20) + 5;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _entryController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  bool get isStrictMode => widget.reminder.isStrictMode;
  bool get isEmergency => widget.reminder.priorityIndex == 3;

  void _tryDone() {
    if (isStrictMode && !_mathCorrect) {
      // Validate math
      final answer = int.tryParse(_answerController.text.trim());
      if (answer == _mathA + _mathB) {
        setState(() => _mathCorrect = true);
        widget.onDone();
      } else {
        setState(() => _showMathError = true);
        Future.delayed(const Duration(seconds: 2),
            () => setState(() => _showMathError = false));
      }
    } else {
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = Color(widget.reminder.priority.colorValue);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Animated background
          AnimatedBuilder(
            animation: _pulseController,
            builder: (ctx, _) => Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.5,
                  colors: [
                    priorityColor
                        .withOpacity(0.15 + _pulseController.value * 0.05),
                    AppTheme.bgDark.withOpacity(0.97),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeEntry,
              child: ScaleTransition(
                scale: _scaleEntry,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // ── Status Header ─────────────────────────────────────
                      _StatusHeader(
                        priority: widget.reminder.priority.label,
                        remainingRepeats: widget.reminder.remainingRepeats,
                        repeatCount: widget.reminder.repeatCount,
                        color: priorityColor,
                        pulse: _pulseController,
                      ),

                      const Spacer(),

                      // ── Task Card ─────────────────────────────────────────
                      _TaskCard(
                        title: widget.reminder.title,
                        description: widget.reminder.description,
                        dateTime: widget.reminder.dateTime,
                        color: priorityColor,
                        pulse: _pulseController,
                      ),

                      const SizedBox(height: 40),

                      // ── Strict Mode Math ──────────────────────────────────
                      if (isStrictMode) ...[
                        _MathPuzzle(
                          a: _mathA,
                          b: _mathB,
                          controller: _answerController,
                          showError: _showMathError,
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Action Buttons ────────────────────────────────────
                      _ActionButtons(
                        onDone: _tryDone,
                        onSnooze: widget.onSnooze,
                        onDelay: widget.onDelay,
                        onIgnore: widget.onIgnore,
                        isStrictMode: isStrictMode,
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  final String priority;
  final int remainingRepeats, repeatCount;
  final Color color;
  final AnimationController pulse;

  const _StatusHeader({
    required this.priority,
    required this.remainingRepeats,
    required this.repeatCount,
    required this.color,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (ctx, _) => Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15 + pulse.value * 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: color.withOpacity(0.4 + pulse.value * 0.3)),
            ),
            child: Text(
              '${priority.toUpperCase()} PRIORITY',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (repeatCount > 1)
            Text(
              'Reminder $remainingRepeats of $repeatCount',
              style: const TextStyle(
                  color: AppTheme.textMuted, fontSize: 13),
            ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final String title, description;
  final DateTime dateTime;
  final Color color;
  final AnimationController pulse;

  const _TaskCard({
    required this.title,
    required this.description,
    required this.dateTime,
    required this.color,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (ctx, _) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppTheme.bgDarkCard,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: color.withOpacity(0.3 + pulse.value * 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15 + pulse.value * 0.1),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                description,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 15, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 20),
            // Pulsing countdown ring
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: pulse.value,
                    strokeWidth: 4,
                    backgroundColor: AppTheme.bgDarkElevated,
                    valueColor: AlwaysStoppedAnimation(color),
                    strokeCap: StrokeCap.round,
                  ),
                  Icon(Icons.alarm_rounded, color: color, size: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MathPuzzle extends StatelessWidget {
  final int a, b;
  final TextEditingController controller;
  final bool showError;

  const _MathPuzzle({
    required this.a,
    required this.b,
    required this.controller,
    required this.showError,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgDarkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: showError
              ? AppTheme.accentRed
              : AppTheme.accentAmber.withOpacity(0.4),
        ),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.lock_rounded,
                  color: AppTheme.accentAmber, size: 16),
              SizedBox(width: 6),
              Text('Strict Mode: Solve to dismiss',
                  style: TextStyle(
                      color: AppTheme.accentAmber,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$a + $b = ?',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Answer',
              errorText: showError ? 'Wrong answer, try again' : null,
              errorStyle: const TextStyle(color: AppTheme.accentRed),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final VoidCallback onDone, onSnooze, onDelay, onIgnore;
  final bool isStrictMode;

  const _ActionButtons({
    required this.onDone,
    required this.onSnooze,
    required this.onDelay,
    required this.onIgnore,
    required this.isStrictMode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Done button (primary)
        SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton.icon(
            onPressed: onDone,
            icon: const Icon(Icons.check_rounded, size: 22),
            label: Text(
              isStrictMode ? 'Submit & Mark Done' : '✅ Done — Task Completed',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGreen,
              foregroundColor: Colors.white,
              shadowColor: AppTheme.accentGreen.withOpacity(0.5),
              elevation: 12,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onSnooze,
                icon: const Icon(Icons.snooze_rounded, size: 16),
                label: const Text('Snooze 10m'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.accentAmber,
                  side: BorderSide(
                      color: AppTheme.accentAmber.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDelay,
                icon: const Icon(Icons.schedule_rounded, size: 16),
                label: const Text('Delay 30m'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.accentBlue,
                  side: BorderSide(
                      color: AppTheme.accentBlue.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: isStrictMode ? null : onIgnore,
            icon: Icon(Icons.close_rounded,
                color: isStrictMode
                    ? AppTheme.textMuted
                    : AppTheme.accentRed,
                size: 16),
            label: Text(
              isStrictMode ? 'Cannot ignore in strict mode' : 'Ignore',
              style: TextStyle(
                color: isStrictMode
                    ? AppTheme.textMuted
                    : AppTheme.accentRed,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
