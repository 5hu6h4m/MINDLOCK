import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = [
    _TabItem(icon: Icons.home_rounded, label: 'Home', path: '/home'),
    _TabItem(icon: Icons.notifications_rounded, label: 'Reminders', path: '/reminders'),
    _TabItem(icon: Icons.center_focus_strong_rounded, label: 'Focus', path: '/focus'),
    _TabItem(icon: Icons.history_edu_rounded, label: 'Journal', path: '/journal'),
    _TabItem(icon: Icons.settings_rounded, label: 'Settings', path: '/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _tabs.indexWhere((t) => location.startsWith(t.path));

    return Scaffold(
      body: child,
      bottomNavigationBar: _FloatingNavBar(
        currentIndex: currentIndex < 0 ? 0 : currentIndex,
        tabs: _tabs,
        onTap: (i) => context.go(_tabs[i].path),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  final String path;
  const _TabItem({required this.icon, required this.label, required this.path});
}

class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final List<_TabItem> tabs;
  final ValueChanged<int> onTap;

  const _FloatingNavBar({
    required this.currentIndex,
    required this.tabs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.bgDarkSurface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.borderColor, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(tabs.length, (i) {
            final selected = i == currentIndex;
            return GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: selected
                    ? BoxDecoration(
                        color: AppTheme.primaryPurple.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppTheme.primaryPurple.withOpacity(0.3),
                          width: 0.5,
                        ),
                      )
                    : null,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedScale(
                      scale: selected ? 1.15 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        tabs[i].icon,
                        color: selected
                            ? AppTheme.primaryPurple
                            : AppTheme.textMuted,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 3),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        color: selected ? AppTheme.primaryPurple : AppTheme.textMuted,
                      ),
                      child: Text(tabs[i].label),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
