/// Languages the announcer can speak, mapped to BCP-47 locale tags that the
/// platform TTS engine understands.
///
/// The `numberWord` is prefixed to the digits ("Number 54") which is what most
/// Housie callers say out loud. The digits themselves are then pronounced by
/// the platform engine in the requested language.
enum VoiceLanguage {
  english(label: 'English', locale: 'en-IN', numberWord: 'Number'),
  hindi(label: 'हिन्दी', locale: 'hi-IN', numberWord: 'नंबर'),
  telugu(label: 'తెలుగు', locale: 'te-IN', numberWord: 'నంబర్'),
  tamil(label: 'தமிழ்', locale: 'ta-IN', numberWord: 'எண்'),
  kannada(label: 'ಕನ್ನಡ', locale: 'kn-IN', numberWord: 'ಸಂಖ್ಯೆ'),
  marathi(label: 'मराठी', locale: 'mr-IN', numberWord: 'नंबर');

  const VoiceLanguage({
    required this.label,
    required this.locale,
    required this.numberWord,
  });

  /// Shown in the "Voice <language>" selector.
  final String label;

  /// BCP-47 tag handed to the TTS engine, e.g. `en-IN`.
  final String locale;

  /// Word placed before the number when announcing, e.g. "Number".
  final String numberWord;

  /// Text passed to `FlutterTts.speak`, e.g. `Number 54`.
  String announcement(int number) => '$numberWord $number';
}
