import 'dart:ui';
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
import '../../core/providers/settings_provider.dart';

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

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryPurple,
          backgroundColor: AppTheme.bgDarkCard,
          onRefresh: () async => setState(() {}),
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

              // ── Emergency Banner ─────────────────────────────────────────
              if (emergencyReminders.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _EmergencyBanner(reminders: emergencyReminders),
                  ),
                ),

              // ── Stats Row ─────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Consumer(
                    builder: (context, ref, child) {
                      final discipline = ref.watch(disciplineServiceProvider);
                      final score = discipline.calculateDailyScore(DateTime.now());
                      return _StatsRow(
                        disciplineScore: (score * 100).toInt(),
                        pending: pendingReminders.length,
                        completed: completedToday,
                      );
                    },
                  ),
                ),
              ),

              // ── AI Suggestion ──────────────────────────────────────────────
              _AISuggestionSliver(),

              // ── Today's Tasks ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
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

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
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
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
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

class _EmergencyBannerState extends State<_EmergencyBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (ctx, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              AppTheme.accentRed.withOpacity(0.15 + _pulse.value * 0.08),
              AppTheme.accentRed.withOpacity(0.08),
            ],
          ),
          border: Border.all(
            color: AppTheme.accentRed.withOpacity(0.4 + _pulse.value * 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_rounded, color: AppTheme.accentRed),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EMERGENCY REMINDER',
                    style: TextStyle(
                      color: AppTheme.accentRed,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    widget.reminders.first.title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.accentRed),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Stats Row
// ──────────────────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final int disciplineScore, pending, completed;
  const _StatsRow(
      {required this.disciplineScore,
      required this.pending,
      required this.completed});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip(value: "$disciplineScore%", label: "Discipline", color: AppTheme.primaryPurple),
        const SizedBox(width: 12),
        _StatChip(value: pending.toString(), label: "Pending", color: AppTheme.accentAmber),
        const SizedBox(width: 12),
        _StatChip(value: completed.toString(), label: "Done", color: AppTheme.accentGreen),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatChip({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 11)),
          ],
        ),
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
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Priority dot
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 12, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('hh:mm a').format(reminder.dateTime),
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 12),
                      ),
                      if (reminder.repeatCount > 1) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryPurple.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
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
// Quick Actions Grid
// ──────────────────────────────────────────────────────────────────────────────
class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
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
          icon: Icons.warning_amber_rounded,
          label: 'Emergency',
          color: AppTheme.accentRed,
          onTap: () => context.push('/reminders/create')),
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
  final VoidCallback onTap;
  const _QAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
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
          color: action.color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: action.color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(action.icon, color: action.color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                action.label,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
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
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.bgDarkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              size: 48, color: AppTheme.accentGreen),
          const SizedBox(height: 12),
          const Text(
            "You're all clear for today",
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'No reminders scheduled. Add one to stay disciplined.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            textAlign: TextAlign.center,
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
    final settings = ref.watch(settingsProvider);
    if (!settings.aiSuggestionsEnabled) return const SliverToBoxAdapter(child: SizedBox());

    final aiService = ref.watch(aiSuggestionServiceProvider);
    final suggestion = aiService.getContextualSuggestion();

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: suggestion.color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: suggestion.color.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: suggestion.color.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: suggestion.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(suggestion.icon, color: suggestion.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'SMART SUGGESTION',
                          style: TextStyle(
                            color: suggestion.color,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'AI',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      suggestion.title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      suggestion.body,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    if (suggestion.action != SuggestionAction.none) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 32,
                        child: ElevatedButton(
                          onPressed: () => _handleAction(context, suggestion.action),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: suggestion.color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            suggestion.actionLabel,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, SuggestionAction action) {
    switch (action) {
      case SuggestionAction.createReminder:
        context.push('/reminders/create');
        break;
      case SuggestionAction.startMission:
        context.push('/mission/create');
        break;
      case SuggestionAction.openSleepTimer:
        context.go('/sleep');
        break;
      case SuggestionAction.viewAnalytics:
        context.go('/analytics');
        break;
      case SuggestionAction.none:
        break;
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Premium FAB
// ──────────────────────────────────────────────────────────────────────────────
class _PremiumFAB extends StatelessWidget {
  final VoidCallback onTap;
  const _PremiumFAB({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [AppTheme.primaryPurple, AppTheme.accentBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryPurple.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}
