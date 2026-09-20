import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Shares text through the native share sheet, falling back to the clipboard
/// when no share target exists (tests, desktop, restricted devices).
class ShareService {
  const ShareService();

  Future<void> shareText(String text, {String? subject}) async {
    try {
      await Share.share(text, subject: subject);
    } catch (error) {
      debugPrint('Native share failed ($error) - copying to clipboard instead');
      await copyToClipboard(text);
    }
  }

  Future<void> copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (error) {
      debugPrint('Clipboard copy failed: $error');
    }
  }
}
