import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SensorService extends ChangeNotifier {
  static const MethodChannel _channel =
      MethodChannel('com.simpleappspg.sensors/data');

  double _rawSensorLux = 650.0;
  double _manualLux = 850.0;
  double _calibrationFactor = 1.0;
  bool _hasHardwareLightSensor = false;
  bool _useManualOverride = true;
  Timer? _pollTimer;

  double get rawSensorLux => _rawSensorLux;
  double get manualLux => _manualLux;
  double get calibrationFactor => _calibrationFactor;
  bool get hasHardwareLightSensor => _hasHardwareLightSensor;
  bool get useManualOverride => _useManualOverride;

  double get effectiveLux {
    final base = _useManualOverride ? _manualLux : _rawSensorLux;
    return (base * _calibrationFactor).clamp(0.0, 50000.0);
  }

  void setManualLux(double value) {
    _manualLux = value.clamp(0.0, 50000.0);
    _useManualOverride = true;
    notifyListeners();
  }

  void setUseManualOverride(bool manual) {
    _useManualOverride = manual;
    notifyListeners();
  }

  void setCalibrationFactor(double factor) {
    _calibrationFactor = factor.clamp(0.5, 2.0);
    notifyListeners();
  }

  Future<void> pollOnce() async {
    try {
      final result =
          await _channel.invokeMapMethod<String, dynamic>('getSensorSnapshot');
      if (result != null) {
        final hasLight = result['hasLight'] as bool? ?? false;
        final luxVal = (result['lightLux'] as num?)?.toDouble() ?? 650.0;
        _hasHardwareLightSensor = hasLight;
        _rawSensorLux = luxVal.clamp(0.0, 50000.0);
        if (hasLight && _useManualOverride == false) {
          notifyListeners();
        }
      }
    } catch (_) {
      // Fallback gracefully when running on desktop/tests without platform channel
    }
  }

  void startPolling({Duration interval = const Duration(milliseconds: 500)}) {
    stopPolling();
    pollOnce();
    _pollTimer = Timer.periodic(interval, (_) {
      if (!_useManualOverride) {
        pollOnce();
      }
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
