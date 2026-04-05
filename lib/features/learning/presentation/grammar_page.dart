import 'dart:math' as math;

import 'package:flutter/material.dart';

class GrammarPage extends StatelessWidget {
  const GrammarPage({super.key});

  static const List<_GrammarCardData> _cards = <_GrammarCardData>[
    _GrammarCardData(
      title: 'Idioms & Phrases',
      subtitle: 'More than 200+ words',
      backgroundColor: Color(0xFFDCCDEE),
      accentColor: Color(0xFF5C2F8C),
      rotationDegrees: 0,
      decorationAlignment: Alignment.centerLeft,
    ),
    _GrammarCardData(
      title: 'Vegetable, fruits etc',
      subtitle: 'More than 200+ words',
      backgroundColor: Color(0xFFFFE187),
      accentColor: Color(0xFF111420),
      rotationDegrees: 0,
      decorationAlignment: Alignment.bottomRight,
    ),
    _GrammarCardData(
      title: 'Proverbs',
      subtitle: 'More than 200+ words',
      backgroundColor: Color(0xFF9ED1F2),
      accentColor: Color(0xFF111420),
      rotationDegrees: 0,
      decorationAlignment: Alignment.bottomLeft,
    ),
    _GrammarCardData(
      title: 'Daily speaking',
      subtitle: 'More than 200+ words',
      backgroundColor: Color(0xFFFFC6A7),
      accentColor: Color(0xFF111420),
      rotationDegrees: -4,
      decorationAlignment: Alignment.bottomRight,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFEFEFFC),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7F7FD), Color(0xFFEEEEFB)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 148),
            children: [
              Row(
                children: [
                  Text(
                    '语法',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: Color(0xFF8D91A3),
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              for (final card in _cards) ...[
                _GrammarShowcaseCard(data: card),
                const SizedBox(height: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GrammarShowcaseCard extends StatelessWidget {
  const _GrammarShowcaseCard({required this.data});

  final _GrammarCardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final angle = data.rotationDegrees * math.pi / 180;

    return Transform.rotate(
      angle: angle,
      child: Container(
        height: 168,
        decoration: BoxDecoration(
          color: data.backgroundColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x120D1730),
              blurRadius: 26,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Align(
                alignment: data.decorationAlignment,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: _BookStackDecoration(
                    accentColor: data.accentColor,
                    mirrored: data.decorationAlignment == Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_stories_outlined,
                    size: 42,
                    color: data.accentColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    data.title,
                    key: ValueKey<String>('grammar-card-${data.title}'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFF171A28),
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data.subtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF3D4152),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookStackDecoration extends StatelessWidget {
  const _BookStackDecoration({
    required this.accentColor,
    this.mirrored = false,
  });

  final Color accentColor;
  final bool mirrored;

  @override
  Widget build(BuildContext context) {
    final books = <_MiniBookSpec>[
      _MiniBookSpec(
        color: accentColor.withValues(alpha: 0.88),
        width: 34,
        height: 11,
      ),
      _MiniBookSpec(
        color: const Color(0xFF6070F6).withValues(alpha: 0.9),
        width: 30,
        height: 10,
      ),
      _MiniBookSpec(
        color: const Color(0xFFF2B44B).withValues(alpha: 0.92),
        width: 26,
        height: 9,
      ),
      _MiniBookSpec(
        color: const Color(0xFF5C2F8C).withValues(alpha: 0.9),
        width: 22,
        height: 8,
      ),
    ];

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Transform.translate(
          offset: const Offset(2, 10),
          child: Container(
            height: 40,
            width: 8,
            decoration: BoxDecoration(
              color: const Color(0xFFA6B3E8).withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        for (final book in books)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Container(
              height: book.height,
              width: book.width,
              decoration: BoxDecoration(
                color: book.color,
                borderRadius: BorderRadius.circular(3),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x160A1633),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
      ],
    );

    return mirrored
        ? Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
            child: content,
          )
        : content;
  }
}

class _GrammarCardData {
  const _GrammarCardData({
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.accentColor,
    required this.rotationDegrees,
    required this.decorationAlignment,
  });

  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color accentColor;
  final double rotationDegrees;
  final Alignment decorationAlignment;
}

class _MiniBookSpec {
  const _MiniBookSpec({
    required this.color,
    required this.width,
    required this.height,
  });

  final Color color;
  final double width;
  final double height;
}
