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
  int _selectedSeconds = 30 * 60;
  int _remainingSeconds = 0;
  bool _isActive = false;
  Timer? _refreshTimer;
  late AnimationController _pulseController;

  final List<Map<String, dynamic>> _presets = [
    {'label': '10s', 'seconds': 10},
    {'label': '30s', 'seconds': 30},
    {'label': '5m', 'seconds': 5 * 60},
    {'label': '15m', 'seconds': 15 * 60},
    {'label': '30m', 'seconds': 30 * 60},
    {'label': '1h', 'seconds': 60 * 60},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);
    
    _checkExistingTimer();
  }

  Future<void> _checkExistingTimer() async {
    final remaining = await PlatformChannel.getRemainingSleepTime();
    if (remaining > 0) {
      setState(() {
        _isActive = true;
        _remainingSeconds = remaining;
      });
      _startRefreshTimer();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final remaining = await PlatformChannel.getRemainingSleepTime();
      if (remaining <= 0) {
        _stopLocal();
      } else {
        setState(() => _remainingSeconds = remaining);
      }
    });
  }

  void _stopLocal() {
    _refreshTimer?.cancel();
    setState(() {
      _isActive = false;
      _remainingSeconds = 0;
    });
  }

  Future<void> _start() async {
    // Send seconds to native
    await PlatformChannel.startSleepTimerSeconds(_selectedSeconds);
    setState(() {
      _isActive = true;
      _remainingSeconds = _selectedSeconds;
    });
    _startRefreshTimer();
  }

  Future<void> _stop() async {
    await PlatformChannel.stopSleepTimer();
    _stopLocal();
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
                          'REMAINING',
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
                    'Aggressive Sleep Timer is Active.\nScreen will lock and apps will close.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.6),
                  ),
                ] else ...[
                  const Text(
                    'Brutal Sleep Timer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Kills media, clears screen, and locks phone.',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  const SizedBox(height: 60),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      alignment: WrapAlignment.center,
                      children: _presets.map((p) {
                        final isSelected = p['seconds'] == _selectedSeconds;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _selectedSeconds = p['seconds'] as int;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 75,
                            height: 75,
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primaryPurple : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? AppTheme.primaryPurple : Colors.white10,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              p['label'] as String,
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
                        _isActive ? 'CANCEL TIMER' : 'START BRUTAL SLEEP',
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
