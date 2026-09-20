import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the screen awake while Auto mode is running so the board stays
/// visible on a table without the phone locking itself.
class WakeLockService {
  bool _enabled = false;

  bool get isEnabled => _enabled;

  Future<void> enable() async {
    if (_enabled) return;
    try {
      await WakelockPlus.enable();
      _enabled = true;
    } catch (error) {
      debugPrint('Wakelock not supported here: $error');
    }
  }

  Future<void> disable() async {
    if (!_enabled) return;
    try {
      await WakelockPlus.disable();
    } catch (error) {
      debugPrint('Wakelock disable failed: $error');
    } finally {
      _enabled = false;
    }
  }
}
