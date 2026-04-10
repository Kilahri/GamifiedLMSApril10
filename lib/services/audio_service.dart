import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  static final AudioPlayer _bgPlayer = AudioPlayer();
  static bool _isMuted = false;
  static bool _isPlaying = false;

  static Future<void> playBackgroundMusic(String fileName) async {
    if (_isPlaying) return;
    try {
      _isPlaying = true;
      await _bgPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgPlayer.setVolume(_isMuted ? 0.0 : 0.5);
      await _bgPlayer.play(AssetSource('audio/$fileName')); // ← fixed path
    } catch (e) {
      _isPlaying = false;
      debugPrint('BGM error: $e');
    }
  }

  static Future<void> stopBackgroundMusic() async {
    _isPlaying = false;
    await _bgPlayer.stop();
  }

  static Future<void> pauseBackgroundMusic() async {
    await _bgPlayer.pause();
  }

  static Future<void> resumeBackgroundMusic() async {
    await _bgPlayer.resume();
  }

  static Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    await _bgPlayer.setVolume(_isMuted ? 0.0 : 0.5);
  }

  static bool get isMuted => _isMuted;

  static Future<void> playSoundEffect(String fileName) async {
    if (_isMuted) return;
    try {
      final player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.release); // ← auto-dispose
      await player.play(AssetSource('audio/$fileName')); // ← fixed path
      player.onPlayerComplete.listen((_) => player.dispose());
    } catch (e) {
      debugPrint('SFX error: $e');
    }
  }

  static void dispose() {
    _isPlaying = false;
    _bgPlayer.dispose();
  }
}
