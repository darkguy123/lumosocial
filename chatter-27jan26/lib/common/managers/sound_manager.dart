import 'package:flutter/services.dart';

class SoundManager {
  static final SoundManager shared = SoundManager();

  /// Play Pop Sound when liking a post / reel
  void playPopSound() {
    try {
      HapticFeedback.lightImpact();
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  /// Play Light Bell Sound when commenting on a post / reel
  void playBellSound() {
    try {
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
  }

  /// Play Message Sound when receiving or sending a chat message
  void playMessageSound() {
    try {
      HapticFeedback.selectionClick();
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }
}
