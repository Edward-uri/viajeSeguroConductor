import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';

import 'routes/app_router.dart';
import 'theme/theme.dart';
import 'theme/util.dart';

class JalaApp extends StatelessWidget {
  const JalaApp({super.key});

  @override
  Widget build(BuildContext context) {
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
      // System = MediaQuery heredado: respeta el toggle claro/oscuro de
      // DevicePreview y el modo del dispositivo real.
      themeMode: ThemeMode.system,
    );
  }
}
