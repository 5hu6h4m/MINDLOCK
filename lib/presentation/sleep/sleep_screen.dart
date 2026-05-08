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

class _SleepScreenState extends ConsumerState<SleepScreen> with TickerProviderStateMixin {
  int _selectedMinutes = 30;
  int _remainingSeconds = 30 * 60;
  bool _isActive = false;
  Timer? _timer;
  late AnimationController _pulseController;

  final _presets = [5, 15, 30, 45, 60, 90];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _start() {
    setState(() {
      _isActive = true;
      _remainingSeconds = _selectedMinutes * 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds <= 0) {
        _onTimerEnd();
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  Future<void> _onTimerEnd() async {
    _timer?.cancel();
    setState(() {
      _isActive = false;
      _remainingSeconds = _selectedMinutes * 60;
    });

    // Aggressive Kill: Stop media and go to Home
    // DND is NOT used as per user request to allow calls.
    await PlatformChannel.pauseMedia();
    await PlatformChannel.goHome();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sleep Timer Ended: Media Stopped 🛌'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _stop() {
    _timer?.cancel();
    setState(() {
      _isActive = false;
      _remainingSeconds = _selectedMinutes * 60;
    });
  }

  String get _timeDisplay {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      body: Stack(
        children: [
          // Ambient Pulse Background
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF1A237E).withOpacity(0.1 * _pulseController.value),
                      const Color(0xFF020408),
                    ],
                    radius: 1.5,
                  ),
                ),
              );
            },
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      ),
                      const Spacer(),
                      const Icon(Icons.timer_outlined, color: AppTheme.primaryPurple, size: 24),
                    ],
                  ),
                ),

                const Spacer(),

                if (_isActive) ...[
                  // Active Timer
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.2), width: 1),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _timeDisplay,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 64,
                            fontWeight: FontWeight.w200,
                          ),
                        ),
                        const Text(
                          'UNTIL SLEEP',
                          style: TextStyle(
                            color: AppTheme.primaryPurple,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Enjoy your media.\nApps will close when time is up.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 14, height: 1.6),
                  ),
                ] else ...[
                  const Text(
                    'Media Sleep Timer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Auto-stop apps and music when you sleep.',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  const SizedBox(height: 60),
                  
                  // Presets
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      alignment: WrapAlignment.center,
                      children: _presets.map((m) {
                        final isSelected = m == _selectedMinutes;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _selectedMinutes = m;
                            _remainingSeconds = m * 60;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primaryPurple : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? AppTheme.primaryPurple : Colors.white10,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$m',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w400,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                const Spacer(),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
                  child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isActive ? _stop : _start,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isActive ? Colors.white.withOpacity(0.05) : AppTheme.primaryPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      child: Text(
                        _isActive ? 'CANCEL TIMER' : 'START TIMER',
                        style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
