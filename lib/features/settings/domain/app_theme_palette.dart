import 'package:flutter/material.dart';

class AppThemePalette {
  const AppThemePalette({
    required this.id,
    required this.label,
    required this.seedColor,
    required this.lightBackground,
    required this.indicatorColor,
  });

  final String id;
  final String label;
  final Color seedColor;
  final Color lightBackground;
  final Color indicatorColor;
}

const List<AppThemePalette> appThemePalettes = <AppThemePalette>[
  AppThemePalette(
    id: 'gray',
    label: '灰色',
    seedColor: Color(0xFF7A6256),
    lightBackground: Color(0xFFF8F4EF),
    indicatorColor: Color(0xFFADA197),
  ),
  AppThemePalette(
    id: 'green',
    label: '绿色',
    seedColor: Color(0xFF39B263),
    lightBackground: Color(0xFFF1F8F2),
    indicatorColor: Color(0xFF44B766),
  ),
  AppThemePalette(
    id: 'blue',
    label: '蓝色',
    seedColor: Color(0xFF1E7AF1),
    lightBackground: Color(0xFFF1F6FD),
    indicatorColor: Color(0xFF1F81F3),
  ),
  AppThemePalette(
    id: 'yellow',
    label: '黄色',
    seedColor: Color(0xFFF7AE22),
    lightBackground: Color(0xFFFBF6EA),
    indicatorColor: Color(0xFFF7B12B),
  ),
  AppThemePalette(
    id: 'pink',
    label: '粉色',
    seedColor: Color(0xFFFF2F62),
    lightBackground: Color(0xFFFDF0F4),
    indicatorColor: Color(0xFFFF325F),
  ),
  AppThemePalette(
    id: 'purple',
    label: '紫色',
    seedColor: Color(0xFF9447F4),
    lightBackground: Color(0xFFF6F0FD),
    indicatorColor: Color(0xFF974AF4),
  ),
];

String normalizeAppThemeName(String themeName) {
  return switch (themeName) {
    'forest' => 'green',
    'sunrise' => 'yellow',
    'default' => 'gray',
    'gray' || 'green' || 'blue' || 'yellow' || 'pink' || 'purple' => themeName,
    _ => 'gray',
  };
}

AppThemePalette appThemePaletteFor(String themeName) {
  final normalized = normalizeAppThemeName(themeName);
  return appThemePalettes.firstWhere(
    (palette) => palette.id == normalized,
    orElse: () => appThemePalettes.first,
  );
}
