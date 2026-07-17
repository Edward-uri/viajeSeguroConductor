import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'routes/app_router.dart';
import 'theme/jala_theme.dart';
import 'theme/theme_mode_provider.dart';

class JalaApp extends ConsumerWidget {
  const JalaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme =
        createTextTheme(context, 'Plus Jakarta Sans', 'Plus Jakarta Sans');
    final theme = MaterialTheme(textTheme);

    return MaterialApp.router(
      title: 'Jala',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: theme.light(),
      darkTheme: theme.dark(),
      // Preferencia del usuario persistida; system respeta el toggle de
      // DevicePreview y el modo del dispositivo real.
      themeMode: ref.watch(themeModeProvider),
    );
  }
}
