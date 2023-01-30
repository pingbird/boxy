import 'package:flutter/material.dart';

class Palette {
  final Color background;
  final Color foreground;
  final Color accent;
  final Color divider;
  final Color primary;
  final Color secondary;
  final Color highlight;

  const Palette({
    required this.background,
    required this.foreground,
    required this.accent,
    required this.divider,
    required this.primary,
    required this.secondary,
    required this.highlight,
  });
}

Palette get palette => const Palette(
      background: Color(0xFF3A2E39),
      foreground: Color(0xFFF4D8CD),
      accent: Color(0xFFF15152),
      divider: Color(0xFF5F4B5E),
      primary: Color(0xFF5F4B5E),
      secondary: Color(0xFF678D58),
      highlight: Color(0xFFEDB183),
    );
