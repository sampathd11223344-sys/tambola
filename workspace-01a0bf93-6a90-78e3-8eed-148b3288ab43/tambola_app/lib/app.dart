import 'package:flutter/material.dart';

import 'screens/tambola_screen.dart';
import 'theme/app_theme.dart';

/// Root widget of the Tambola board app.
class TambolaApp extends StatelessWidget {
  const TambolaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tambola Board',
      debugShowCheckedModeBanner: false,
      theme: buildTambolaTheme(),
      home: const TambolaScreen(),
      builder: (context, child) {
        // Never let the user's system font scaling break the 9x10 board.
        final MediaQueryData data = MediaQuery.of(context);
        return MediaQuery(
          data: data.copyWith(
            textScaler: data.textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.2,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
