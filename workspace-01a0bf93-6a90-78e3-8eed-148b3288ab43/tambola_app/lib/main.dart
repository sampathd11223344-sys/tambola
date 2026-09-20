import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // A Tambola board is a "shared screen" experience: it is designed for
  // landscape. Removing this block (or adding portraitLeft/portraitRight)
  // will let the app rotate -- the layout is responsive either way.
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(const TambolaApp());
}
