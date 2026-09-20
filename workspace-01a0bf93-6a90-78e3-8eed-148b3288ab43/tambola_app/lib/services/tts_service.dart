import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/voice_language.dart';
import 'announcer.dart';

/// Platform text-to-speech implementation of [Announcer].
///
/// Every call is guarded: if TTS is missing (emulator without a speech engine,
/// tests, unsupported device) the game keeps working silently.
class TtsService implements Announcer {
  TtsService({FlutterTts? engine}) : _tts = engine ?? FlutterTts();

  final FlutterTts _tts;

  bool _ready = false;
  bool _muted = false;
  VoiceLanguage _language = VoiceLanguage.english;

  bool get isReady => _ready;

  @override
  Future<void> init() async {
    try {
      await _tts.awaitSpeakCompletion(false);
      await _tts.setSpeechRate(0.45); // calm, clear caller
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _tts.setSharedInstance(true);
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          const <IosTextToSpeechAudioCategoryOptions>[
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          ],
          IosTextToSpeechAudioMode.voicePrompt,
        );
      }
      await _tts.setLanguage(_language.locale);
      _tts.setErrorHandler((String message) => debugPrint('TTS error: $message'));
      _ready = true;
    } catch (error) {
      _ready = false;
      debugPrint('TTS unavailable on this device: $error');
    }
  }

  /// Switches the announcer language, falling back to the base language code
  /// when the exact regional voice is not installed.
  @override
  Future<void> setLanguage(VoiceLanguage language) async {
    _language = language;
    if (!_ready) return;
    try {
      dynamic available = false;
      try {
        available = await _tts.isLanguageAvailable(language.locale);
      } catch (_) {
        available = true; // iOS reports availability differently
      }
      final bool supported = available is bool ? available : available == 1;
      await _tts.setLanguage(
        supported ? language.locale : language.locale.split('-').first,
      );
    } catch (error) {
      debugPrint('Could not switch TTS language to ${language.locale}: $error');
    }
  }

  @override
  Future<void> speak(String text) async {
    if (!_ready || _muted || text.trim().isEmpty) return;
    try {
      await _tts.speak(text);
    } catch (error) {
      debugPrint('TTS speak failed: $error');
    }
  }

  @override
  Future<void> announce(int number) => speak(_language.announcement(number));

  @override
  void setMuted(bool muted) {
    _muted = muted;
    if (muted) {
      // Fire and forget: nothing to await on the UI path.
      unawaited(stop());
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {
      // Ignored on purpose.
    }
  }

  @override
  Future<void> dispose() => stop();
}
