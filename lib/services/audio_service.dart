import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class _AudioLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // Home button pressed — pause so it can resume when returning
        AudioService._bgPlayer.pause();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App closed/killed — stop completely
        AudioService._bgPlayer.stop();
        AudioService._isPlaying = false;
        AudioService._currentTrack = null;
        break;
      case AppLifecycleState.resumed:
        // Only resume if music was playing before
        if (AudioService._isPlaying && !AudioService._isMuted) {
          AudioService._bgPlayer.resume();
        }
        break;
    }
  }
}

class AudioService {
  static final AudioPlayer _bgPlayer = AudioPlayer();
  static final AudioPlayer _sfxPlayer = AudioPlayer();
  static bool _isMuted = false;
  static bool _isPlaying = false;
  static bool _initialized = false;
  static String? _currentTrack;
  static _AudioLifecycleObserver? _observer;

  static void initLifecycleObserver() {
    if (_observer != null) return;
    _observer = _AudioLifecycleObserver();
    WidgetsBinding.instance.addObserver(_observer!);
  }

  static Future<void> _init() async {
    if (_initialized || kIsWeb) return;
    _initialized = true;
    try {
      await _bgPlayer.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {
              AVAudioSessionOptions.defaultToSpeaker,
              AVAudioSessionOptions.mixWithOthers,
            },
          ),
        ),
      );
      await _sfxPlayer.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.assistanceSonification,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: {AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );
      await _sfxPlayer.setReleaseMode(ReleaseMode.release);
    } catch (e) {
      debugPrint('AudioContext init error: $e');
    }
  }

  // ── Background music ──────────────────────────────────────────────────────

  static Future<void> playBackgroundMusic(String fileName) async {
    // Always reinitialize audio context on play
    _initialized = false;
    await _init();
    try {
      _isPlaying = true;
      _currentTrack = fileName;
      await _bgPlayer.stop();
      await _bgPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgPlayer.setVolume(_isMuted ? 0.0 : 0.5);
      await _bgPlayer.play(AssetSource('audio/$fileName'));
    } catch (e) {
      _isPlaying = false;
      _currentTrack = null;
      debugPrint('BGM error: $e');
    }
  }

  static Future<void> stopBackgroundMusic() async {
    _isPlaying = false;
    _currentTrack = null;
    await _bgPlayer.stop();
  }

  static Future<void> pauseBackgroundMusic() async {
    await _bgPlayer.pause();
  }

  static Future<void> resumeBackgroundMusic() async {
    await _bgPlayer.resume();
  }

  // ── Mute ──────────────────────────────────────────────────────────────────

  static Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    await _bgPlayer.setVolume(_isMuted ? 0.0 : 0.5);
  }

  static bool get isMuted => _isMuted;

  // ── Sound effects ─────────────────────────────────────────────────────────

  static Future<void> playSoundEffect(String fileName) async {
    if (_isMuted) return;
    // Always reinit sfx context in case it was lost after home/back
    try {
      await _sfxPlayer.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.assistanceSonification,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: {AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('audio/$fileName'));
    } catch (e) {
      debugPrint('SFX error: $e');
    }
  }

  static Future<void> playSfx(String fileName) => playSoundEffect(fileName);

  // ── Cleanup ───────────────────────────────────────────────────────────────

  static void dispose() {
    _isPlaying = false;
    _currentTrack = null;
    _bgPlayer.dispose();
    _sfxPlayer.dispose();
  }
}
