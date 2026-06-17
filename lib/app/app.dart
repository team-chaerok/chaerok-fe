import 'package:chaerok/core/design_system/chaerok_theme.dart';

import 'package:flutter/material.dart';

class ChaerokApp extends StatelessWidget {
  const ChaerokApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chaerok',
      debugShowCheckedModeBanner: false,
      theme: ChaerokTheme.light,
      home: const Placeholder(),
    );
  }
}