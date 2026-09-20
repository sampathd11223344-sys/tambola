import '../models/voice_language.dart';

/// Contract the game logic depends on for spoken announcements.
///
/// Keeping it abstract means `TambolaController` can be unit-tested with a
/// fake announcer (no platform channels) and swapped for a recorded-voice
/// implementation later without touching the game logic.
abstract interface class Announcer {
  Future<void> init();

  Future<void> setLanguage(VoiceLanguage language);

  Future<void> speak(String text);

  /// Announces a called number, e.g. "Number 54".
  Future<void> announce(int number);

  void setMuted(bool muted);

  Future<void> stop();

  Future<void> dispose();
}
