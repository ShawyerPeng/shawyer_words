import 'package:flutter/material.dart';
import 'package:shawyer_words/features/learning/domain/learning_article.dart';

class InMemoryLearningRepository {
  InMemoryLearningRepository._(this._articles);

  factory InMemoryLearningRepository.seeded() {
    return InMemoryLearningRepository._(_seededArticles);
  }

  final List<LearningArticle> _articles;

  List<LearningArticle> loadAllArticles() =>
      List<LearningArticle>.unmodifiable(_articles);

  List<LearningArticle> loadPopularArticles() =>
      List<LearningArticle>.unmodifiable(
        _articles.where((article) => article.isPopular),
      );

  List<LearningArticle> loadRecentArticles() =>
      List<LearningArticle>.unmodifiable(_articles);

  List<String> loadCategories() {
    final categories =
        _articles.map((article) => article.category).toSet().toList()..sort();
    return List<String>.unmodifiable(categories);
  }
}

const List<LearningArticle> _seededArticles = <LearningArticle>[
  LearningArticle(
    id: 'elephants',
    title: 'Saving Elephants',
    category: 'Nature',
    publishedAtLabel: 'Aug 20, 2021',
    summary: 'How rangers use data and mobile tools to protect elephants.',
    durationLabel: '2:31',
    isPopular: true,
    heroGradient: <Color>[Color(0xFFDDBE73), Color(0xFF7E6E4E)],
    heroIcon: Icons.pets_rounded,
    content:
        'This news is about elephants. Around 28,000 elephants die every year. '
        'A former soldier talks about poaching. She says that people call it '
        'poaching, but it is more like war. Somebody gives the poachers arms, '
        'and somebody transports the ivory. Kenyan rangers try to protect the '
        'elephants. They have a new smartphone app. They can see important data. '
        'They can enter new data, too. The app helps them. Since 2016, fewer '
        'elephants die. The drop is by 11 per cent.',
  ),
  LearningArticle(
    id: 'bamboo-trains',
    title: 'Cambodia\'s Bamboo Trains',
    category: 'Travel',
    publishedAtLabel: 'Aug 18, 2021',
    summary: 'A quick ride through one of Cambodia\'s most unusual journeys.',
    durationLabel: '3:05',
    isPopular: true,
    heroGradient: <Color>[Color(0xFF84C26A), Color(0xFF2F6B3C)],
    heroIcon: Icons.directions_railway_rounded,
    content:
        'People in Cambodia still use bamboo trains. The trains are simple, '
        'light platforms with small motors. They move quickly on old railway '
        'tracks. Tourists enjoy them because the ride feels open and close to '
        'nature. Local families also use them for travel and business. The '
        'experience shows how creative transport can grow from everyday needs.',
  ),
  LearningArticle(
    id: 'richest-singer',
    title: 'The richest singer in the world',
    category: 'Interesting',
    publishedAtLabel: 'Aug 20, 2021',
    summary: 'A short profile about music, business, and celebrity wealth.',
    durationLabel: '1:48',
    heroGradient: <Color>[Color(0xFFD77892), Color(0xFF5E294B)],
    heroIcon: Icons.mic_external_on_rounded,
    content:
        'Some singers earn money from albums and tours. Others build brands, '
        'fashion lines, and media businesses. That is why the richest singer is '
        'not always the one with the most number-one songs. Business choices, '
        'ownership, and long-term planning often matter more than one hit record.',
  ),
  LearningArticle(
    id: 'olympics',
    title: 'Krystsina Tsimanouskaya must leave Olympics',
    category: 'Sports',
    publishedAtLabel: 'Aug 18, 2021',
    summary: 'A sports story about pressure, travel, and athlete safety.',
    durationLabel: '2:14',
    heroGradient: <Color>[Color(0xFF87A3FF), Color(0xFF3551C8)],
    heroIcon: Icons.directions_run_rounded,
    content:
        'An athlete at the Olympics suddenly became the center of international '
        'attention. What started as a team disagreement soon raised bigger '
        'questions about personal safety, public pressure, and the role of sports '
        'organizations when conflict moves beyond the track.',
  ),
  LearningArticle(
    id: 'fries',
    title: 'The most expensive fries in the world',
    category: 'Foods',
    publishedAtLabel: 'Aug 10, 2021',
    summary: 'Luxury ingredients turn an ordinary snack into a headline.',
    durationLabel: '1:26',
    heroGradient: <Color>[Color(0xFFF6C24F), Color(0xFFCC7C1F)],
    heroIcon: Icons.restaurant_rounded,
    content:
        'French fries are usually simple food. A restaurant in New York wanted '
        'to make them unforgettable. It used expensive ingredients, careful '
        'presentation, and a strong story. The result was a plate of fries that '
        'people talked about around the world.',
  ),
];
