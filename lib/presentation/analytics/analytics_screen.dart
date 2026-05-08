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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
      backgroundColor: isDark ? AppTheme.bgDark : const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Analytics', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        physics: const BouncingScrollPhysics(),
        children: [
          // ── Discipline Score ──────────────────────────────────────────────
          _DisScore(rate: score, label: label, isDark: isDark),
          const SizedBox(height: 20),

          // ── Stats Grid ───────────────────────────────────────────────────
          _StatsGrid(completed: completed, ignored: ignored, pending: pending, isDark: isDark),
          const SizedBox(height: 24),

          // ── Weekly Chart ─────────────────────────────────────────────────
          _SectionTitle('Weekly Activity', isDark: isDark),
          const SizedBox(height: 12),
          _WeeklyChart(stats: weeklyStats, isDark: isDark),
          const SizedBox(height: 24),

          // ── Streaks ───────────────────────────────────────────────────────
          _StreaksBadges(current: stats.currentStreak, longest: stats.longestStreak, isDark: isDark),
          const SizedBox(height: 24),

          // ── Top Distractions ──────────────────────────────────────────────
          _SectionTitle('Top Distractions', isDark: isDark),
          const SizedBox(height: 12),
          FutureBuilder<Map<String, int>>(
            future: PlatformChannel.getUsageStats(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _InsightCard(
                  icon: Icons.info_outline_rounded,
                  color: AppTheme.textMuted,
                  title: 'No Data',
                  body: 'Usage stats permission required to track distractions.',
                  isDark: isDark,
                );
              }
              final sorted = snapshot.data!.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              final top3 = sorted.take(3).toList();
              
              return Column(
                children: top3.map((e) => _DistractionTile(pkg: e.key, mins: e.value, isDark: isDark)).toList(),
              );
            },
          ),
          const SizedBox(height: 24),

          // ── Insights ─────────────────────────────────────────────────────
          _SectionTitle('Insights', isDark: isDark),
          const SizedBox(height: 12),
          _InsightCard(
            icon: Icons.lightbulb_rounded,
            color: AppTheme.accentAmber,
            title: 'Keep it consistent',
            body: 'Completing reminders before 9 PM improves your sleep quality.',
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _InsightCard(
            icon: Icons.trending_up_rounded,
            color: AppTheme.accentGreen,
            title: 'Good discipline!',
            body: 'Your completion rate is ${(rate * 100).toStringAsFixed(0)}%. Aim for 80%+ for maximum focus.',
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final bool isDark;
  const _SectionTitle(this.text, {required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: TextStyle(
            color: isDark ? AppTheme.textPrimary : Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w700));
  }
}

class _DisScore extends StatelessWidget {
  final double rate;
  final String label;
  final bool isDark;
  const _DisScore({required this.rate, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final pct = (rate * 100).toInt();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgDarkElevated.withOpacity(0.5) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? AppTheme.primaryPurple.withOpacity(0.2) : Colors.black.withOpacity(0.05)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8))],
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
                  backgroundColor: isDark ? AppTheme.bgDarkElevated : Colors.black.withOpacity(0.05),
                  valueColor: const AlwaysStoppedAnimation(AppTheme.primaryPurple),
                  strokeCap: StrokeCap.round,
                ),
                Text('$pct%',
                    style: TextStyle(
                      color: isDark ? AppTheme.textPrimary : Colors.black87,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    )),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Discipline',
                    style: TextStyle(
                        color: isDark ? AppTheme.textPrimary : Colors.black87,
                        fontWeight: FontWeight.w800,
                        fontSize: 20)),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                      color: isDark ? AppTheme.textSecondary : Colors.black54, fontSize: 14),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: rate,
                    backgroundColor: isDark ? AppTheme.bgDarkElevated : Colors.black.withOpacity(0.05),
                    valueColor: AlwaysStoppedAnimation(
                      pct >= 80 ? AppTheme.accentGreen : pct >= 50 ? AppTheme.primaryPurple : AppTheme.accentAmber,
                    ),
                    minHeight: 8,
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

