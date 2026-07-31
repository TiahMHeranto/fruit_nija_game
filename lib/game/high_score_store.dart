import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// High-score persistence without the shared_preferences plugin.
///
/// That plugin fails to compile when the project and pub-cache live on
/// different Windows drive letters (Z: vs C:). This channel uses app-local
/// SharedPreferences on Android and an in-memory fallback elsewhere.
class HighScoreStore {
  HighScoreStore._();

  static const _channel = MethodChannel('fruit_ninja_tiahm/prefs');
  static int _memory = 0;

  static Future<int> load() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return _memory;
    }
    try {
      final value = await _channel.invokeMethod<int>('getHighScore');
      _memory = value ?? 0;
      return _memory;
    } catch (_) {
      return _memory;
    }
  }

  static Future<void> save(int value) async {
    if (value < _memory) return;
    _memory = value;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>('setHighScore', value);
    } catch (_) {
      // Keep in-memory value if the channel is unavailable.
    }
  }
}
