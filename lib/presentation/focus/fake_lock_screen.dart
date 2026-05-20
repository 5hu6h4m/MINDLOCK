import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class FakeLockScreen extends StatefulWidget {
  const FakeLockScreen({super.key});

  @override
  State<FakeLockScreen> createState() => _FakeLockScreenState();
}

class _FakeLockScreenState extends State<FakeLockScreen>
    with TickerProviderStateMixin {
  // Lock state
  bool _isLockActive = false;
  int _selectedHours = 3;
  int _remainingSeconds = 3 * 3600;
  Timer? _countdownTimer;

  // Animation Controllers
  late AnimationController _pulseController;
  late AnimationController _scannerController;
  late AnimationController _bgFloatController;

  // Secret Bypass States
  int _shieldTaps = 0;
  Timer? _tapResetTimer;
  bool _showPinSheet = false;
  final List<int> _enteredPin = [];
  String _pinErrorMessage = '';

  // Call Logs & Phone Simulator state
  bool _showDialer = false;
  final String _dialerInput = '';
  final List<Map<String, String>> _mockCallLogs = [
    {'name': 'Mom 🧑‍🍼', 'time': '2 mins ago', 'type': 'incoming'},
    {'name': 'Dad 👨', 'time': '18 mins ago', 'type': 'outgoing'},
    {'name': 'Math Professor 📚', 'time': '1 hour ago', 'type': 'missed'},
    {'name': 'Principal Office 🏫', 'time': '2 hours ago', 'type': 'incoming'},
    {'name': 'Study Coach 🧠', 'time': '4 hours ago', 'type': 'outgoing'},
  ];

  @override
  void initState() {
    super.initState();
    // Pulse animation for the lock shield icon
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Tech scanner light animation
    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Drifting background animation
    _bgFloatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _tapResetTimer?.cancel();
    _pulseController.dispose();
    _scannerController.dispose();
    _bgFloatController.dispose();
    super.dispose();
  }

  void _startLockdown() {
    HapticFeedback.heavyImpact();
    setState(() {
      _remainingSeconds = _selectedHours * 3600;
      _isLockActive = true;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        _unlockComplete();
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  void _unlockComplete() {
    _countdownTimer?.cancel();
    setState(() {
      _isLockActive = false;
    });
    HapticFeedback.vibrate();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildSuccessDialog(),
    );
  }

  // Warning when trying to close screen normally
  Future<bool> _handlePopAttempt() async {
    HapticFeedback.heavyImpact();
    _showWarningDialog();
    return false; // Prevent back gesture
  }

  void _showWarningDialog() {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: AppTheme.bgDarkCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: const BorderSide(color: AppTheme.accentRed, width: 1.5),
          ),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: AppTheme.accentRed, size: 28),
              SizedBox(width: 10),
              Text(
                'CRITICAL SYSTEM LOCK',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '⚠️ Active Lock Restriction Enforced',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'This device is operating under extreme Study Mode isolation. All background data connections, applications, and system operations are strictly suspended to ensure focus. No tools or databases will run, and absolutely no apps can be opened except for Calls and Call Logs, until the countdown timer reaches zero.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.accentRed,
              ),
              child: const Text(
                'DISMISS WARNING',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Handle Shield Icon Tap - Secret Bypass Trigger
  void _onShieldTap() {
    HapticFeedback.selectionClick();
    _shieldTaps++;

    _tapResetTimer?.cancel();
    _tapResetTimer = Timer(const Duration(seconds: 3), () {
      _shieldTaps = 0; // Reset tap count if 3s delay
    });

    if (_shieldTaps >= 5) {
      HapticFeedback.doubleTap();
      setState(() {
        _shieldTaps = 0;
        _showPinSheet = true;
        _enteredPin.clear();
        _pinErrorMessage = '';
      });
    }
  }

  // Handle PIN Number pad click
  void _onPinKeypress(int val) {
    if (_enteredPin.length >= 4) return;
    HapticFeedback.lightImpact();
    setState(() {
      _enteredPin.add(val);
      _pinErrorMessage = '';
    });

    if (_enteredPin.length == 4) {
      // Validate PIN
      final pinStr = _enteredPin.join();
      if (pinStr == '1234' || pinStr == '9999' || pinStr == '2026') {
        HapticFeedback.mediumImpact();
        setState(() {
          _showPinSheet = false;
          _isLockActive = false;
        });
        _countdownTimer?.cancel();
        context.go('/home');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ STRICT STUDY LOCK BYPASSED SUCCESSFULLY!'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      } else {
        HapticFeedback.vibrate();
        setState(() {
          _enteredPin.clear();
          _pinErrorMessage = 'ACCESS DENIED: INVALID BYPASS CODE';
        });
      }
    }
  }

  void _clearPin() {
    HapticFeedback.selectionClick();
    setState(() {
      _enteredPin.clear();
      _pinErrorMessage = '';
    });
  }

  String get _timeDisplay {
    final h = _remainingSeconds ~/ 3600;
    final m = (_remainingSeconds % 3600) ~/ 60;
    final s = _remainingSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress => _remainingSeconds / (_selectedHours * 3600);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handlePopAttempt,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // ── Background Particle Drift ──
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _bgFloatController,
                builder: (ctx, _) {
                  return CustomPaint(
                    painter: _LockBackgroundPainter(
                      animValue: _bgFloatController.value,
                      glowColor: _isLockActive ? AppTheme.accentRed : AppTheme.primaryPurple,
                    ),
                  );
                },
              ),
            ),

            // ── Tech grid alignment ──
            Positioned.fill(
              child: Opacity(
                opacity: 0.03,
                child: Image.network(
                  'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=500', // Safe abstract texture
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(),
                ),
              ),
            ),

            // ── Main UI Layout ──
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    // Header Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isLockActive ? AppTheme.accentRed : AppTheme.accentGreen,
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isLockActive ? AppTheme.accentRed : AppTheme.accentGreen).withOpacity(0.5),
                                    blurRadius: 6,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isLockActive ? 'STRICT LOCKDOWN ACTIVE' : 'SECURE STUDY SHELL',
                              style: TextStyle(
                                color: _isLockActive ? AppTheme.accentRed : AppTheme.accentGreen,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                        if (_isLockActive)
                          GestureDetector(
                            onTap: _handlePopAttempt,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.accentRed.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.accentRed.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.lock_open_rounded, color: AppTheme.accentRed, size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    'EXIT LOCK',
                                    style: TextStyle(color: AppTheme.accentRed, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Main Shell Body
                    Expanded(
                      child: AnimatedCrossFade(
                        duration: const Duration(milliseconds: 500),
                        firstChild: _buildSelectorView(),
                        secondChild: _buildLockdownTimerView(),
                        crossFadeState: _isLockActive
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Secret Bypass Keyboard Overlay ──
            if (_showPinSheet) _buildSecretPinOverlay(),

            // ── Fake Call Logs & Dialer Overlay ──
            if (_showDialer) _buildSimulatedDialerOverlay(),
          ],
        ),
      ),
    );
  }

  // 1. Selector view before Lock starts
  Widget _buildSelectorView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Giant Locking Glass Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: GlassDecoration.build(
            opacity: 0.05,
            borderRadius: 32,
            borderColor: AppTheme.primaryPurple.withOpacity(0.2),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.3)),
                ),
                child: const Icon(
                  Icons.lock_person_rounded,
                  color: AppTheme.primaryPurple,
                  size: 48,
                  shadows: [
                    Shadow(color: AppTheme.primaryPurple, blurRadius: 20),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Strict Study Lock',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
              ),
              const SizedBox(height: 8),
              const Text(
                'Show off extreme study mode to friends. This mimics a full device lockout allowing only telephone services.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Picker Hours
              const Text(
                'CHOOSE LOCK TIMEOUT',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [1, 2, 3, 4].map((hrs) {
                  final sel = hrs == _selectedHours;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedHours = hrs);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: sel ? AppTheme.primaryPurple.withOpacity(0.2) : AppTheme.bgDarkElevated.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: sel ? AppTheme.primaryPurple : AppTheme.borderColor,
                            width: sel ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          '$hrs Hrs',
                          style: TextStyle(
                            color: sel ? Colors.white : AppTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Launch strict mode button
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton.icon(
            onPressed: _startLockdown,
            icon: const Icon(Icons.security_rounded, size: 20),
            label: const Text(
              'ACTIVATE ENFORCED MODE',
              style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.w900, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
              shadowColor: AppTheme.primaryPurple.withOpacity(0.5),
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => context.go('/home'),
          child: Text(
            'CANCEL AND RETREAT',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  // 2. Main active lockdown view
  Widget _buildLockdownTimerView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Floating circular neon countdown
        AnimatedBuilder(
          animation: _pulseController,
          builder: (ctx, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Soft background radial aura
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentRed.withOpacity(0.05 + (_pulseController.value * 0.05)),
                        blurRadius: 50,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),

                // Triple futuristic radar rings
                ...List.generate(3, (i) {
                  final size = 210.0 + i * 25;
                  return Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.accentRed.withOpacity((0.1 - i * 0.03) * (0.5 + _pulseController.value * 0.5)),
                        width: 1,
                      ),
                    ),
                  );
                }),

                // Interactive Shield lock (Main tap bypass detector)
                GestureDetector(
                  onTap: _onShieldTap,
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        width: 190,
                        height: 190,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.3),
                          border: Border.all(
                            color: AppTheme.accentRed.withOpacity(0.2 + _pulseController.value * 0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ScaleTransition(
                              scale: Tween<double>(begin: 0.9, end: 1.1).animate(
                                CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                              ),
                              child: const Icon(
                                Icons.shield_rounded,
                                color: AppTheme.accentRed,
                                size: 36,
                                shadows: [
                                  Shadow(color: AppTheme.accentRed, blurRadius: 15),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _timeDisplay,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'REMAINING',
                              style: TextStyle(
                                color: AppTheme.accentRed.withOpacity(0.7),
                                fontSize: 9,
                                letterSpacing: 2,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Radial sweep indicator
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 4,
                    backgroundColor: Colors.white.withOpacity(0.03),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentRed),
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 40),

        // Grid indicators of lock properties
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: GlassDecoration.build(
            borderRadius: 24,
            opacity: 0.03,
            borderColor: Colors.white.withOpacity(0.06),
          ),
          child: Column(
            children: [
              _buildStatusRow(Icons.wifi_off_rounded, 'Wi-Fi Network Enforced', 'SUSPENDED', AppTheme.accentRed),
              const Divider(color: Colors.white10, height: 20),
              _buildStatusRow(Icons.signal_cellular_connected_no_internet_4_bar_rounded, 'Mobile Cellular Data', 'RESTRICTED', AppTheme.accentRed),
              const Divider(color: Colors.white10, height: 20),
              _buildStatusRow(Icons.phonelink_lock_rounded, 'Background Processes', 'BLOCKED (87 APPS)', AppTheme.accentAmber),
              const Divider(color: Colors.white10, height: 20),
              _buildStatusRow(Icons.call_rounded, 'Voice Communications', 'EMERGENCY ONLY', AppTheme.accentGreen),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Phone call simulator launcher
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              setState(() => _showDialer = true);
            },
            icon: const Icon(Icons.dialpad_rounded, size: 20),
            label: const Text(
              'OPEN DIALER & CALL LOGS',
              style: TextStyle(letterSpacing: 1, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGreen,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),

        const SizedBox(height: 16),
        Text(
          'Double-tap & Hold Lock Shield for Bypass Support',
          style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildStatusRow(IconData icon, String title, String value, Color statusColor) {
    return Row(
      children: [
        Icon(icon, color: Colors.white60, size: 20),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          value,
          style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
        ),
      ],
    );
  }

  // 3. Secret Bypass Overlay (Hidden Keypad)
  Widget _buildSecretPinOverlay() {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          color: Colors.black.withOpacity(0.85),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: AppTheme.primaryPurple,
                  size: 48,
                  shadows: [Shadow(color: AppTheme.primaryPurple, blurRadius: 20)],
                ),
                const SizedBox(height: 16),
                const Text(
                  'SECURITY BYPASS PANELS',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
                const SizedBox(height: 8),
                Text(
                  'ENTER STRICT ACCESS CODE TO TERMINATE SHELL',
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, letterSpacing: 1),
                ),
                const SizedBox(height: 32),

                // PIN bubble displays
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isFilled = index < _enteredPin.length;
                    return Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFilled ? AppTheme.primaryPurple : Colors.transparent,
                        border: Border.all(
                          color: isFilled ? AppTheme.primaryPurple : Colors.white24,
                          width: 1.5,
                        ),
                        boxShadow: isFilled
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryPurple.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                              ]
                            : [],
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 16),

                // Error Message
                if (_pinErrorMessage.isNotEmpty)
                  Text(
                    _pinErrorMessage,
                    style: const TextStyle(color: AppTheme.accentRed, fontSize: 11, fontWeight: FontWeight.bold),
                  ),

                const SizedBox(height: 40),

                // Lock numbers keypad grid
                Container(
                  width: 280,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.1,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                    ),
                    itemCount: 12,
                    itemBuilder: (ctx, idx) {
                      if (idx == 9) {
                        return GestureDetector(
                          onTap: _clearPin,
                          child: Container(
                            alignment: Alignment.center,
                            child: const Text('CLEAR', style: TextStyle(color: AppTheme.accentRed, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        );
                      }
                      if (idx == 11) {
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _showPinSheet = false);
                          },
                          child: Container(
                            alignment: Alignment.center,
                            child: const Text('CLOSE', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        );
                      }
                      final num = idx == 10 ? 0 : idx + 1;
                      return GestureDetector(
                        onTap: () => _onPinKeypress(num),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.04),
                            border: Border.all(color: Colors.white10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$num',
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 4. Simulated Dialer & Phone Overlay
  Widget _buildSimulatedDialerOverlay() {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          color: Colors.black.withOpacity(0.92),
          child: SafeArea(
            child: Column(
              children: [
                // Top control bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.call_rounded, color: AppTheme.accentGreen, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'EMERGENCY DIALER',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() => _showDialer = false);
                        },
                        icon: const Icon(Icons.close_rounded, color: Colors.white60),
                      ),
                    ],
                  ),
                ),

                // Call logs list
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: _mockCallLogs.length,
                    separatorBuilder: (c, i) => const Divider(color: Colors.white10, height: 1),
                    itemBuilder: (ctx, index) {
                      final item = _mockCallLogs[index];
                      Color callTypeColor = Colors.white54;
                      IconData callTypeIcon = Icons.call_received_rounded;

                      if (item['type'] == 'outgoing') {
                        callTypeColor = AppTheme.accentCyan;
                        callTypeIcon = Icons.call_made_rounded;
                      } else if (item['type'] == 'missed') {
                        callTypeColor = AppTheme.accentRed;
                        callTypeIcon = Icons.call_missed_rounded;
                      }

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(callTypeIcon, color: callTypeColor, size: 16),
                        ),
                        title: Text(
                          item['name']!,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: Text(
                          item['time']!,
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                        trailing: IconButton(
                          onPressed: () {
                            HapticFeedback.heavyImpact();
                            _simulateFakeCall(item['name']!);
                          },
                          icon: const Icon(Icons.phone_rounded, color: AppTheme.accentGreen, size: 20),
                        ),
                      );
                    },
                  ),
                ),

                // Warning Footer
                Container(
                  padding: const EdgeInsets.all(20),
                  color: AppTheme.bgDarkElevated.withOpacity(0.3),
                  child: Row(
                    children: const [
                      Icon(Icons.lock_rounded, color: AppTheme.accentAmber, size: 16),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'SECURITY NOTICE: Only pre-authorized contacts and emergency lines are connectable during active Study Enforcements.',
                          style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _simulateFakeCall(String name) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Scaffold(
          backgroundColor: const Color(0xFF0F1E19), // Dark telephone green tone
          body: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.03),
                  ),
                  child: const Icon(Icons.person_rounded, size: 80, color: Colors.white30),
                ),
                const SizedBox(height: 24),
                Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'DIALING SECURE CONNECT...',
                  style: TextStyle(color: AppTheme.accentGreen, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.w900),
                ),
                const Spacer(),

                // End call button
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.accentRed,
                    ),
                    child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 32),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('END CALL', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuccessDialog() {
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
                child: const Text('🎓', style: TextStyle(fontSize: 40)),
              ),
              const SizedBox(height: 20),
              const Text(
                'Lockdown Finished!',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              const Text(
                'Congratulations! You stayed fully isolated and focused. Your mind locking stats have reached the next level.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/home');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('RETURN TO BASE', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Drifting grid background painter
class _LockBackgroundPainter extends CustomPainter {
  final double animValue;
  final Color glowColor;

  _LockBackgroundPainter({required this.animValue, required this.glowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = glowColor.withOpacity(0.015)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);

    // Drifting background light spots
    canvas.drawCircle(
      Offset(
        size.width * (0.3 + 0.1 * math.sin(animValue * 2 * math.pi)),
        size.height * (0.2 + 0.1 * math.cos(animValue * 2 * math.pi)),
      ),
      120,
      paint,
    );

    canvas.drawCircle(
      Offset(
        size.width * (0.7 + 0.15 * math.cos(animValue * 2 * math.pi)),
        size.height * (0.8 + 0.08 * math.sin(animValue * 2 * math.pi)),
      ),
      160,
      paint,
    );
  }

  @override
  bool shouldRepaint(_LockBackgroundPainter oldDelegate) => true;
}

