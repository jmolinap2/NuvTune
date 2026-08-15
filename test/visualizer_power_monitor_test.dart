import 'package:flutter_test/flutter_test.dart';
import 'package:nuvtune/core/platform/visualizer_power_monitor.dart';

void main() {
  group('VisualizerPowerState', () {
    test('decodes and clamps the native battery snapshot', () {
      final state = VisualizerPowerState.fromPlatformEvent(<Object?, Object?>{
        'batteryLevel': 1.4,
        'isCharging': true,
        'isBatteryLow': true,
        'isPowerSaveMode': false,
      });

      expect(state.batteryLevel, 1);
      expect(state.isCharging, isTrue);
      expect(state.isBatteryLow, isTrue);
      expect(state.isPowerSaveMode, isFalse);
      expect(state.shouldReduceEffects, isFalse);
    });

    test('power save always requests reduced effects', () {
      const state = VisualizerPowerState(
        batteryLevel: 0.9,
        isCharging: true,
        isBatteryLow: false,
        isPowerSaveMode: true,
      );

      expect(state.shouldReduceEffects, isTrue);
    });

    test('low unplugged battery requests reduced effects', () {
      const state = VisualizerPowerState(
        batteryLevel: 0.1,
        isCharging: false,
        isBatteryLow: true,
        isPowerSaveMode: false,
      );

      expect(state.shouldReduceEffects, isTrue);
    });

    test('malformed events use normal quality defaults', () {
      final state = VisualizerPowerState.fromPlatformEvent('invalid');

      expect(state, const VisualizerPowerState.normal());
      expect(state.shouldReduceEffects, isFalse);
    });
  });
}
