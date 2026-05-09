import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../services/platform_channel.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _fadeController;

  final _pages = const [
    _OnboardPage(
      emoji: '🎯',
      title: 'Smart Reminders',
      subtitle:
          'Powerful reminders that demand attention. Full-screen alerts that cannot be ignored.',
      color: AppTheme.primaryPurple,
    ),
    _OnboardPage(
      emoji: '🌙',
      title: 'Sleep Protection',
      subtitle:
          'Stop endless scrolling. Auto-close YouTube and Reels when your sleep timer ends.',
      color: AppTheme.accentBlue,
    ),
    _OnboardPage(
      emoji: '🧠',
      title: 'Deep Focus',
      subtitle:
          'Block distractions. Lock in. Build the discipline habit one session at a time.',
      color: AppTheme.accentCyan,
    ),
    _OnboardPage(
      emoji: '⚙️',
      title: 'Setup Permissions',
      subtitle:
          'MINDLOCK needs these permissions to enforce your discipline. Please enable all of them for the best experience.',
      color: AppTheme.accentAmber,
      isPermissionPage: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    if (mounted) context.go('/home');
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 20, 0),
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Skip',
                      style: TextStyle(color: AppTheme.textMuted)),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (ctx, i) => _OnboardingPageWidget(
                  page: _pages[i],
                  isActive: i == _currentPage,
                ),
              ),
            ),

            // Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final active = i == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 24 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active
                        ? _pages[_currentPage].color
                        : AppTheme.textMuted,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),

            // CTA Button
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 0, 40, 32),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _pages[_currentPage].color,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    _currentPage == _pages.length - 1
                        ? "I'M READY! 🚀"
                        : 'Continue',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
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

class _OnboardPage {
  final String emoji, title, subtitle;
  final Color color;
  final bool isPermissionPage;
  const _OnboardPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    this.isPermissionPage = false,
  });
}

class _OnboardingPageWidget extends StatefulWidget {
  final _OnboardPage page;
  final bool isActive;
  const _OnboardingPageWidget({required this.page, required this.isActive});

  @override
  State<_OnboardingPageWidget> createState() => _OnboardingPageWidgetState();
}

class _OnboardingPageWidgetState extends State<_OnboardingPageWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim =
        Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));
    _fadeAnim =
        Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    if (widget.isActive) _controller.forward();
  }

  @override
  void didUpdateWidget(_OnboardingPageWidget old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // Emoji orb
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        widget.page.color.withOpacity(0.3),
                        widget.page.color.withOpacity(0.05),
                      ],
                    ),
                    border: Border.all(
                        color: widget.page.color.withOpacity(0.3), width: 1.5),
                  ),
                  child: Center(
                    child: Text(widget.page.emoji,
                        style: const TextStyle(fontSize: 48)),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  widget.page.title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.page.subtitle,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
    
                if (widget.page.isPermissionPage) ...[
                  const SizedBox(height: 24),
                  _PermissionButton(
                    icon: Icons.layers_rounded,
                    label: '1. Overlay (Always on Top)',
                    onTap: PlatformChannel.openOverlaySettings,
                  ),
                  const SizedBox(height: 10),
                  _PermissionButton(
                    icon: Icons.accessibility_new_rounded,
                    label: '2. Accessibility (Blocking)',
                    onTap: PlatformChannel.openAccessibilitySettings,
                  ),
                  const SizedBox(height: 10),
                  _PermissionButton(
                    icon: Icons.analytics_rounded,
                    label: '3. Usage Stats (Tracking)',
                    onTap: PlatformChannel.openUsageStatsSettings,
                  ),
                  const SizedBox(height: 10),
                  _PermissionButton(
                    icon: Icons.notifications_active_rounded,
                    label: '4. Notifications (Alarms)',
                    onTap: () async {
                      await PlatformChannel.setDNDMode(true); // Triggers DND/Notif permission
                    },
                  ),
                  const SizedBox(height: 10),
                  _PermissionButton(
                    icon: Icons.battery_charging_full_rounded,
                    label: '5. Battery (Background)',
                    onTap: PlatformChannel.requestBatteryOptimizationExemption,
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PermissionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PermissionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.bgDarkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryPurple, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: AppTheme.textMuted, size: 14),
          ],
        ),
      ),
    );
  }
}
