import 'dart:ui';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/enums.dart';
import '../../data/repositories/reminder_repository.dart';
import '../../data/local/models/reminder_model.dart';
import '../../data/local/models/suggestion_model.dart';
import '../../services/ai_suggestion_service.dart';
import '../../services/discipline_service.dart';
import '../../services/streak_service.dart';
import '../../services/platform_channel.dart';
import '../../core/providers/settings_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/streak_service.dart';
import '../../services/charging_service.dart';
import './widgets/charging_stats_card.dart';
import '../overlay/charging_animation_overlay.dart';

final aiSuggestionProvider = Provider<SuggestionModel>((ref) {
  final service = ref.watch(aiSuggestionServiceProvider);
  return service.getContextualSuggestion();
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _greetingController;
  late AnimationController _cardsController;

  @override
  void initState() {
    super.initState();
    _greetingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _cardsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    _checkDisclosure();
    _checkPermissions();
    _initDailyReflection();
    _initChargingListener();
  }

  void _initChargingListener() {
    // We can't listen to Provider inside initState easily without ref.
    // So we use a PostFrameCallback or just use the build method's ref.listen
  }

  Future<void> _checkDisclosure() async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool('disclosure_accepted') ?? false;
    if (!accepted) {
      if (mounted) _showDisclosureDialog();
    }
  }

  void _showDisclosureDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: AppTheme.bgDarkCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Icon(Icons.security_rounded, color: AppTheme.primaryPurple),
                SizedBox(width: 10),
                Text('Privacy & Safety', style: TextStyle(color: Colors.white)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MindLock requires specific permissions to help you maintain digital discipline:',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _DisclosureItem(
                    icon: Icons.accessibility_new_rounded,
                    title: 'Accessibility Service',
                    desc: 'Used to detect and block distracting apps during Mission Mode and Anti-Scroll sessions. We do not collect or share any data.',
                  ),
                  const SizedBox(height: 12),
                  _DisclosureItem(
                    icon: Icons.admin_panel_settings_rounded,
                    title: 'Device Administrator',
                    desc: 'Used to lock your screen during Deep Sleep sessions to prevent midnight dopamine loops.',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your data stays on your device unless you manually enable Cloud Sync. We never sell your data.',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('disclosure_accepted', true);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('I UNDERSTAND', style: TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _initDailyReflection() {
    PlatformChannel.scheduleDailyReflection();
  }

  bool _showPermissionBanner = false;

  Future<void> _checkPermissions() async {
    // Check for Exact Alarm permission on Android 12+
    if (await Permission.scheduleExactAlarm.isDenied) {
      setState(() => _showPermissionBanner = true);
    }
  }

  @override
  void dispose() {
    _greetingController.dispose();
    _cardsController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'Late night 🌙';
    if (hour < 12) return 'Good morning ☀️';
    if (hour < 17) return 'Good afternoon 🌤️';
    if (hour < 21) return 'Good evening 🌆';
    return 'Good night 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(reminderRepositoryProvider);
    final todayReminders = repo.getToday();
    final pendingReminders = repo.getPending();
    final emergencyReminders = repo.getEmergency();
    final completedToday = repo.totalCompleted;

    // Listen for charging connection to show overlay
    ref.listen(chargingProvider, (previous, next) {
      if (next.isCharging && (previous == null || !previous.isCharging)) {
        _showChargingOverlay(next);
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryPurple,
          backgroundColor: AppTheme.bgDarkCard,
          onRefresh: () async => setState(() {}),
          child: FadeTransition(
            opacity: _cardsController,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
              // ── App Bar ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _buildHeader(),
                ),
              ),

              // ── Permission Banner ─────────────────────────────────────────
              if (_showPermissionBanner)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _PermissionBanner(),
                  ),
                ),

              // ── Emergency Banner ─────────────────────────────────────────
              if (emergencyReminders.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _EmergencyBanner(reminders: emergencyReminders),
                ),
              ),

            // ── Charging Stats ───────────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: ChargingStatsCard(),
              ),
            ),

            // ── Discipline Meter ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Consumer(
                    builder: (context, ref, child) {
                      final discipline = ref.watch(disciplineServiceProvider);
                      final score = discipline.calculateDailyScore(DateTime.now());
                      final pct = (score * 100).toInt();
                      
                      return AnimatedScale(
                        duration: const Duration(milliseconds: 600),
                        scale: _cardsController.value,
                        curve: Curves.easeOutBack,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryPurple.withOpacity(0.2),
                              AppTheme.accentBlue.withOpacity(0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: CircularProgressIndicator(
                                    value: score,
                                    strokeWidth: 8,
                                    backgroundColor: AppTheme.bgDarkElevated,
                                    valueColor: AlwaysStoppedAnimation(
                                      pct >= 80 ? AppTheme.accentGreen : AppTheme.primaryPurple
                                    ),
                                  ),
                                ),
                                Text(
                                  '$pct%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    discipline.getDisciplineLabel(score),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700
                                    )
                                  ),
                                  const SizedBox(height: 4),
                                  const Text('Stay consistent to reach 100%',
                                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12)
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                    },
                  ),
                ),
              ),

              // ── AI Suggestion ──────────────────────────────────────────────
              _AISuggestionSliver(),

              // ── Quick Actions ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.textPrimary,
                        ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: _QuickActionsGrid(),
                ),
              ),

              // ── Today's Tasks ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Today's Tasks",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.textPrimary,
                            ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/reminders'),
                        child: const Text('See all',
                            style: TextStyle(color: AppTheme.primaryPurple)),
                      ),
                    ],
                  ),
                ),
              ),

              if (todayReminders.isEmpty)
                SliverToBoxAdapter(child: _EmptyState())
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: _ReminderCard(
                        reminder: todayReminders[i],
                        index: i,
                        onDone: () async {
                          await ref
                              .read(reminderRepositoryProvider)
                              .markCompleted(todayReminders[i].id);
                          setState(() {});
                        },
                      ),
                    ),
                    childCount: todayReminders.length,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      ),

      // ── FAB ────────────────────────────────────────────────────────────────
      floatingActionButton: _PremiumFAB(
        onTap: () => context.push('/reminders/create'),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _greetingController,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text(
                      'MINDLOCK',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Consumer(
                      builder: (context, ref, _) {
                        final stats = ref.watch(userStatsProvider);
                        if (stats.currentStreak == 0) return const SizedBox();
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentAmber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.accentAmber.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.local_fire_department_rounded, 
                                  color: AppTheme.accentAmber, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${stats.currentStreak}',
                                style: const TextStyle(
                                  color: AppTheme.accentAmber,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                Text(
                  DateFormat('EEEE, d MMMM').format(DateTime.now()),
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // App Logo
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.bgDarkElevated,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryPurple.withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: const Icon(Icons.center_focus_strong_rounded, color: AppTheme.primaryPurple, size: 28),
          ),
        ],
      ),
    );
  }
  void _showChargingOverlay(BatteryState battery) {
    String speed = "Charging";
    if (battery.speed == ChargingSpeed.ultra) speed = "Ultra Super Charge";
    else if (battery.speed == ChargingSpeed.fast) speed = "Fast Charging";

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return ChargingAnimationOverlay(
          level: battery.level,
          speedType: speed,
          onDismiss: () => Navigator.pop(context),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Emergency Banner
// ──────────────────────────────────────────────────────────────────────────────
class _EmergencyBanner extends StatefulWidget {
  final List<ReminderModel> reminders;
  const _EmergencyBanner({required this.reminders});

  @override
  State<_EmergencyBanner> createState() => _EmergencyBannerState();
}

class _EmergencyBannerState extends State<_EmergencyBanner> {
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.reminders.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (mounted) {
          setState(() => _currentIndex = (_currentIndex + 1) % widget.reminders.length);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reminders[_currentIndex];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accentRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.accentRed),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('EMERGENCY ALERT',
                    style: TextStyle(
                        color: AppTheme.accentRed,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1)),
                Text(r.title,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.go('/reminders/alarm', extra: r.toMap()),
            icon: const Icon(Icons.arrow_forward_ios_rounded,
                color: AppTheme.accentRed, size: 16),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// AI Suggestion Sliver
// ──────────────────────────────────────────────────────────────────────────────
class _AISuggestionSliver extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome_rounded,
                    color: AppTheme.primaryPurple, size: 16),
                SizedBox(width: 8),
                Text(
                  'DISCIPLINE COACH',
                  style: TextStyle(
                    color: AppTheme.primaryPurple,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.bgDarkCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Consumer(
                builder: (context, ref, _) {
                  final s = ref.watch(aiSuggestionProvider);
                  return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.title,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.body,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        if (s.actionLabel != null) ...[
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () {
                              if (s.action == SuggestionAction.startMission) {
                                context.push('/mission/create');
                              } else if (s.action == SuggestionAction.createReminder) {
                                context.push('/reminders/create');
                              } else if (s.action == SuggestionAction.openSleepTimer) {
                                context.push('/sleep');
                              } else if (s.action == SuggestionAction.viewAnalytics) {
                                context.push('/insights');
                              }
                            },
                            child: Row(
                              children: [
                                Text(
                                  s.actionLabel!,
                                  style: const TextStyle(
                                    color: AppTheme.primaryPurple,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_rounded,
                                    color: AppTheme.primaryPurple, size: 14),
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Quick Actions Grid
// ──────────────────────────────────────────────────────────────────────────────
class _QuickActionsGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = [
      _QAction(
          icon: Icons.not_interested_rounded,
          label: 'Anti-Scroll',
          color: AppTheme.accentCyan,
          isActive: ref.watch(settingsProvider).noScrollEnabled,
          onTap: () async {
            final isEnabled = await PlatformChannel.isAccessibilityEnabled();
            if (!isEnabled) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PLEASE ENABLE "MINDLOCK Accessibility" in Settings! 🦾'),
                    backgroundColor: AppTheme.accentAmber,
                    duration: Duration(seconds: 4),
                  )
                );
              }
              await PlatformChannel.openAccessibilitySettings();
              return;
            }

            final current = ref.read(settingsProvider).noScrollEnabled;
            final newVal = !current;
            ref.read(settingsProvider.notifier).updateSetting('noScrollEnabled', newVal);
            await PlatformChannel.setNoScrollMode(newVal);
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(newVal ? 'Anti-Scroll ACTIVATED! 🚫📜' : 'Anti-Scroll Deactivated'),
                  backgroundColor: newVal ? AppTheme.accentCyan : AppTheme.bgDarkCard,
                  duration: const Duration(seconds: 2),
                )
              );
            }
          }),
      _QAction(
          icon: Icons.add_alarm_rounded,
          label: 'Add Reminder',
          color: AppTheme.primaryPurple,
          onTap: () => context.push('/reminders/create')),
      _QAction(
          icon: Icons.rocket_launch_rounded,
          label: 'Mission Mode',
          color: AppTheme.accentAmber,
          onTap: () => context.push('/mission/create')),
      _QAction(
          icon: Icons.bedtime_rounded,
          label: 'Sleep Timer',
          color: AppTheme.accentBlue,
          onTap: () => context.go('/sleep')),
      _QAction(
          icon: Icons.analytics_rounded,
          label: 'Analytics & Cloud',
          color: AppTheme.accentGreen,
          onTap: () => context.push('/insights')),
      _QAction(
          icon: Icons.lock_clock_rounded,
          label: 'Nightly Test',
          color: AppTheme.accentRed,
          onTap: () => PlatformChannel.triggerNightlyLockdown()),
      _QAction(
          icon: Icons.lock_person_rounded,
          label: 'Study Lock',
          color: AppTheme.accentRed,
          onTap: () => context.push('/fake-lock')),
      _QAction(
          icon: Icons.history_edu_rounded,
          label: 'Daily Journal',
          color: AppTheme.primaryPurple,
          onTap: () => context.go('/journal')),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: actions.map((a) => _QuickActionCard(action: a)).toList(),
    );
  }
}

class _QAction {
  final IconData icon;
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;
  const _QAction({
    required this.icon,
    required this.label,
    required this.color,
    this.isActive = false,
    required this.onTap,
  });
}

class _QuickActionCard extends StatelessWidget {
  final _QAction action;
  const _QuickActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: action.isActive ? action.color.withOpacity(0.2) : action.color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: action.isActive ? action.color : action.color.withOpacity(0.2),
            width: action.isActive ? 1.5 : 1.0,
          ),
          boxShadow: action.isActive ? [
            BoxShadow(color: action.color.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))
          ] : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: action.isActive ? action.color : action.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                action.icon, 
                color: action.isActive ? Colors.white : action.color, 
                size: 18
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.label,
                    style: TextStyle(
                      color: action.isActive ? Colors.white : AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: action.isActive ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                  if (action.isActive)
                    const Text(
                      'ACTIVE',
                      style: TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold),
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

// ──────────────────────────────────────────────────────────────────────────────
// Empty State
// ──────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.bgDarkCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: const Column(
        children: [
          Icon(Icons.check_circle_outline_rounded,
              color: AppTheme.accentGreen, size: 48),
          SizedBox(height: 16),
          Text('ALL TASKS DONE',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text('Enjoy your peace of mind',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Reminder Card
// ──────────────────────────────────────────────────────────────────────────────
class _ReminderCard extends StatelessWidget {
  final ReminderModel reminder;
  final int index;
  final VoidCallback onDone;

  const _ReminderCard({
    required this.reminder,
    required this.index,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColor = Color(reminder.priority.colorValue);
    final isPast = reminder.dateTime.isBefore(DateTime.now());

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + index * 80),
      curve: Curves.easeOutCubic,
      builder: (ctx, v, child) =>
          Opacity(opacity: v, child: Transform.translate(
            offset: Offset(0, 20 * (1 - v)), child: child)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgDarkCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isPast
                ? priorityColor.withOpacity(0.4)
                : AppTheme.borderColor,
          ),
          boxShadow: isPast
              ? [
                  BoxShadow(
                    color: priorityColor.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            // Status bar
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      decoration: reminder.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          color: isPast ? AppTheme.accentRed : AppTheme.textMuted,
                          size: 14),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('hh:mm a').format(reminder.dateTime),
                        style: TextStyle(
                          color: isPast ? AppTheme.accentRed : AppTheme.textMuted,
                          fontSize: 12,
                          fontWeight: isPast ? FontWeight.bold : null,
                        ),
                      ),
                      if (reminder.repeatIntervalMinutes > 0) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryPurple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '×${reminder.remainingRepeats}',
                            style: const TextStyle(
                                color: AppTheme.primaryPurple, fontSize: 10),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Done button
            GestureDetector(
              onTap: onDone,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppTheme.accentGreen.withOpacity(0.3)),
                ),
                child: const Icon(Icons.check_rounded,
                    color: AppTheme.accentGreen, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// FAB
// ──────────────────────────────────────────────────────────────────────────────
class _PremiumFAB extends StatelessWidget {
  final VoidCallback onTap;
  const _PremiumFAB({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [AppTheme.primaryPurple, AppTheme.accentBlue],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryPurple.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Permission Banner Widget
// ──────────────────────────────────────────────────────────────────────────────
class _PermissionBanner extends StatefulWidget {
  const _PermissionBanner();
  @override
  State<_PermissionBanner> createState() => _PermissionBannerState();
}

class _PermissionBannerState extends State<_PermissionBanner> {
  bool _hasExactAlarm = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final granted = await Permission.scheduleExactAlarm.isGranted;
    if (mounted) setState(() => _hasExactAlarm = granted);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasExactAlarm) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.accentAmber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentAmber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.security_rounded, color: AppTheme.accentAmber),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PERMISSIONS REQUIRED',
                  style: TextStyle(
                    color: AppTheme.accentAmber,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  'Allow Alarms & Reminders for Android to ring.',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              await PlatformChannel.openExactAlarmSettings();
              await Future.delayed(const Duration(seconds: 3));
              _checkPermissions();
            },
            child: const Text('FIX', style: TextStyle(color: AppTheme.accentAmber, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _DisclosureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  const _DisclosureItem({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primaryPurple, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
