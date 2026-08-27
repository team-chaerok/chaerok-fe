import 'package:flutter/material.dart';

class ChaerokShadows {
  const ChaerokShadows._();

  static List<BoxShadow> card = [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.25),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> floating = [
    BoxShadow(color: Color(0x1A324D3E), blurRadius: 18, offset: Offset(0, 7)),
  ];
}
