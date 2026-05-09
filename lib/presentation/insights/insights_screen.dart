import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../services/platform_channel.dart';
import '../../core/providers/usage_provider.dart';
import '../../core/providers/interests_provider.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  String _selectedPeriod = 'day';

  @override
  Widget build(BuildContext context) {
    final usageAsync = ref.watch(usageProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Stack(
        children: [
          // Background ambient glows
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryPurple.withOpacity(0.05),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: const SizedBox(),
              ),
            ),
          ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildPeriodSelector(),
                      const SizedBox(height: 24),
                      FutureBuilder<bool>(
                        future: PlatformChannel.checkUsageStatsPermission(),
                        builder: (context, snapshot) {
                          if (snapshot.data == false) {
                            return _buildPermissionNote();
                          }
                          return const SizedBox.shrink();
                        }
                      ),
                      usageAsync.when(
                        data: (stats) => _buildStatsContent(stats),
                        loading: () => const Padding(
                          padding: EdgeInsets.only(top: 100),
                          child: Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple)),
                        ),
                        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      backgroundColor: AppTheme.bgDark,
      floating: false,
      pinned: true,
      elevation: 0,
      centerTitle: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(bottom: 16),
        centerTitle: true,
        title: const Text(
          'ANALYTICS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 4,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryPurple.withOpacity(0.15),
                AppTheme.bgDark,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppTheme.bgDarkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          _buildPeriodBtn('day', 'DAY'),
          _buildPeriodBtn('week', 'WEEK'),
          _buildPeriodBtn('month', 'MONTH'),
          _buildPeriodBtn('year', 'YEAR'),
        ],
      ),
    );
  }

  Widget _buildPeriodBtn(String period, String label) {
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedPeriod = period);
          ref.read(usageProvider.notifier).fetchUsage(period);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected ? [
              BoxShadow(
                color: AppTheme.primaryPurple.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ] : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textMuted,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsContent(Map<String, int> stats) {
    if (stats.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.only(top: 60),
        child: Text('No data recorded for this period.', style: TextStyle(color: AppTheme.textMuted)),
      ));
    }

    final selectedInterests = ref.watch(userInterestsProvider);
    int productiveMins = 0;
    int distractionMins = 0;

    for (final entry in stats.entries) {
      bool isProductive = false;
      for (final interest in selectedInterests) {
        final productivePackages = InterestApps.mapping[interest] ?? [];
        if (productivePackages.contains(entry.key)) {
          isProductive = true;
          break;
        }
      }
      
      if (isProductive) {
        productiveMins += entry.value;
      } else if (entry.key != 'com.mindlock.app' && entry.key != 'com.android.settings') {
        distractionMins += entry.value;
      }
    }

    final top3 = stats.entries.take(3).toList();
    final totalMins = stats.values.fold(0, (sum, val) => sum + val);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTotalTimeCard(totalMins),
        const SizedBox(height: 32),
        _buildProductivityBalance(productiveMins, distractionMins),
        const SizedBox(height: 32),
        const Text(
          'TOP DISTRACTIONS',
          style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            if (top3.isNotEmpty) Expanded(child: _buildTopAppCard(top3[0], 1, AppTheme.accentAmber)),
            if (top3.length > 1) const SizedBox(width: 12),
            if (top3.length > 1) Expanded(child: _buildTopAppCard(top3[1], 2, AppTheme.accentBlue)),
            if (top3.length > 2) const SizedBox(width: 12),
            if (top3.length > 2) Expanded(child: _buildTopAppCard(top3[2], 3, AppTheme.primaryPurple)),
          ],
        ),
        const SizedBox(height: 32),
        const Text(
          'USAGE BREAKDOWN',
          style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2),
        ),
        const SizedBox(height: 16),
        ...stats.entries.skip(3).take(7).map((e) => _buildUsageItem(e.key, e.value, stats.values.first)),
        const SizedBox(height: 32),
        _buildProblemSection(top3.isNotEmpty ? top3[0].key : '', top3.isNotEmpty ? top3[0].value : 0),
      ],
    );
  }

  Widget _buildTotalTimeCard(int totalMins) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E1E2C).withOpacity(0.5),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2D2D44).withOpacity(0.9),
                  const Color(0xFF1E1E2C).withOpacity(0.95),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL SCREEN TIME',
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2),
                    ),
                    Icon(Icons.auto_graph_rounded, color: AppTheme.primaryPurple.withOpacity(0.6), size: 22),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatTime(totalMins).split(' ').first,
                      style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w900, letterSpacing: -2),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        _formatTime(totalMins).contains(' ') ? _formatTime(totalMins).split(' ').last : '',
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 24, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded, color: AppTheme.primaryPurple, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Period: ${_selectedPeriod.toUpperCase()}',
                        style: const TextStyle(color: AppTheme.primaryPurple, fontSize: 10, fontWeight: FontWeight.bold),
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

  Widget _buildProductivityBalance(int productive, int distraction) {
    final total = productive + distraction;
    final ratio = total > 0 ? productive / total : 0.0;
    final isLazy = ratio < 0.3;

    String periodTitle = 'DAILY VERDICT';
    if (_selectedPeriod == 'week') periodTitle = 'WEEKLY PERFORMANCE';
    if (_selectedPeriod == 'month') periodTitle = 'MONTHLY ANALYSIS';
    if (_selectedPeriod == 'year') periodTitle = 'YEARLY SUMMARY';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(periodTitle, style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2)),
            Text(
              isLazy ? 'LAZY' : 'PRODUCTIVE',
              style: TextStyle(
                color: isLazy ? AppTheme.accentAmber : AppTheme.accentGreen, 
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.bgDarkCard,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _BalanceItem('INTERESTS', productive, AppTheme.accentGreen),
                  const SizedBox(width: 20),
                  _BalanceItem('DISTRACTIONS', distraction, AppTheme.accentRed),
                ],
              ),
              const SizedBox(height: 24),
              Stack(
                children: [
                  Container(
                    height: 10,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.accentRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    height: 10,
                    width: MediaQuery.of(context).size.width * (ratio * 0.8), // Approx scaling
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.accentGreen, Color(0xFF00FF88)]),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [BoxShadow(color: AppTheme.accentGreen.withOpacity(0.4), blurRadius: 10)],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'You spent ${ (ratio * 100).toInt()}% of your time on what matters to you.',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _BalanceItem(String label, int mins, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(_formatTime(mins), style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        ],
      ),
    );
  }

  Widget _buildTopAppCard(MapEntry<String, int> entry, int rank, Color color) {
    final appName = entry.key.split('.').last.toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgDarkCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Text('#$rank', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            appName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _formatTime(entry.value),
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageItem(String pkg, int minutes, int maxMins) {
    final ratio = minutes / maxMins;
    final appName = pkg.split('.').last;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(appName.toUpperCase(), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
              Text(_formatTime(minutes), style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.03),
              color: AppTheme.primaryPurple.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProblemSection(String pkg, int minutes) {
    if (pkg.isEmpty) return const SizedBox.shrink();
    final appName = pkg.split('.').last.toUpperCase();
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.accentRed.withOpacity(0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppTheme.accentRed.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: AppTheme.accentRed, size: 20),
              SizedBox(width: 12),
              Text('TIME LEAK DETECTED', style: TextStyle(color: AppTheme.accentRed, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'You spent ${_formatTime(minutes)} on $appName during this period. This is your primary distraction source.',
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
          ),
          const SizedBox(height: 24),
          _SolutionTile('Activate Mission Lockdown', Icons.security_rounded),
          _SolutionTile('Set smart usage limit', Icons.av_timer_rounded),
        ],
      ),
    );
  }

  Widget _SolutionTile(String text, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryPurple, size: 18),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPermissionNote() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentAmber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accentAmber.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.accentAmber, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Detailed insights require "Usage Access" permission.',
                  style: TextStyle(color: AppTheme.accentAmber, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await PlatformChannel.openUsageStatsSettings();
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentAmber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('GRANT ACCESS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }
}