class _StatsGrid extends StatelessWidget {
  final int completed, ignored, pending;
  final bool isDark;
  const _StatsGrid({required this.completed, required this.ignored, required this.pending, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(value: completed.toString(), label: 'Done', icon: Icons.check_circle_rounded, color: AppTheme.accentGreen, isDark: isDark),
        const SizedBox(width: 12),
        _StatCard(value: ignored.toString(), label: 'Missed', icon: Icons.cancel_rounded, color: AppTheme.accentRed, isDark: isDark),
        const SizedBox(width: 12),
        _StatCard(value: pending.toString(), label: 'Left', icon: Icons.pending_rounded, color: AppTheme.accentAmber, isDark: isDark),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatCard({required this.value, required this.label, required this.icon, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.bgDarkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? AppTheme.borderColor : Colors.black.withOpacity(0.05)),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  final Map<int, List<int>> stats;
  final bool isDark;
  const _WeeklyChart({required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Container(
      padding: const EdgeInsets.all(20),
      height: 220,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? AppTheme.borderColor : Colors.black.withOpacity(0.05)),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 10,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, meta) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(days[v.toInt() % 7], style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
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
                BarChartRodData(toY: data[0].toDouble(), color: AppTheme.primaryPurple, width: 12, borderRadius: BorderRadius.circular(4)),
                BarChartRodData(toY: data[1].toDouble(), color: AppTheme.accentRed.withOpacity(0.5), width: 12, borderRadius: BorderRadius.circular(4)),
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
  final bool isDark;
  const _StreaksBadges({required this.current, required this.longest, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final repo = ProviderScope.containerOf(context).read(reminderRepositoryProvider);
    final isNightWarrior = repo.getCompletedAfter(20).length >= 3;
    final isTaskWarrior = repo.totalCompleted >= 10;
    final isFocusMaster = repo.totalMissionsCompleted >= 3;
    
    return Column(
      children: [
        Row(
          children: [
            _StatCard(value: current.toString(), label: 'Streak', icon: Icons.local_fire_department_rounded, color: AppTheme.accentAmber, isDark: isDark),
            const SizedBox(width: 12),
            _StatCard(value: longest.toString(), label: 'Best', icon: Icons.emoji_events_rounded, color: AppTheme.accentCyan, isDark: isDark),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _BadgeTile(emoji: '🌙', label: 'Night Owl', color: AppTheme.accentBlue, unlocked: isNightWarrior, isDark: isDark),
              _BadgeTile(emoji: '⚔️', label: 'Warrior', color: AppTheme.primaryPurple, unlocked: isTaskWarrior, isDark: isDark),
              _BadgeTile(emoji: '🎯', label: 'Master', color: AppTheme.accentCyan, unlocked: isFocusMaster, isDark: isDark),
              _BadgeTile(emoji: '📵', label: 'Zen Mode', color: AppTheme.accentGreen, unlocked: false, isDark: isDark),
            ],
          ),
        ),
      ],
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final String emoji, label;
  final Color color;
  final bool unlocked, isDark;

  const _BadgeTile({required this.emoji, required this.label, required this.color, required this.unlocked, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: unlocked ? color.withOpacity(0.1) : (isDark ? AppTheme.bgDarkElevated : Colors.black.withOpacity(0.03)),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: unlocked ? color.withOpacity(0.3) : Colors.transparent),
      ),
      child: Column(
        children: [
          Opacity(
            opacity: unlocked ? 1.0 : 0.3,
            child: Text(emoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: unlocked ? color : AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, body;
  final bool isDark;

  const _InsightCard({required this.icon, required this.color, required this.title, required this.body, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 4),
                Text(body, style: TextStyle(color: isDark ? AppTheme.textSecondary : Colors.black54, fontSize: 13)),
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
  final bool isDark;
  const _DistractionTile({required this.pkg, required this.mins, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final name = pkg.split('.').last.toUpperCase();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppTheme.borderColor : Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppTheme.accentRed, size: 20),
          const SizedBox(width: 16),
          Expanded(child: Text(name, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600))),
          Text('$mins m', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
