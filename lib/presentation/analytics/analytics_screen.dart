import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/reminder_repository.dart';
import '../../services/discipline_service.dart';
import '../../services/streak_service.dart';
import '../../services/platform_channel.dart';
import '../../core/theme/app_theme.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(reminderRepositoryProvider);
    final discipline = ref.watch(disciplineServiceProvider);
    final stats = ref.watch(userStatsProvider);
    
    final score = discipline.calculateDailyScore(DateTime.now());
    final label = discipline.getDisciplineLabel(score);
    final weeklyStats = repo.getWeeklyStats();
    
    final completed = repo.totalCompleted;
    final ignored = repo.totalIgnored;
    final pending = repo.totalPending;
    final rate = repo.completionRate;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        title: const Text('Analytics'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        physics: const BouncingScrollPhysics(),
        children: [
          // ── Discipline Score ──────────────────────────────────────────────
          _DisScore(rate: score, label: label),
          const SizedBox(height: 20),

          // ── Stats Grid ───────────────────────────────────────────────────
          _StatsGrid(
              completed: completed, ignored: ignored, pending: pending),
          const SizedBox(height: 20),

          // ── Weekly Chart ─────────────────────────────────────────────────
          _SectionTitle('Weekly Activity'),
          const SizedBox(height: 12),
          _WeeklyChart(stats: weeklyStats),
          const SizedBox(height: 20),

          // ── Streaks ───────────────────────────────────────────────────────
          _StreaksBadges(current: stats.currentStreak, longest: stats.longestStreak),
          const SizedBox(height: 20),

          // ── Top Distractions ──────────────────────────────────────────────
          _SectionTitle('Top Distractions'),
          const SizedBox(height: 12),
          FutureBuilder<Map<String, int>>(
            future: PlatformChannel.getUsageStats(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const _InsightCard(
                  icon: Icons.info_outline_rounded,
                  color: AppTheme.textMuted,
                  title: 'No Data',
                  body: 'Usage stats permission required to track distractions.',
                );
              }
              final sorted = snapshot.data!.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              final top3 = sorted.take(3).toList();
              
              return Column(
                children: top3.map((e) => _DistractionTile(pkg: e.key, mins: e.value)).toList(),
              );
            },
          ),
          const SizedBox(height: 20),

          // ── Insights ─────────────────────────────────────────────────────
          _SectionTitle('Insights'),
          const SizedBox(height: 12),
          _InsightCard(
            icon: Icons.lightbulb_rounded,
            color: AppTheme.accentAmber,
            title: 'Keep it consistent',
            body:
                'Completing reminders before 9 PM improves your sleep quality.',
          ),
          const SizedBox(height: 8),
          _InsightCard(
            icon: Icons.trending_up_rounded,
            color: AppTheme.accentGreen,
            title: 'Good discipline!',
            body: 'Your completion rate is ${(rate * 100).toStringAsFixed(0)}%. '
                'Aim for 80%+ for maximum focus.',
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600));
  }
}

class _DisScore extends StatelessWidget {
  final double rate;
  final String label;
  const _DisScore({required this.rate, required this.label});

  @override
  Widget build(BuildContext context) {
    final pct = (rate * 100).toInt();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryPurple.withOpacity(0.15),
            AppTheme.accentBlue.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: rate,
                  strokeWidth: 8,
                  backgroundColor: AppTheme.bgDarkElevated,
                  valueColor: const AlwaysStoppedAnimation(
                      AppTheme.primaryPurple),
                  strokeCap: StrokeCap.round,
                ),
                Text('$pct%',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    )),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Discipline Score',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 18)),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: rate,
                  backgroundColor: AppTheme.bgDarkElevated,
                  valueColor: AlwaysStoppedAnimation(
                    pct >= 80
                        ? AppTheme.accentGreen
                        : pct >= 50
                            ? AppTheme.primaryPurple
                            : AppTheme.accentAmber,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final int completed, ignored, pending;
  const _StatsGrid(
      {required this.completed,
      required this.ignored,
      required this.pending});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
            value: completed.toString(),
            label: 'Completed',
            icon: Icons.check_circle_rounded,
            color: AppTheme.accentGreen),
        const SizedBox(width: 12),
        _StatCard(
            value: ignored.toString(),
            label: 'Ignored',
            icon: Icons.cancel_rounded,
            color: AppTheme.accentRed),
        const SizedBox(width: 12),
        _StatCard(
            value: pending.toString(),
            label: 'Pending',
            icon: Icons.pending_rounded,
            color: AppTheme.accentAmber),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;

  const _StatCard(
      {required this.value,
      required this.label,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 26,
                    fontWeight: FontWeight.w700)),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  final Map<int, List<int>> stats;
  const _WeeklyChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      return DateFormat('E').format(date);
    });

    // Find max value for scaling
    double maxVal = 5.0;
    for (final s in stats.values) {
      if (s[0] + s[1] > maxVal) maxVal = (s[0] + s[1]).toDouble();
    }
    maxVal += 2;

    return Container(
      padding: const EdgeInsets.all(16),
      height: 200,
      decoration: BoxDecoration(
        color: AppTheme.bgDarkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 12,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, meta) => Text(
                  days[v.toInt()],
                  style: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 11),
                ),
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (i) {
            final data = stats[i] ?? [0, 0];
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: data[0].toDouble(),
                  color: AppTheme.primaryPurple,
                  width: 10,
                  borderRadius: BorderRadius.circular(4),
                ),
                BarChartRodData(
                  toY: data[1].toDouble(),
                  color: AppTheme.accentRed.withOpacity(0.5),
                  width: 10,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _StreaksBadges extends StatelessWidget {
  final int current, longest;
  const _StreaksBadges({required this.current, required this.longest});

  final _badges = const [
    _Badge('🌙', 'Night\nDiscipline', AppTheme.accentBlue),
    _Badge('⚔️', 'Task\nWarrior', AppTheme.primaryPurple),
    _Badge('🎯', 'Focus\nMaster', AppTheme.accentCyan),
    _Badge('📵', 'No-Reels\nChamp', AppTheme.accentGreen),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _StatCard(
                value: current.toString(),
                label: 'Current Streak',
                icon: Icons.local_fire_department_rounded,
                color: AppTheme.accentAmber),
            const SizedBox(width: 12),
            _StatCard(
                value: longest.toString(),
                label: 'Longest Streak',
                icon: Icons.emoji_events_rounded,
                color: AppTheme.accentCyan),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: _badges.map((b) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: b.color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: b.color.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Text(b.emoji, style: const TextStyle(fontSize: 26)),
                const SizedBox(height: 4),
                Text(b.label,
                    style: TextStyle(
                        color: b.color,
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      }).toList(),
        ),
      ],
    );
  }
}

class _Badge {
  final String emoji, label;
  final Color color;
  const _Badge(this.emoji, this.label, this.color);
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, body;

  const _InsightCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const SizedBox(height: 4),
                Text(body,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DistractionTile extends StatelessWidget {
  final String pkg;
  final int mins;
  const _DistractionTile({required this.pkg, required this.mins});

  @override
  Widget build(BuildContext context) {
    final name = pkg.split('.').last.toUpperCase();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgDarkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.accentRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warning_amber_rounded, color: AppTheme.accentRed, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                Text(pkg, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
              ],
            ),
          ),
          Text('$mins mins', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
