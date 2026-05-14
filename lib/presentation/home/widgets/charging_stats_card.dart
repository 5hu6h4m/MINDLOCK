import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/charging_service.dart';

class ChargingStatsCard extends ConsumerWidget {
  const ChargingStatsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final battery = ref.watch(chargingProvider);

    if (!battery.isCharging) return const SizedBox.shrink();

    final Color accentColor = _getAccentColor(battery.speed);
    final String speedLabel = _getSpeedLabel(battery.speed);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withOpacity(0.15),
            AppTheme.bgDarkCard.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: -5,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.bolt_rounded, color: accentColor, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    speedLabel,
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${battery.level}%',
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CURRENT INFLOW',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${battery.currentNow}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 6, left: 4),
                          child: Text(
                            'mA',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                height: 50,
                width: 1,
                color: AppTheme.borderColor.withOpacity(0.5),
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'EST. TIME LEFT',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatRemainingTime(battery.remainingTimeMs),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: battery.level / 100,
              backgroundColor: AppTheme.bgDarkElevated,
              valueColor: AlwaysStoppedAnimation(accentColor),
              minHeight: 6,
            ),
          ),
          if (battery.speed == ChargingSpeed.ultra) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.accentCyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accentCyan.withOpacity(0.2)),
              ),
              child: const Center(
                child: Text(
                  '🚀 TURBO CHARGING OPTIMIZED',
                  style: TextStyle(
                    color: AppTheme.accentCyan,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getAccentColor(ChargingSpeed speed) {
    switch (speed) {
      case ChargingSpeed.ultra:
        return AppTheme.accentCyan;
      case ChargingSpeed.fast:
        return AppTheme.primaryPurple;
      case ChargingSpeed.normal:
        return AppTheme.accentBlue;
    }
  }

  String _getSpeedLabel(ChargingSpeed speed) {
    switch (speed) {
      case ChargingSpeed.ultra:
        return 'ULTRA SUPER CHARGE';
      case ChargingSpeed.fast:
        return 'FAST CHARGING';
      case ChargingSpeed.normal:
        return 'NORMAL CHARGING';
    }
  }

  String _formatRemainingTime(int ms) {
    if (ms <= 0) return 'Analyzing...';
    // If it's a very large number (fallback estimation), cap it or handle it
    if (ms > 1000 * 60 * 60 * 24) return 'Steady flow...';
    
    final duration = Duration(milliseconds: ms);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    if (minutes <= 0) return 'Finishing...';
    return '${minutes}m left';
  }
}
