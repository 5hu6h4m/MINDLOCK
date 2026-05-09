import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/platform_channel.dart';

final usageProvider = StateNotifierProvider<UsageNotifier, AsyncValue<Map<String, int>>>((ref) {
  return UsageNotifier();
});

class UsageNotifier extends StateNotifier<AsyncValue<Map<String, int>>> {
  UsageNotifier() : super(const AsyncValue.loading()) {
    fetchUsage('day');
  }

  Future<void> fetchUsage(String period) async {
    state = const AsyncValue.loading();
    try {
      final stats = await PlatformChannel.getUsageStats(period: period);
      // Sort and limit to top 15 apps
      final sortedStats = Map.fromEntries(
        stats.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value))
          ..take(15)
      );
      state = AsyncValue.data(sortedStats);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
