import 'package:chaerok/ui/home/home_preview_screen.dart';
import 'package:chaerok/ui/preview_theme.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const ChaerokUiPreviewApp());
}

class ChaerokUiPreviewApp extends StatelessWidget {
  const ChaerokUiPreviewApp({super.key});

  static const double _maximumMobileWidth = 430;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '채록 UI Preview',
      debugShowCheckedModeBanner: false,
      theme: UiPreviewTheme.light,
      home: ColoredBox(
        color: UiPreviewColors.skyBlue,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maximumMobileWidth),
            child: const HomePreviewScreen(),
          ),
        ),
      ),
    );
  }
}
