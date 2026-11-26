import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class CallRingtoneService {
  CallRingtoneService._();
  static final CallRingtoneService instance = CallRingtoneService._();

  AudioPlayer? _player;
  String? _activeCallId;
  bool _isRinging = false;

  bool get isRinging => _isRinging;

  /// Plays the CC0 incoming call ringtone in a single-instance loop.
  /// Must ONLY be called after the receiver device has confirmed the incoming call UI/notification is ready.
  Future<void> startRinging(String callId) async {
    if (callId.isEmpty) return;
    if (_isRinging && _activeCallId == callId) {
      return; // Prevent duplicate concurrent ringtones for the same CallSession
    }
    await stopRinging();

    _activeCallId = callId;
    _isRinging = true;
    try {
      _player ??= AudioPlayer();
      _player!.audioCache = AudioCache(prefix: 'packages/mobile_shared/assets/');
      await _player!.setReleaseMode(ReleaseMode.loop);
      await _player!.setVolume(1.0);
      await _player!.play(AssetSource('audio/call_ringtone.wav'));
    } catch (e) {
      // Browser autoplay policies or platform audio focus constraints may block playback before interaction
      debugPrint('[CallRingtoneService] Unable to start ringtone: $e');
      _isRinging = false;
      _activeCallId = null;
    }
  }

  Future<void> stopRinging([String? callId]) async {
    if (callId != null && _activeCallId != null && _activeCallId != callId) {
      return;
    }
    _isRinging = false;
    _activeCallId = null;
    try {
      await _player?.stop();
    } catch (e) {
      debugPrint('[CallRingtoneService] Error stopping ringtone: $e');
    }
  }

  Future<void> dispose() async {
    await stopRinging();
    try {
      await _player?.dispose();
    } catch (_) {}
    _player = null;
  }
}

final callRingtoneService = CallRingtoneService.instance;
