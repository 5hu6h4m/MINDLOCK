import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../services/platform_channel.dart';

class SleepScreen extends ConsumerStatefulWidget {
  const SleepScreen({super.key});
  @override
  ConsumerState<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends ConsumerState<SleepScreen> {
  int _selectedMinutes = 30;
  int _remainingSeconds = 30 * 60;
  bool _isActive = false;
  Timer? _timer;

  final _presets = [10, 20, 30, 45, 60];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _isActive = true;
      _remainingSeconds = _selectedMinutes * 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds <= 0) {
        _stop();
        _showSilentWarning();
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  void _stop() {
    _timer?.cancel();
    setState(() {
      _isActive = false;
      _remainingSeconds = _selectedMinutes * 60;
    });
  }

  void _showSilentWarning() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _SilentWarningDialog(),
    );
  }

  String get _timeDisplay {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        title: const Text('Media Sleep Timer', style: TextStyle(letterSpacing: 0.5)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          physics: const BouncingScrollPhysics(),
          children: [
            const Text(
              'TIMER',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),

            if (_isActive)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.bgDarkCard,
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    Text(
                      _timeDisplay,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 64,
                        fontWeight: FontWeight.w300,
                        letterSpacing: -2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('REMAINING', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, letterSpacing: 2)),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _stop,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textPrimary,
                          side: const BorderSide(color: AppTheme.borderColor),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        child: const Text('CANCEL TIMER', style: TextStyle(letterSpacing: 1)),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.bgDarkCard,
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Duration', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    const Text('Music and background media will be stopped when the timer ends.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.5)),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _presets.map((m) {
                        final sel = m == _selectedMinutes;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _selectedMinutes = m;
                            _remainingSeconds = m * 60;
                          }),
                          child: Container(
                            width: 60,
                            height: 60,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: sel ? AppTheme.textPrimary : AppTheme.bgDarkElevated,
                              border: Border.all(color: sel ? AppTheme.textPrimary : AppTheme.borderColor),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '$m',
                              style: TextStyle(
                                color: sel ? AppTheme.bgDark : AppTheme.textSecondary,
                                fontSize: 20,
                                fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _start,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.textPrimary,
                          foregroundColor: AppTheme.bgDark,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        child: const Text('START SLEEP TIMER', style: TextStyle(letterSpacing: 1, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SilentWarningDialog extends StatefulWidget {
  const _SilentWarningDialog();

  @override
  State<_SilentWarningDialog> createState() => _SilentWarningDialogState();
}

class _SilentWarningDialogState extends State<_SilentWarningDialog> {
  int _secondsLeft = 10;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        _timer?.cancel();
        _killBackgroundMedia();
        if (mounted) Navigator.pop(context);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _killBackgroundMedia() async {
    try {
      await PlatformChannel.pauseMedia();
      await PlatformChannel.lockScreen();
    } catch (e) {
      debugPrint('Failed to kill media: \$e');
    }
  }

  void _cancelKill() {
    _timer?.cancel();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: GestureDetector(
        onTap: _cancelKill,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppTheme.bgDarkCard,
            border: Border.all(color: AppTheme.borderColor, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bedtime_outlined, color: AppTheme.textMuted, size: 48),
              const SizedBox(height: 24),
              const Text(
                'SLEEP TIMER ENDED',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '$_secondsLeft',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 72,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tap anywhere to stay awake',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
