import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'platform_channel.dart';

enum ChargingSpeed { normal, fast, ultra }

class BatteryState {
  final int level;
  final bool isCharging;
  final String plugType;
  final int currentNow; // mA
  final int remainingTimeMs;
  final ChargingSpeed speed;

  BatteryState({
    required this.level,
    required this.isCharging,
    required this.plugType,
    required this.currentNow,
    required this.remainingTimeMs,
    required this.speed,
  });

  factory BatteryState.initial() => BatteryState(
        level: 0,
        isCharging: false,
        plugType: 'Unknown',
        currentNow: 0,
        remainingTimeMs: -1,
        speed: ChargingSpeed.normal,
      );

  BatteryState copyWith({
    int? level,
    bool? isCharging,
    String? plugType,
    int? currentNow,
    int? remainingTimeMs,
    ChargingSpeed? speed,
  }) {
    return BatteryState(
      level: level ?? this.level,
      isCharging: isCharging ?? this.isCharging,
      plugType: plugType ?? this.plugType,
      currentNow: currentNow ?? this.currentNow,
      remainingTimeMs: remainingTimeMs ?? this.remainingTimeMs,
      speed: speed ?? this.speed,
    );
  }
}

class ChargingService extends StateNotifier<BatteryState> {
  ChargingService() : super(BatteryState.initial()) {
    _initialize();
  }

  void _initialize() {
    PlatformChannel.onPowerConnected = (data) {
      _updateFromMap(data);
      // Trigger animation overlay here if needed
      _showChargingOverlay();
    };

    PlatformChannel.onPowerDisconnected = () {
      state = state.copyWith(isCharging: false, currentNow: 0);
    };

    PlatformChannel.onBatteryInfoUpdate = (data) {
      _updateFromMap(data);
    };

    // Initial fetch
    _fetchInitial();
  }

  Future<void> _fetchInitial() async {
    final info = await PlatformChannel.getBatteryInfo();
    if (info != null) {
      _updateFromMap(info);
    }
  }

  void _updateFromMap(Map<String, dynamic> data) {
    final current = (data['currentNow'] as num?)?.toInt() ?? 0;
    
    ChargingSpeed speed = ChargingSpeed.normal;
    if (current.abs() > 4000) {
      speed = ChargingSpeed.ultra;
    } else if (current.abs() > 1500) {
      speed = ChargingSpeed.fast;
    }

    state = state.copyWith(
      level: (data['level'] as num?)?.toInt(),
      isCharging: data['isCharging'] as bool?,
      plugType: data['plugType'] as String?,
      currentNow: current,
      remainingTimeMs: (data['remainingTimeMs'] as num?)?.toInt(),
      speed: speed,
    );
  }

  void _showChargingOverlay() {
    // This will be handled by a listener in the UI or a separate service
    debugPrint("SHOW CHARGING OVERLAY");
  }
}

final chargingProvider = StateNotifierProvider<ChargingService, BatteryState>((ref) {
  return ChargingService();
});
