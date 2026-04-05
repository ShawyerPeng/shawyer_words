import 'package:flutter/material.dart';

@immutable
class LearningArticle {
  const LearningArticle({
    required this.id,
    required this.title,
    required this.category,
    required this.publishedAtLabel,
    required this.summary,
    required this.content,
    required this.durationLabel,
    required this.heroGradient,
    required this.heroIcon,
    this.heroImageUrl,
    this.isPopular = false,
    this.difficultyLevels = const <String>['Level 1', 'Level 2', 'Level 3'],
  });

  final String id;
  final String title;
  final String category;
  final String publishedAtLabel;
  final String summary;
  final String content;
  final String durationLabel;
  final String? heroImageUrl;
  final List<Color> heroGradient;
  final IconData heroIcon;
  final bool isPopular;
  final List<String> difficultyLevels;
}
